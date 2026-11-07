#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
SETUP_DOTS="$ROOT_DIR/omarchy/utils/bash/setup-dots"
MANIFEST="$ROOT_DIR/omarchy/dots-manifest"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
paths=(agent/settings.json gentle-ai/persona.json gentle-ai/profiles.json)
declare -A manifest_actions=() manifest_counts=() pi_actions=()

# These mappings are file destinations, so only file, copy, or skip are compatible.
while IFS=$'\t' read -r action source target; do
  [[ -z "$action" || "$action" =~ ^[[:space:]]*# ]] && continue
  action="$(xargs <<< "$action")"
  source="$(xargs <<< "$source")"
  target="$(xargs <<< "$target")"
  [[ "$source" == omarchy/home/pi/* || "$target" == .pi/* ]] || continue
  mapping="$source"$'\t'"$target"
  manifest_counts["$mapping"]=$((${manifest_counts["$mapping"]:-0} + 1))
  manifest_actions["$mapping"]="$action"
done < "$MANIFEST"

for mapping in "${!manifest_counts[@]}"; do
  expected=0
  for path in "${paths[@]}"; do
    if [[ "$mapping" == "omarchy/home/pi/$path"$'\t'".pi/$path" ]]; then
      expected=1
      break
    fi
  done
  [[ "$expected" -eq 1 ]] || fail "unexpected Pi manifest mapping: ${mapping//$'\t'/ -> }"
done
for path in "${paths[@]}"; do
  mapping="omarchy/home/pi/$path"$'\t'".pi/$path"
  count="${manifest_counts["$mapping"]:-0}"
  [[ "$count" -eq 1 ]] || fail "expected one Pi manifest mapping for $path; found $count"
  action="${manifest_actions["$mapping"]}"
  case "$action" in
    file|copy|skip) pi_actions["$path"]="$action" ;;
    *) fail "incompatible Pi action '$action' for file mapping: omarchy/home/pi/$path -> .pi/$path" ;;
  esac
done

mkdir -p "$tmp/bin"
printf '#!/usr/bin/env bash\n[[ $1 == version ]] && echo 4.5.0\n' > "$tmp/bin/omarchy"
chmod +x "$tmp/bin/omarchy"

make_scenario() {
  local kind="$1" path source target source_file target_file
  scenario_repo="$tmp/$kind/repo"
  scenario_home="$tmp/$kind/home"
  scenario_backup="$tmp/$kind/backup"
  mkdir -p "$scenario_repo/omarchy" "$scenario_home/.pi/agent"
  printf '# fixture manifest\n' > "$scenario_repo/omarchy/dots-manifest"
  for path in "${paths[@]}"; do
    source="omarchy/home/pi/$path"
    target=".pi/$path"
    source_file="$ROOT_DIR/$source"
    target_file="$scenario_home/$target"
    [[ -f "$source_file" ]] || fail "Pi manifest source is not a regular file: $source"
    mkdir -p "$scenario_repo/$(dirname -- "$source")"
    cp "$source_file" "$scenario_repo/$source"
    printf '%s\t%s\t%s\n' "${pi_actions["$path"]}" "$source" "$target" >> "$scenario_repo/omarchy/dots-manifest"
    if [[ "$kind" == existing ]]; then
      mkdir -p "$(dirname -- "$target_file")"
      printf 'local configuration\n' > "$target_file"
    fi
  done
  printf 'unmanaged data\n' > "$scenario_home/.pi/agent/unmanaged"
}

append_expected() { printf '%s\n' "$1" >> "$tmp/expected"; }
write_expected() {
  local kind="$1" phase="$2" path action source target source_file target_file backup_file
  : > "$tmp/expected"
  append_expected "[setup-dots] Repo root: $scenario_repo"
  if [[ "$phase" == dry ]]; then
    append_expected '[setup-dots] Mode: DRY-RUN (no user changes)'
  fi
  for path in "${paths[@]}"; do
    action="${pi_actions["$path"]}"
    source="omarchy/home/pi/$path"
    target=".pi/$path"
    source_file="$scenario_repo/$source"
    target_file="$scenario_home/$target"
    backup_file="$scenario_backup/$target"
    case "$action" in
      file)
        if [[ "$kind" == existing && "$phase" != repeat ]]; then
          append_expected "[setup-dots] Backing up existing target: $target_file -> $backup_file"
          append_expected "[setup-dots] Creating symlink: $target_file -> $source_file"
        elif [[ "$phase" == repeat ]]; then
          append_expected "[setup-dots] Already linked: $target_file"
        else
          append_expected "[setup-dots] Creating symlink: $target_file -> $source_file"
        fi
        ;;
      copy)
        if [[ "$kind" == fresh && "$phase" != repeat ]]; then
          append_expected "[setup-dots] Copying: $source_file -> $target_file"
        else
          append_expected "[setup-dots] Skipping copy: $target_file already exists"
        fi
        ;;
      skip)
        append_expected "[setup-dots] Skipping explicit exclusion: $source"
        ;;
    esac
  done
  append_expected '[setup-dots] User dotfiles complete.'
}

assert_state() {
  local kind="$1" phase="$2" path action source target source_file target_file backup_file
  for path in "${paths[@]}"; do
    action="${pi_actions["$path"]}"
    source="omarchy/home/pi/$path"
    target=".pi/$path"
    source_file="$scenario_repo/$source"
    target_file="$scenario_home/$target"
    backup_file="$scenario_backup/$target"
    case "$action" in
      file)
        if [[ "$kind" == fresh && "$phase" == dry ]]; then
          [[ ! -e "$target_file" && ! -L "$target_file" ]] || fail "file dry-run changed $target"
          [[ ! -e "$backup_file" && ! -L "$backup_file" ]] || fail "file dry-run backed up $target"
        elif [[ "$kind" == existing && "$phase" == dry ]]; then
          [[ -f "$target_file" && ! -L "$target_file" && "$(<"$target_file")" == 'local configuration' ]] || fail "file dry-run changed existing $target"
          [[ ! -e "$backup_file" && ! -L "$backup_file" ]] || fail "file dry-run created backup for $target"
        else
          [[ -L "$target_file" && "$(readlink -- "$target_file")" == "$source_file" ]] || fail "file action did not link $target"
          cmp "$target_file" "$source_file" || fail "file action changed source contents for $target"
          if [[ "$kind" == existing ]]; then
            [[ -f "$backup_file" && "$(<"$backup_file")" == 'local configuration' ]] || fail "file action did not preserve existing $target"
            [[ ! -e "$backup_file.1" && ! -L "$backup_file.1" ]] || fail "file repeat created another backup for $target"
          else
            [[ ! -e "$backup_file" && ! -L "$backup_file" ]] || fail "fresh file target unexpectedly created backup for $target"
          fi
        fi
        ;;
      copy)
        if [[ "$kind" == fresh && "$phase" == dry ]]; then
          [[ ! -e "$target_file" && ! -L "$target_file" ]] || fail "copy dry-run created $target"
        elif [[ "$kind" == fresh && "$phase" == repeat ]]; then
          [[ -f "$target_file" && ! -L "$target_file" && "$(<"$target_file")" == 'local copy edit' ]] || fail "copy repeat overwrote a local edit to $target"
        elif [[ "$kind" == fresh ]]; then
          [[ -f "$target_file" && ! -L "$target_file" ]] || fail "copy did not create regular file $target"
          cmp "$target_file" "$source_file" || fail "copy changed source contents for $target"
        else
          [[ -f "$target_file" && ! -L "$target_file" && "$(<"$target_file")" == 'local configuration' ]] || fail "copy changed existing $target"
        fi
        [[ ! -e "$backup_file" && ! -L "$backup_file" ]] || fail "copy created an unexpected backup for $target"
        ;;
      skip)
        if [[ "$kind" == fresh ]]; then
          [[ ! -e "$target_file" && ! -L "$target_file" ]] || fail "skip changed absent target $target"
        else
          [[ -f "$target_file" && ! -L "$target_file" && "$(<"$target_file")" == 'local configuration' ]] || fail "skip changed existing target $target"
        fi
        [[ ! -e "$backup_file" && ! -L "$backup_file" ]] || fail "skip created an unexpected backup for $target"
        ;;
    esac
  done
  [[ "$(<"$scenario_home/.pi/agent/unmanaged")" == 'unmanaged data' ]] || fail 'unmanaged Pi data changed'
}

run_case() {
  local kind="$1" phase="$2" status
  local -a args=()
  [[ "$phase" != dry ]] || args+=(--dry-run)
  write_expected "$kind" "$phase"
  if HOME="$scenario_home" DOTFILES_ROOT="$scenario_repo" DOTFILES_BACKUP_DIR="$scenario_backup" \
    PATH="$tmp/bin:$PATH" bash "$SETUP_DOTS" "${args[@]}" > "$tmp/stdout" 2> "$tmp/stderr"; then
    status=0
  else
    status=$?
  fi
  [[ "$status" -eq 0 ]] || fail "$kind/$phase exited $status: $(<"$tmp/stderr")"
  [[ ! -s "$tmp/stderr" ]] || fail "$kind/$phase wrote unexpected stderr: $(<"$tmp/stderr")"
  cmp "$tmp/expected" "$tmp/stdout" || fail "$kind/$phase stdout did not match the manifest action"
  assert_state "$kind" "$phase"
}

make_scenario fresh
run_case fresh dry
run_case fresh apply
for path in "${paths[@]}"; do
  if [[ "${pi_actions["$path"]}" == copy ]]; then
    printf 'local copy edit\n' > "$scenario_home/.pi/$path"
  fi
done
run_case fresh repeat

make_scenario existing
run_case existing dry
run_case existing apply
run_case existing repeat
printf 'PASS: Pi manifest actions, dry-run, existing targets, and repeat behavior\n'
