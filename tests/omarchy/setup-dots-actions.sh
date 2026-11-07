#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
SETUP_DOTS="$ROOT_DIR/omarchy/utils/bash/setup-dots"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

repo="$tmp/repo"
home="$tmp/home"
backup="$tmp/backup"
mkdir -p "$repo/omarchy" "$repo/omarchy/links/dir-source" "$repo/omarchy/glob" \
  "$repo/omarchy/copy" "$repo/omarchy/skip" "$home/.config/copy" "$home/.config/skip" \
  "$tmp/bin"
printf 'file source\n' > "$repo/omarchy/links/file-source"
printf 'directory source\n' > "$repo/omarchy/links/dir-source/value"
printf 'glob alpha\n' > "$repo/omarchy/glob/alpha.lua"
printf 'glob beta\n' > "$repo/omarchy/glob/beta.lua"
printf 'new copy source\n' > "$repo/omarchy/copy/new-source"
printf 'existing file source\n' > "$repo/omarchy/copy/existing-file-source"
printf 'existing dir source\n' > "$repo/omarchy/copy/existing-dir-source"
printf 'existing link source\n' > "$repo/omarchy/copy/existing-link-source"
printf 'dangling link source\n' > "$repo/omarchy/copy/dangling-link-source"
printf 'skip existing source\n' > "$repo/omarchy/skip/existing-source"
printf '#!/usr/bin/env bash\n[[ $1 == version ]] && echo 4.5.0\n' > "$tmp/bin/omarchy"
chmod +x "$tmp/bin/omarchy"

copy_dir="$home/.config/copy/existing-dir"
mkdir -p "$copy_dir"
printf 'local file\n' > "$home/.config/copy/existing-file"
printf 'local directory data\n' > "$copy_dir/value"
printf 'valid link referent\n' > "$tmp/valid-link-referent"
ln -s "$tmp/valid-link-referent" "$home/.config/copy/existing-link"
ln -s 'missing-copy-referent' "$home/.config/copy/dangling-link"
printf 'skip local data\n' > "$home/.config/skip/existing"
printf 'unmanaged data\n' > "$home/.config/unmanaged"

