#!/usr/bin/env bash

set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/omarchy/utils/bash/setup-fonts"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
HOME="$TMP/home"
BIN="$TMP/bin"
FIXTURES="$TMP/fixtures"
mkdir -p "$HOME" "$BIN" "$FIXTURES"
export HOME FONT_FIXTURES="$FIXTURES" FC_CACHE_LOG="$TMP/fc-cache.log"

cat >"$BIN/curl" <<'SH'
#!/usr/bin/env bash
set -e
while [[ $# -gt 0 ]]; do
  case "$1" in -o) output="$2"; shift 2 ;; *) shift ;; esac
done
[[ "${FAIL_URL:-}" != "${output##*/}" ]] || exit 9
printf '%s\n' "${output##*/}" >>"${DOWNLOAD_LOG:?}"
printf archive >"$output"
SH
cat >"$BIN/unzip" <<'SH'
#!/usr/bin/env bash
set -e
while [[ $# -gt 0 ]]; do
  case "$1" in -d) dest="$2"; shift 2 ;; *) archive="$1"; shift ;; esac
done
mkdir -p "$dest"
case "${archive##*/}" in
  MonaspaceNerdFont.zip) family=MonaspaceNerdFont ;;
  FiraCodeNerdFont.zip) family=FiraCodeNerdFont ;;
  FiraMonoNerdFont.zip) family=FiraMonoNerdFont ;;
esac
cp "$FONT_FIXTURES/$family.ttf" "$dest/$family.ttf"
SH
cat >"$BIN/sha256sum" <<'SH'
#!/usr/bin/env bash
[[ "${FAIL_HASH:-0}" != 1 ]] || exit 7
if [[ "$1" == *.zip ]]; then
  case "${1##*/}" in
    MonaspaceNerdFont.zip) hash=9b7f9505d977601d8819dfdb57fa4b49bdab61132b6d1131c2e8d092066edc5a ;;
    FiraCodeNerdFont.zip) hash=239395baf60c89b2eaf4862b6b09db0ef95605cd3e8eef51c00345822a81a665 ;;
    FiraMonoNerdFont.zip) hash=292f2f9160d76a6603a920d3813caa89233a9910d7eadf2832639ad1ddbf98b4 ;;
  esac
  printf '%s  %s\n' "${EXPECTED_HASH:-$hash}" "$1"
else
  exec /usr/bin/sha256sum "$@"
fi
SH
cat >"$BIN/fc-cache" <<'SH'
#!/usr/bin/env bash
printf called >>"$FC_CACHE_LOG"
SH
chmod +x "$BIN"/*
export PATH="$BIN:$PATH" DOWNLOAD_LOG="$TMP/downloads.log"
printf monaspace >"$FIXTURES/MonaspaceNerdFont.ttf"
printf firacode >"$FIXTURES/FiraCodeNerdFont.ttf"
printf firamono >"$FIXTURES/FiraMonoNerdFont.ttf"

assert_failed_unchanged() {
  local label="$1"; shift
  local before
  before="$(find "$HOME" -type f -print0 | sort -z | xargs -0 -r sha256sum)"
  : >"$FC_CACHE_LOG"
  set +e
  "$SCRIPT" "$@" >"$TMP/stdout" 2>"$TMP/stderr"
  local status=$?
  set -e
  [[ $status -eq 1 ]] || { echo "FAIL: $label exit was $status" >&2; exit 1; }
  [[ "$(find "$HOME" -type f -print0 | sort -z | xargs -0 -r sha256sum)" == "$before" ]] || { echo "FAIL: $label changed installed files" >&2; exit 1; }
  [[ ! -s "$FC_CACHE_LOG" ]] || { echo "FAIL: $label ran fc-cache" >&2; exit 1; }
}

# A failed late download must not leave earlier families installed.
rm -rf "$HOME/.local"
: >"$DOWNLOAD_LOG"
FAIL_URL=FiraMonoNerdFont.zip assert_failed_unchanged late-download
[[ ! -e "$HOME/.local" ]] || { echo 'FAIL: late download left destination state' >&2; exit 1; }

# Checksum-tool failure and digest mismatch both abort before any destination change.
FAIL_HASH=1 assert_failed_unchanged checksum-tool-failure
EXPECTED_HASH=bad assert_failed_unchanged checksum-mismatch

# Existing unmanaged or locally modified files are preserved and cause a clear stop.
mkdir -p "$HOME/.local/share/fonts/FiraCodeNerdFont"
printf foreign >"$HOME/.local/share/fonts/FiraCodeNerdFont/FiraCodeNerdFont.ttf"
assert_failed_unchanged unmanaged-collision
[[ "$(<"$HOME/.local/share/fonts/FiraCodeNerdFont/FiraCodeNerdFont.ttf")" == foreign ]] || exit 1

# Clean install records hashes; an unchanged rerun is safe and preserves stale managed files.
rm -rf "$HOME/.local"
"$SCRIPT" >"$TMP/stdout" 2>"$TMP/stderr"
record="$HOME/.local/share/fonts/.dotfiles-fonts-ownership"
[[ -f "$record" ]] || { echo 'FAIL: ownership record missing' >&2; exit 1; }
cp "$HOME/.local/share/fonts/MonaspaceNerdFont/MonaspaceNerdFont.ttf" "$TMP/installed"
printf stale >"$HOME/.local/share/fonts/MonaspaceNerdFont/old.ttf"
"$SCRIPT" >"$TMP/stdout" 2>"$TMP/stderr"
cmp "$TMP/installed" "$HOME/.local/share/fonts/MonaspaceNerdFont/MonaspaceNerdFont.ttf"
[[ "$(<"$HOME/.local/share/fonts/MonaspaceNerdFont/old.ttf")" == stale ]] || { echo 'FAIL: stale managed file pruned' >&2; exit 1; }
printf edited >"$HOME/.local/share/fonts/MonaspaceNerdFont/MonaspaceNerdFont.ttf"
assert_failed_unchanged locally-modified-file

# Dry-run retains its no-write/no-network/no-cache contract.
rm -rf "$HOME/.local"; : >"$DOWNLOAD_LOG"
"$SCRIPT" --dry-run >"$TMP/stdout"
[[ ! -e "$HOME/.local" && ! -s "$DOWNLOAD_LOG" && ! -s "$FC_CACHE_LOG" ]] || { echo 'FAIL: dry-run caused side effects' >&2; exit 1; }
printf 'PASS: setup-fonts integrity and ownership\n'
