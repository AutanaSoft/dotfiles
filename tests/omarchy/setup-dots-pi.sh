#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }
paths=(agent/settings.json gentle-ai/persona.json gentle-ai/profiles.json)
repo="$tmp/repo"
home="$tmp/home"
backup="$tmp/backup"
mkdir -p "$repo/omarchy" "$home/.pi/agent" "$tmp/bin"
printf '#!/usr/bin/env bash\n[[ $1 == version ]] && echo 4.5.0\n' > "$tmp/bin/omarchy"
chmod +x "$tmp/bin/omarchy"

for path in "${paths[@]}"; do
  entry="$(printf 'file\tomarchy/home/pi/%s\t.pi/%s' "$path" "$path")"
  grep -Fx "$entry" "$ROOT_DIR/omarchy/dots-manifest" >/dev/null || fail "missing Pi manifest entry: $path"
  mkdir -p "$repo/omarchy/home/pi/$(dirname "$path")" "$home/.pi/$(dirname "$path")"
  cp "$ROOT_DIR/omarchy/home/pi/$path" "$repo/omarchy/home/pi/$path"
  printf '%s\n' "$entry" >> "$repo/omarchy/dots-manifest"
  printf 'local configuration\n' > "$home/.pi/$path"
done
printf 'unmanaged data\n' > "$home/.pi/agent/unmanaged"

for mode in dry apply repeat; do
  args=()
  [[ "$mode" != dry ]] || args+=(--dry-run)
  {
    printf '[setup-dots] Repo root: %s\n' "$repo"
    [[ "$mode" != dry ]] || printf '[setup-dots] Mode: DRY-RUN (no user changes)\n'
    for path in "${paths[@]}"; do
      if [[ "$mode" == repeat ]]; then
        printf '[setup-dots] Already linked: %s/.pi/%s\n' "$home" "$path"
      else
        printf '[setup-dots] Backing up existing target: %s/.pi/%s -> %s/.pi/%s\n' "$home" "$path" "$backup" "$path"
        printf '[setup-dots] Creating symlink: %s/.pi/%s -> %s/omarchy/home/pi/%s\n' "$home" "$path" "$repo" "$path"
      fi
    done
    printf '[setup-dots] User dotfiles complete.\n'
  } > "$tmp/expected"
  HOME="$home" DOTFILES_ROOT="$repo" DOTFILES_BACKUP_DIR="$backup" PATH="$tmp/bin:$PATH" \
    bash "$ROOT_DIR/omarchy/utils/bash/setup-dots" "${args[@]}" > "$tmp/stdout" 2> "$tmp/stderr" || fail "$mode failed"
  [[ ! -s "$tmp/stderr" ]] || fail "$mode unexpected stderr"
  cmp "$tmp/expected" "$tmp/stdout" || fail "$mode unexpected stdout"
  for path in "${paths[@]}"; do
    if [[ "$mode" == dry ]]; then
      [[ ! -L "$home/.pi/$path" && "$(<"$home/.pi/$path")" == 'local configuration' ]] || fail 'dry-run changed target'
      [[ ! -e "$backup" ]] || fail 'dry-run created backup'
    else
      [[ -L "$home/.pi/$path" && "$(readlink "$home/.pi/$path")" == "$repo/omarchy/home/pi/$path" ]] || fail "incorrect link: $path"
      cmp "$home/.pi/$path" "$ROOT_DIR/omarchy/home/pi/$path" || fail "changed configuration: $path"
      [[ "$(<"$backup/.pi/$path")" == 'local configuration' ]] || fail 'missing local backup'
      [[ ! -e "$backup/.pi/$path.1" ]] || fail 'repeat created backup'
    fi
  done
  [[ "$(<"$home/.pi/agent/unmanaged")" == 'unmanaged data' ]] || fail 'unmanaged data changed'
done
printf 'PASS: Pi configuration symlinks, dry-run, backups, and idempotency\n'