cat > "$repo/omarchy/dots-manifest" <<'EOF'
file	omarchy/links/file-source	.config/links/file-link
dir	omarchy/links/dir-source	.config/links/dir-link
glob	omarchy/glob/*.lua	.config/links/glob/
copy	omarchy/copy/new-source	.config/copy/new
copy	omarchy/copy/existing-file-source	.config/copy/existing-file
copy	omarchy/copy/existing-dir-source	.config/copy/existing-dir
copy	omarchy/copy/existing-link-source	.config/copy/existing-link
copy	omarchy/copy/dangling-link-source	.config/copy/dangling-link
copy	omarchy/copy/missing-source	.config/copy/missing
skip	omarchy/skip/existing-source	.config/skip/existing
skip	omarchy/skip/missing-source	.config/skip/missing
EOF

append_expected() { printf '%s\n' "$1" >> "$tmp/expected"; }
write_expected() {
  local phase="$1"
  local file_target="$home/.config/links/file-link"
  local dir_target="$home/.config/links/dir-link"
  local glob_target="$home/.config/links/glob"
  local copy_target="$home/.config/copy/new"
  : > "$tmp/expected"
  append_expected "[setup-dots] Repo root: $repo"
  if [[ "$phase" == dry ]]; then
    append_expected '[setup-dots] Mode: DRY-RUN (no user changes)'
  fi
  if [[ "$phase" == repeat ]]; then
    append_expected "[setup-dots] Already linked: $file_target"
    append_expected "[setup-dots] Already linked: $dir_target"
  else
    append_expected "[setup-dots] Creating symlink: $file_target -> $repo/omarchy/links/file-source"
    append_expected "[setup-dots] Creating symlink: $dir_target -> $repo/omarchy/links/dir-source"
  fi
  if [[ "$phase" == repeat ]]; then
    append_expected "[setup-dots] Already linked: $glob_target/alpha.lua"
    append_expected "[setup-dots] Already linked: $glob_target/beta.lua"
  else
    append_expected "[setup-dots] Creating symlink: $glob_target/alpha.lua -> $repo/omarchy/glob/alpha.lua"
    append_expected "[setup-dots] Creating symlink: $glob_target/beta.lua -> $repo/omarchy/glob/beta.lua"
  fi
  if [[ "$phase" == repeat ]]; then
    append_expected "[setup-dots] Skipping copy: $copy_target already exists"
  else
    append_expected "[setup-dots] Copying: $repo/omarchy/copy/new-source -> $copy_target"
  fi
  append_expected "[setup-dots] Skipping copy: $home/.config/copy/existing-file already exists"
  append_expected "[setup-dots] Skipping copy: $home/.config/copy/existing-dir already exists"
  append_expected "[setup-dots] Skipping copy: $home/.config/copy/existing-link already exists"
  append_expected "[setup-dots] Skipping copy: $home/.config/copy/dangling-link already exists"
  append_expected "[setup-dots] Skipping missing source: $repo/omarchy/copy/missing-source"
  append_expected "[setup-dots] Skipping explicit exclusion: omarchy/skip/existing-source"
  append_expected "[setup-dots] Skipping explicit exclusion: omarchy/skip/missing-source"
  append_expected '[setup-dots] User dotfiles complete.'
}

assert_preexisting_copy_targets() {
  [[ -f "$home/.config/copy/existing-file" && ! -L "$home/.config/copy/existing-file" && "$(<"$home/.config/copy/existing-file")" == 'local file' ]] || fail 'copy replaced an existing local file'
  [[ -d "$copy_dir" && ! -L "$copy_dir" && "$(<"$copy_dir/value")" == 'local directory data' ]] || fail 'copy replaced an existing local directory'
  [[ -L "$home/.config/copy/existing-link" && "$(readlink -- "$home/.config/copy/existing-link")" == "$tmp/valid-link-referent" ]] || fail 'copy replaced a valid symlink'
  [[ "$(<"$tmp/valid-link-referent")" == 'valid link referent' ]] || fail 'copy changed a valid symlink referent'
  [[ -L "$home/.config/copy/dangling-link" && "$(readlink -- "$home/.config/copy/dangling-link")" == 'missing-copy-referent' ]] || fail 'copy replaced a dangling symlink'
  [[ -f "$home/.config/skip/existing" && ! -L "$home/.config/skip/existing" && "$(<"$home/.config/skip/existing")" == 'skip local data' ]] || fail 'skip changed an existing target'
}

assert_state() {
  local phase="$1"
  local file_target="$home/.config/links/file-link"
  local dir_target="$home/.config/links/dir-link"
  local glob_target="$home/.config/links/glob"
  local copy_target="$home/.config/copy/new"
  assert_preexisting_copy_targets
  [[ "$(<"$home/.config/unmanaged")" == 'unmanaged data' ]] || fail 'unmanaged data changed'
  if [[ "$phase" == dry ]]; then
    [[ ! -e "$home/.config/links" && ! -L "$home/.config/links" ]] || fail 'dry-run created link targets or parent directories'
    [[ ! -e "$copy_target" && ! -L "$copy_target" ]] || fail 'dry-run copied a new file'
    [[ ! -e "$home/.config/copy/missing" && ! -L "$home/.config/copy/missing" ]] || fail 'missing copy source created a target'
    [[ ! -e "$home/.config/skip/missing" && ! -L "$home/.config/skip/missing" ]] || fail 'skip created an absent target'
  else
    [[ -L "$file_target" && "$(readlink -- "$file_target")" == "$repo/omarchy/links/file-source" ]] || fail 'file action did not create the expected symlink'
    [[ -L "$dir_target" && "$(readlink -- "$dir_target")" == "$repo/omarchy/links/dir-source" ]] || fail 'dir action did not create the expected symlink'
    for name in alpha.lua beta.lua; do
      [[ -L "$glob_target/$name" && "$(readlink -- "$glob_target/$name")" == "$repo/omarchy/glob/$name" ]] || fail "glob action did not link $name"
    done
    [[ -f "$copy_target" && ! -L "$copy_target" ]] || fail 'copy action did not create a regular file'
    if [[ "$phase" == repeat ]]; then
      [[ "$(<"$copy_target")" == 'local copy edit' ]] || fail 'copy repeat overwrote a local edit'
    else
      [[ "$(<"$copy_target")" == 'new copy source' ]] || fail 'copy action changed file contents'
    fi
    [[ ! -e "$home/.config/copy/missing" && ! -L "$home/.config/copy/missing" ]] || fail 'missing copy source created a target'
    [[ ! -e "$home/.config/skip/missing" && ! -L "$home/.config/skip/missing" ]] || fail 'skip created an absent target'
  fi
  [[ ! -e "$backup" && ! -L "$backup" ]] || fail 'file, dir, glob, copy, or skip fixture unexpectedly created a backup'
}

run_case() {
  local phase="$1" status
  local -a args=()
  [[ "$phase" != dry ]] || args+=(--dry-run)
  write_expected "$phase"
  if HOME="$home" DOTFILES_ROOT="$repo" DOTFILES_BACKUP_DIR="$backup" PATH="$tmp/bin:$PATH" \
    bash "$SETUP_DOTS" "${args[@]}" > "$tmp/stdout" 2> "$tmp/stderr"; then
    status=0
  else
    status=$?
  fi
  [[ "$status" -eq 0 ]] || fail "$phase exited $status: $(<"$tmp/stderr")"
  [[ ! -s "$tmp/stderr" ]] || fail "$phase wrote unexpected stderr: $(<"$tmp/stderr")"
  cmp "$tmp/expected" "$tmp/stdout" || fail "$phase stdout did not match the action contract"
  assert_state "$phase"
}

run_case dry
run_case apply
printf 'local copy edit\n' > "$home/.config/copy/new"
run_case repeat
printf 'PASS: file, dir, glob, copy, and skip manifest actions\n'
