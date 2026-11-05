#!/usr/bin/env bash

set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/test-helpers.sh
source "$ROOT_DIR/tests/lib/test-helpers.sh"
setup_test_environment
trap cleanup_test_environment EXIT
BIN="$TEST_TMP_DIR/bin"; STATE="$TEST_TMP_DIR/state"; mkdir -p "$BIN" "$STATE"
export SERVICE_STATE="$STATE" SERVICE_LOG="$TEST_TMP_DIR/services.log" VALKEY_PING_LOG="$TEST_TMP_DIR/valkey-pings.log" SS_LOG="$TEST_TMP_DIR/ss.log"
export DOTFILES_BACKUP_DIR="$TEST_TMP_DIR/backups"
mkdir -p "$DOTFILES_BACKUP_DIR"
cat >"$BIN/sudo" <<'SH'
#!/usr/bin/env bash
set -e
[[ "$1" == -u ]] && shift 2
if [[ "$1" == install ]]; then
  shift
  dest="${!#}"
  if [[ "${FAIL_INSTALL:-0}" == 1 ]]; then printf partial >"$dest"; exit 9; fi
  while [[ $# -gt 0 ]]; do case "$1" in -o|-g|-m) shift 2;; *) break;; esac; done
  exec install "$@"
fi
if [[ "$1" == cp && "${FAIL_RESTORE:-0}" == 1 && "${4:-}" == "$DOTFILES_BACKUP_DIR"* ]]; then exit 8; fi
if [[ "$1" == rm && "${FAIL_RESTORE:-0}" == 1 ]]; then exit 8; fi
exec "$@"
SH
cat >"$BIN/systemctl" <<'SH'
#!/usr/bin/env bash
set -e
printf '%s\n' "$*" >>"$SERVICE_LOG"
cmd="$1"; shift; [[ "${1:-}" == --quiet ]] && shift; unit="$1"
case "$cmd" in
 is-enabled) [[ -e "$SERVICE_STATE/$unit.enabled" ]];;
 is-active) [[ -e "$SERVICE_STATE/$unit.active" ]];;
 enable) touch "$SERVICE_STATE/$unit.enabled"; [[ "${FAIL_ENABLE:-0}" != 1 ]];;
 disable) rm -f "$SERVICE_STATE/$unit.enabled";;
 start) touch "$SERVICE_STATE/$unit.active"; [[ "${FAIL_START:-0}" != 1 ]] || exit 7;;
 stop) rm -f "$SERVICE_STATE/$unit.active";;
 reload) [[ "${FAIL_RELOAD:-0}" != 1 ]];;
 restart) [[ "${FAIL_RESTART:-0}" != 1 ]];;
 *) exit 0;;
