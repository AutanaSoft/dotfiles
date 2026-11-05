#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
CLEANUP="$ROOT_DIR/omarchy/utils/bash/cleanup"
source "$ROOT_DIR/tests/lib/test-helpers.sh"
setup_test_environment
export TEST_TMP_DIR
trap cleanup_test_environment EXIT

bin="$TEST_TMP_DIR/bin"
root="$TEST_TMP_DIR/repo"
log="$TEST_TMP_DIR/mutations.log"
confirm_log="$TEST_TMP_DIR/confirms.log"
mkdir -p "$bin" "$root/backup" "$HOME/.local/bin" "$HOME/.local/share/applications"
export DOTFILES_ROOT="$root" MUTATION_LOG="$log" CONFIRM_LOG="$confirm_log" GUM_RESPONSE=accept

cat >"$bin/gum" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  confirm) printf 'confirm\n' >>"$CONFIRM_LOG"; [[ "${GUM_RESPONSE:?}" == accept ]] ;;
  choose) printf '%s\n' "$GUM_ROWS" ;;
  *) exit 2 ;;
esac
EOF
cat >"$bin/rm" <<'EOF'
#!/usr/bin/env bash
printf 'rm' >>"$MUTATION_LOG"
printf ' <%s>' "$@" >>"$MUTATION_LOG"
printf '\n' >>"$MUTATION_LOG"
EOF
for command in omarchy-pkg-drop omarchy-webapp-remove omarchy-tui-remove pacman sudo; do
  cat >"$bin/$command" <<'EOF'
#!/usr/bin/env bash
printf '%s' "${0##*/}" >>"$MUTATION_LOG"
printf ' <%s>' "$@" >>"$MUTATION_LOG"
printf '\n' >>"$MUTATION_LOG"
[[ "${FAIL_COMMAND:-}" != "${0##*/}" ]]
EOF
done
chmod +x "$bin"/*
export PATH="$bin:$PATH"

help="$($CLEANUP --help)"
[[ "$help" == *'Still requires'*'confirmation unless --yes is supplied.'* ]] || fail 'help does not describe dry-run confirmation'
[[ "$help" == *'Does not remove'*'components.'* ]] || fail 'help does not describe dry-run no-removal behavior'
[[ "$help" == *'single audit log is written'* ]] || fail 'help does not describe audit logging'

# Publicly observable installed state: a stub, a package, and a web app with spaces.
touch "$HOME/.local/bin/codex" "$HOME/.local/share/applications/Google Maps.desktop"
printf 'obs-studio\n' >"$TEST_TMP_DIR/installed-packages"
cat >"$bin/pacman" <<'EOF'
#!/usr/bin/env bash
[[ "$1" == -Qq ]] || exit 2
grep -Fxq "$2" "$TEST_TMP_DIR/installed-packages"
EOF
chmod +x "$bin/pacman"

set +e
GUM_RESPONSE=accept "$CLEANUP" --dry-run >"$TEST_STDOUT" 2>"$TEST_STDERR"
dry_status=$?
set -e
[[ "$dry_status" -eq 0 ]] || fail "dry-run status $dry_status: $(<"$TEST_STDERR")"
[[ ! -s "$log" ]] || fail 'dry-run invoked a removal or package command'
[[ "$(wc -l <"$confirm_log")" -eq 1 ]] || fail 'dry-run did not request confirmation'
[[ "$(find "$root/backup" -type f | wc -l)" -eq 1 ]] || fail 'dry-run did not create one audit log'
dry_log="$(find "$root/backup" -type f -print -quit)"
[[ "$(grep -c $'\tdry-run$' "$dry_log")" -eq 3 ]] || fail 'dry-run did not audit all installed selected components'
[[ "$(grep -c $'\tskipped: not present$' "$dry_log")" -gt 0 ]] || fail 'dry-run did not preserve absent components as skipped'
[[ "$(<"$TEST_STDOUT")" == *'DRY-RUN: would run: omarchy-webapp-remove "Google Maps"'* ]] || fail 'dry-run did not retain the human-readable spaced name'

: >"$log"
GUM_RESPONSE=reject "$CLEANUP" >"$TEST_STDOUT" 2>"$TEST_STDERR"
[[ "$(<"$TEST_STDOUT")" == 'aborted by user' && ! -e "$root/backup/cleanup."* ]] || fail 'rejected confirmation did not abort before audit creation'
[[ ! -s "$log" ]] || fail 'rejected confirmation invoked a mutation'
[[ "$(wc -l <"$confirm_log")" -eq 2 ]] || fail 'default mode did not request confirmation'

set +e
GUM_RESPONSE=accept "$CLEANUP" --yes >"$TEST_STDOUT" 2>"$TEST_STDERR"
yes_status=$?
set -e
[[ "$yes_status" -eq 0 ]] || fail "--yes status $yes_status: $(<"$TEST_STDERR")"
[[ "$(wc -l <"$confirm_log")" -eq 2 ]] || fail '--yes did not bypass confirmation'
[[ "$(<"$log")" == *$'rm <-f> <'*'/codex>'* && "$(<"$log")" == *$'omarchy-webapp-remove <Google Maps>'* ]] || fail 'removal API arguments were not passed individually and in order'
[[ "$(<"$log")" == *$'omarchy-pkg-drop <obs-studio>'* ]] || fail 'package API did not receive its original argument'
[[ "$(<"$log")" != *'signal-desktop'* ]] || fail 'unselected package was removed'

before="$(find "$root/backup" -type f | wc -l)"
list="$($CLEANUP --list)"
[[ "$list" == *'omarchy-webapp-remove "Google Maps"'* ]] || fail '--list omitted the spaced human-readable name'
[[ "$(find "$root/backup" -type f | wc -l)" -eq "$before" && "$(<"$log")" != *'--list'* ]] || fail '--list wrote an audit or ran a mutation'

: >"$log"
set +e
FAIL_COMMAND=omarchy-webapp-remove GUM_RESPONSE=accept "$CLEANUP" --yes >"$TEST_STDOUT" 2>"$TEST_STDERR"
failure_status=$?
set -e
[[ "$failure_status" -eq 1 ]] || fail "failed API returned $failure_status"
[[ "$(<"$TEST_STDERR")" == *'cleanup.'*'.log' ]] || fail 'failure did not report the partial audit path'
[[ "$(<"$log")" == *$'omarchy-webapp-remove <Google Maps>'* ]] || fail 'failure did not preserve exact spaced API argument'
[[ -e "$HOME/.local/bin/codex" && -e "$HOME/.local/share/applications/Google Maps.desktop" ]] || fail 'test altered simulated installed state'

printf 'PASS: cleanup contract\n'