esac
SH
cat >"$BIN/getent" <<'SH'
#!/usr/bin/env bash
exit 0
SH
cat >"$BIN/id" <<'SH'
#!/usr/bin/env bash
[[ "$1" == -nG ]] && printf '%s\n' "${CURRENT_GROUPS:-users}"
SH
cat >"$BIN/valkey-cli" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$VALKEY_PING_LOG"
printf 'PONG\n'
SH
cat >"$BIN/ss" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$SS_LOG"
printf '%s\n' "${SS_OUTPUT-LISTEN 0 511 127.0.0.1:6379 0.0.0.0:*}"
[[ "${FAIL_SS:-0}" != 1 ]]
SH
chmod +x "$BIN"/*
export PATH="$BIN:$PATH" CURRENT_GROUPS=users
VALKEY="$ROOT_DIR/omarchy/utils/bash/setup-services-valkey"
run_valkey() {
  set +e
  "$VALKEY" --non-interactive >"$TEST_STDOUT" 2>"$TEST_STDERR"
  result=$?
  set -e
}
reset_state() { rm -f "$STATE"/*; : >"$SERVICE_LOG"; : >"$VALKEY_PING_LOG"; : >"$SS_LOG"; }

# ss failures and empty output must reject and roll back rather than report readiness.
for mode in failed empty external; do
  reset_state; target="$TEST_TMP_DIR/$mode.conf"; printf 'prior config' >"$target"
  case "$mode" in failed) export FAIL_SS=1 SS_OUTPUT='LISTEN 0 511 127.0.0.1:6379 0.0.0.0:*';; empty) export FAIL_SS=0 SS_OUTPUT='';; external) export FAIL_SS=0 SS_OUTPUT='LISTEN 0 511 0.0.0.0:6379 0.0.0.0:*';; esac
  export VALKEY_CONFIG="$target"
  run_valkey
  [[ "$result" -eq 1 ]] || fail "$mode listener inspection returned $result, expected 1"
  [[ "$(<"$target")" == 'prior config' ]] || fail "$mode did not restore prior configuration"
  [[ "$(<"$TEST_STDERR")" == '[setup-services-valkey] ERROR: Valkey port 6379 is exposed beyond loopback' ]] || fail "$mode diagnostic differed: $(<"$TEST_STDERR")"
  [[ ! -e "$STATE/valkey.service.enabled" && ! -e "$STATE/valkey.service.active" ]] || fail "$mode failure did not restore initial service state"
done

# A failed install may have partially written its destination; recovery preserves old or absent state.
for existed in yes no; do
  for initial_state in disabled-inactive enabled-inactive disabled-active enabled-active; do
    reset_state; target="$TEST_TMP_DIR/install-$existed-$initial_state.conf"; rm -f "$target"
    [[ "$existed" == no ]] || printf 'prior config' >"$target"
    [[ "$initial_state" != enabled-inactive && "$initial_state" != enabled-active ]] || touch "$STATE/valkey.service.enabled"
    [[ "$initial_state" != disabled-active && "$initial_state" != enabled-active ]] || touch "$STATE/valkey.service.active"
    export VALKEY_CONFIG="$target" FAIL_INSTALL=1 FAIL_RESTORE=0 FAIL_SS=0 SS_OUTPUT='LISTEN 0 511 127.0.0.1:6379 0.0.0.0:*'
    run_valkey
    [[ "$result" -eq 1 ]] || fail "partial install ($existed/$initial_state) returned $result"
    if [[ "$existed" == yes ]]; then
      [[ "$(<"$target")" == 'prior config' ]] || fail 'partial install did not restore prior destination'
      [[ "$(<"$DOTFILES_BACKUP_DIR/${target#/*}")" == 'prior config' ]] || fail 'partial install did not retain the original backup'
    else
      [[ ! -e "$target" ]] || fail 'partial install left new destination'
      [[ ! -e "$DOTFILES_BACKUP_DIR/${target#/*}" ]] || fail 'partial install created a backup without a prior destination'
    fi
    [[ "$(<"$TEST_STDERR")" == "[setup-services-valkey] ERROR: could not install $target" ]] || fail "partial install diagnostic differed: $(<"$TEST_STDERR")"
    if [[ "$initial_state" == enabled-* ]]; then [[ -e "$STATE/valkey.service.enabled" ]] || fail "enabled state changed for $initial_state"; else [[ ! -e "$STATE/valkey.service.enabled" ]] || fail "enabled state changed for $initial_state"; fi
    if [[ "$initial_state" == *-active ]]; then [[ -e "$STATE/valkey.service.active" ]] || fail "active state changed for $initial_state"; else [[ ! -e "$STATE/valkey.service.active" ]] || fail "active state changed for $initial_state"; fi
  done
done

# Failed recovery must be surfaced rather than hidden behind the install error.
reset_state; target="$TEST_TMP_DIR/restore-failure.conf"; printf 'prior config' >"$target"
export VALKEY_CONFIG="$target" FAIL_INSTALL=1 FAIL_RESTORE=1
run_valkey
[[ "$result" -eq 1 ]] || fail "recovery failure returned $result"
[[ "$(<"$TEST_STDOUT")" == *"[setup-services-valkey] Recovery ERROR: could not restore $target"* ]] || fail "recovery failure was not reported: $(<"$TEST_STDOUT")"

# Preserve enabled/active status when a restart fails after configuration changes.
reset_state; target="$TEST_TMP_DIR/active.conf"; printf 'prior config' >"$target"
touch "$STATE/valkey.service.enabled" "$STATE/valkey.service.active"
export VALKEY_CONFIG="$target" FAIL_INSTALL=0 FAIL_RESTORE=0 FAIL_RESTART=1
run_valkey
[[ "$result" -eq 1 ]] || fail "restart failure returned $result"
[[ "$(<"$target")" == 'prior config' ]] || fail 'restart failure did not restore prior configuration'
[[ -e "$STATE/valkey.service.enabled" && -e "$STATE/valkey.service.active" ]] || fail 'restart failure changed initial enabled/active state'

# A start failure after enablement restores the prior file and disabled/inactive state.
reset_state; target="$TEST_TMP_DIR/start-failure.conf"; printf 'prior config' >"$target"
export VALKEY_CONFIG="$target" FAIL_INSTALL=0 FAIL_START=1 FAIL_RESTORE=0
run_valkey
[[ "$result" -eq 1 ]] || fail "start failure returned $result"
[[ "$(<"$target")" == 'prior config' ]] || fail 'start failure did not restore prior configuration'
[[ ! -e "$STATE/valkey.service.enabled" && ! -e "$STATE/valkey.service.active" ]] || fail 'start failure did not restore initial disabled/inactive state'
[[ "$(<"$TEST_STDERR")" == "[setup-services-valkey] ERROR: could not start valkey.service" ]] || fail 'start failure diagnostic changed'

# Successful TCP, socket, and loopback checks retain the existing success path.
reset_state; target="$TEST_TMP_DIR/success.conf"; printf 'prior config' >"$target"
export VALKEY_CONFIG="$target" CURRENT_GROUPS='users valkey' FAIL_INSTALL=0 FAIL_START=0 FAIL_RESTART=0 FAIL_SS=0 SS_OUTPUT='LISTEN 0 511 127.0.0.1:6379 0.0.0.0:*'
run_valkey
[[ "$result" -eq 0 ]] || fail "valid Valkey setup failed: $(<"$TEST_STDERR")"
[[ "$(<"$TEST_STDOUT")" == *'[setup-services-valkey] Valkey is ready'* ]] || fail 'valid Valkey success message changed'
[[ "$(<"$target")" == "$(<"$ROOT_DIR/omarchy/etc/valkey/valkey.conf")" ]] || fail 'valid setup did not install expected config'
[[ "$(<"$SERVICE_LOG")" == *'restart valkey.service'* ]] || fail 'successful Valkey setup did not restart changed config'
[[ "$(<"$VALKEY_PING_LOG")" == $'-h 127.0.0.1 -p 6379 ping\n-s /run/valkey/valkey.sock ping' ]] || fail 'success path did not validate both TCP and socket'
[[ "$(<"$SS_LOG")" == "-ltnH sport = :6379" ]] || fail 'success path did not validate the listener'

# Dry-run remains side-effect free and preserves the exact baseline output contract.
reset_state
"$VALKEY" --dry-run >"$TEST_STDOUT" 2>"$TEST_STDERR"
expected_valkey="$(printf '[setup-services-valkey] [dry-run] would verify valkey user and group\n[setup-services-valkey] [dry-run] would ask before adding %s to valkey only in an interactive run\n[setup-services-valkey] [dry-run] would install configuration: %s\n[setup-services-valkey] [dry-run] would enable and start valkey.service\n[setup-services-valkey] [dry-run] would restart valkey.service if configuration changed\n[setup-services-valkey] [dry-run] would validate TCP, /run/valkey/valkey.sock, and loopback-only port 6379' "$USER" "$VALKEY_CONFIG")"
[[ "$result" -eq 0 && "$(<"$TEST_STDOUT")" == "$expected_valkey" && ! -s "$TEST_STDERR" ]] || fail "Valkey dry-run output differs from baseline: $(<"$TEST_STDOUT")"
[[ ! -s "$SERVICE_LOG" ]] || fail 'dry-run touched simulated service state'
pg_data="$TEST_TMP_DIR/postgres-dry-data"
set +e
POSTGRES_DATA_DIR="$pg_data" "$ROOT_DIR/omarchy/utils/bash/setup-services-postgresql" --dry-run >"$TEST_STDOUT" 2>"$TEST_STDERR"
result=$?
set -e
expected_postgres="$(printf '[setup-services-postgresql] [dry-run] would initialize PostgreSQL only if %s is absent or empty\n[setup-services-postgresql] [dry-run] would install configuration: %s/pg_hba.conf\n[setup-services-postgresql] [dry-run] would enable and start postgresql.service\n[setup-services-postgresql] [dry-run] would reload postgresql.service if configuration changed\n[setup-services-postgresql] [dry-run] would validate PostgreSQL through /run/postgresql and localhost TCP' "$pg_data" "$pg_data")"
[[ "$result" -eq 0 && "$(<"$TEST_STDOUT")" == "$expected_postgres" && ! -s "$TEST_STDERR" ]] || fail 'PostgreSQL dry-run output differs from baseline'
[[ ! -s "$SERVICE_LOG" ]] || fail 'PostgreSQL dry-run touched simulated service state'

# Run the contract from isolated caller directories to prove it preserves an existing
# service_log and does not create one when absent.
existing_cwd="$TEST_TMP_DIR/caller-existing"; absent_cwd="$TEST_TMP_DIR/caller-absent"
mkdir -p "$existing_cwd" "$absent_cwd"; printf 'caller-owned log\n' >"$existing_cwd/service_log"; cp "$existing_cwd/service_log" "$TEST_TMP_DIR/caller-log.expected"
(cd "$existing_cwd" && bash "$ROOT_DIR/tests/omarchy/setup-contract.sh" >"$TEST_TMP_DIR/contract-existing.out")
cmp -s "$existing_cwd/service_log" "$TEST_TMP_DIR/caller-log.expected" || fail 'contract test changed caller service_log'
(cd "$absent_cwd" && bash "$ROOT_DIR/tests/omarchy/setup-contract.sh" >"$TEST_TMP_DIR/contract-absent.out")
[[ ! -e "$absent_cwd/service_log" ]] || fail 'contract test created caller service_log'
printf 'PASS: Omarchy service recovery and listener checks\n'
