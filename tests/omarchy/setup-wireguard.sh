#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
SETUP="$ROOT_DIR/setup"
SERVICES_SETUP="$ROOT_DIR/omarchy/utils/bash/setup-services"
WIREGUARD_SETUP="$ROOT_DIR/omarchy/utils/bash/setup-services-wireguard"
DROPIN_SOURCE="$ROOT_DIR/omarchy/etc/systemd/system/wg-quick@wg0.service.d/90-networkmanager-connectivity.conf"

# shellcheck source=../lib/test-helpers.sh
source "$ROOT_DIR/tests/lib/test-helpers.sh"

setup_test_environment
trap cleanup_test_environment EXIT

[[ -x "$WIREGUARD_SETUP" ]] || fail "WireGuard service helper is missing"

BIN="$TEST_TMP_DIR/bin"
mkdir -p "$BIN"
CALL_LOG="$TEST_TMP_DIR/calls.log"
SYSTEM_STATE="$TEST_TMP_DIR/system-state"
mkdir -p "$SYSTEM_STATE"
: >"$CALL_LOG"

cat >"$BIN/sudo" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'sudo %s\n' "$*" >>"${WG_CALL_LOG:?}"
if [[ "${WG_SUDO_FAIL:-0}" == 1 ]]; then
  printf 'simulated sudo failure\n' >&2
  exit 90
fi
args=()
for arg in "$@"; do
  case "$arg" in
    /etc/wireguard/wg0.conf) arg="${WG_TEST_ROOT:?}/etc/wireguard/wg0.conf" ;;
    /etc/keyd/default.conf*) arg="${WG_TEST_ROOT:?}/etc/keyd/default.conf${arg#/etc/keyd/default.conf}" ;;
    /etc/systemd/system/wg-quick@wg0.service.d/90-networkmanager-connectivity.conf)
      arg="${WG_TEST_ROOT:?}/etc/systemd/system/wg-quick@wg0.service.d/90-networkmanager-connectivity.conf"
      ;;
  esac
  args+=("$arg")
done
exec "${args[@]}"
EOF

cat >"$BIN/systemctl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'systemctl %s\n' "$*" >>"${WG_CALL_LOG:?}"
case "$1" in
  daemon-reload) ;;
  is-enabled|is-active)
    operation="$1"
    shift
    [[ "${1:-}" == --quiet ]] && shift
    [[ -e "${WG_SYSTEM_STATE:?}/$1.$([[ "$operation" == is-enabled ]] && printf enabled || printf active)" ]]
    ;;
  enable)
    if [[ " $* " == *' wg-quick@wg0.service '* ]]; then
      [[ " $* " != *' --now '* ]] || { printf 'WireGuard enable --now is forbidden\n' >&2; exit 91; }
      touch "${WG_SYSTEM_STATE:?}/wg-quick@wg0.service.enabled"
    elif [[ " $* " == *' keyd '* ]]; then
      touch "${WG_SYSTEM_STATE:?}/keyd.enabled" "${WG_SYSTEM_STATE:?}/keyd.active"
    else
      printf 'unexpected unit: %s\n' "$*" >&2
      exit 92
    fi
    ;;
  start|stop|restart|disable|try-restart|reload)
    printf 'forbidden systemctl operation: %s\n' "$*" >&2
    exit 93
    ;;
  *) printf 'unexpected systemctl operation: %s\n' "$*" >&2; exit 94 ;;
esac
EOF

cat >"$BIN/chown" <<'EOF'
#!/usr/bin/env bash
printf 'chown %s\n' "$*" >>"${WG_CALL_LOG:?}"
EOF

for tool in wg wg-quick resolvconf nmcli timeout; do
  cat >"$BIN/$tool" <<EOF
#!/usr/bin/env bash
printf '$tool %s\\n' "\$*" >>"\${WG_CALL_LOG:?}"
EOF
done
cat >"$BIN/keyd" <<'EOF'
#!/usr/bin/env bash
printf 'keyd %s\\n' "$*" >>"${WG_CALL_LOG:?}"
[[ "$1" == reload ]]
EOF
chmod +x "$BIN"/*

new_case() {
  WG_TEST_ROOT="$TEST_TMP_DIR/$1"
  WG_SYSTEM_STATE="$SYSTEM_STATE/$1"
  mkdir -p "$WG_TEST_ROOT/etc/keyd" "$WG_SYSTEM_STATE"
  export WG_TEST_ROOT WG_SYSTEM_STATE
}

run_helper() {
  local status
  set +e
  PATH="$BIN:$PATH" DOTFILES_ROOT="$ROOT_DIR" WG_CALL_LOG="$CALL_LOG" \
    "$WIREGUARD_SETUP" "$@" >"$TEST_STDOUT" 2>"$TEST_STDERR"
  status=$?
  set -e
  return "$status"
}

run_setup() {
  local status
  set +e
  PATH="$BIN:$PATH" DOTFILES_ROOT="$ROOT_DIR" WG_CALL_LOG="$CALL_LOG" \
    "$SETUP" --profile omarchy --services --non-interactive "$@" >"$TEST_STDOUT" 2>"$TEST_STDERR"
  status=$?
  set -e
  return "$status"
}

capture_helper() {
  if run_helper "$@"; then RESULT_STATUS=0; else RESULT_STATUS=$?; fi
}

capture_setup() {
  if run_setup "$@"; then RESULT_STATUS=0; else RESULT_STATUS=$?; fi
}

assert_output() {
  local expected_status="$1" expected_stdout="$2" expected_stderr="$3"
  [[ "$RESULT_STATUS" -eq "$expected_status" ]] || fail "expected status $expected_status, got $RESULT_STATUS"
  printf '%s' "$expected_stdout" >"$TEST_TMP_DIR/expected.stdout"
  printf '%s' "$expected_stderr" >"$TEST_TMP_DIR/expected.stderr"
  cmp -s "$TEST_STDOUT" "$TEST_TMP_DIR/expected.stdout" || fail "stdout differed from exact expected output: expected $(<"$TEST_TMP_DIR/expected.stdout"); got $(<"$TEST_STDOUT")"
  cmp -s "$TEST_STDERR" "$TEST_TMP_DIR/expected.stderr" || fail "stderr differed from exact expected output: expected $(<"$TEST_TMP_DIR/expected.stderr"); got $(<"$TEST_STDERR")"
}

assert_no_network_operations() {
  [[ "$(<"$CALL_LOG")" != *'systemctl start wg-quick@wg0.service'* && \
    "$(<"$CALL_LOG")" != *'systemctl stop wg-quick@wg0.service'* && \
    "$(<"$CALL_LOG")" != *'systemctl restart wg-quick@wg0.service'* && \
    "$(<"$CALL_LOG")" != *'systemctl enable --now wg-quick@wg0.service'* && \
    "$(<"$CALL_LOG")" != *'sudo wg-quick '* ]] || fail "WireGuard setup attempted a network or immediate service operation"
}

# Public dry-run previews the WireGuard phase without calling sudo/systemctl or writing state.
new_case dry-run
: >"$CALL_LOG"
capture_helper --dry-run
assert_output 0 $'[setup-services-wireguard] [dry-run] would install or reuse the non-secret WireGuard systemd drop-in at /etc/systemd/system/wg-quick@wg0.service.d/90-networkmanager-connectivity.conf\n[setup-services-wireguard] [dry-run] would secure /etc/wireguard/wg0.conf to root:root mode 0600 only if it is a regular, non-symlink file\n[setup-services-wireguard] [dry-run] would enable wg-quick@wg0.service for boot only when /etc/wireguard/wg0.conf exists as a regular, non-symlink file\n[setup-services-wireguard] [dry-run] would not start, stop, or restart the VPN\n' ''
capture_setup --dry-run
[[ "$RESULT_STATUS" -eq 0 && "$(<"$TEST_STDOUT")" == *"WireGuard"* && "$(<"$TEST_STDOUT")" == *"[dry-run]"* ]] || fail "public services dry-run did not describe WireGuard actions"
[[ ! -s "$CALL_LOG" ]] || fail "services dry-run invoked a privileged or service command"
[[ ! -e "$WG_TEST_ROOT/etc/wireguard/wg0.conf" && ! -e "$WG_TEST_ROOT/etc/systemd/system/wg-quick@wg0.service.d/90-networkmanager-connectivity.conf" ]] || fail "services dry-run changed the isolated system root"

# Missing config still installs/reuses the non-secret unit drop-in but never alters unit enablement.
new_case missing-config
: >"$CALL_LOG"
mkdir -p "$WG_SYSTEM_STATE"
touch "$WG_SYSTEM_STATE/wg-quick@wg0.service.enabled"
capture_helper
assert_output 0 $'[setup-services-wireguard] Installing the non-secret WireGuard systemd drop-in\n[setup-services-wireguard] /etc/wireguard/wg0.conf is not found; not enabling or disabling wg-quick@wg0.service\n' ''
[[ -f "$WG_TEST_ROOT/etc/systemd/system/wg-quick@wg0.service.d/90-networkmanager-connectivity.conf" ]] || fail "missing-config setup did not install the drop-in"
cmp -s "$DROPIN_SOURCE" "$WG_TEST_ROOT/etc/systemd/system/wg-quick@wg0.service.d/90-networkmanager-connectivity.conf" || fail "installed drop-in differs from the approved source"
[[ ! -e "$WG_TEST_ROOT/etc/wireguard/wg0.conf" ]] || fail "setup created a VPN config"
[[ "$(<"$TEST_STDOUT")" == *"not found"* && "$(<"$TEST_STDOUT")" == *"not enabling"* ]] || fail "missing config was not clearly reported"
[[ "$(<"$CALL_LOG")" == *'systemctl daemon-reload'* ]] || fail "new drop-in did not trigger daemon-reload"
[[ "$(<"$CALL_LOG")" != *'systemctl enable '* && "$(<"$CALL_LOG")" != *'systemctl disable '* ]] || fail "missing config changed WireGuard enablement"
[[ -e "$WG_SYSTEM_STATE/wg-quick@wg0.service.enabled" ]] || fail "missing config changed prior enabled state"
assert_no_network_operations

# Configured setup through ./setup enforces root-only config permissions, installs the exact drop-in,
# reloads systemd and enables at boot without starting the tunnel.
new_case configured
mkdir -p "$WG_TEST_ROOT/etc/wireguard"
printf 'private-key-content-must-not-change\n' >"$WG_TEST_ROOT/etc/wireguard/wg0.conf"
chmod 644 "$WG_TEST_ROOT/etc/wireguard/wg0.conf"
: >"$CALL_LOG"
capture_setup
assert_output 0 $'[setup-services] Recorded service state: keyd enabled=0 active=0\n[setup-services] Installing keyd configuration before changing services\n[setup-services] Enabling keyd\n[setup-services] Reloading keyd configuration\n[setup-services] Services configured successfully; no previous keyd configuration required a backup\n[setup-services-wireguard] Installing the non-secret WireGuard systemd drop-in\n[setup-services-wireguard] Enabling wg-quick@wg0.service for boot without starting the VPN\n[setup-services-wireguard] WireGuard boot configuration completed successfully\n' ''
[[ "$(<"$WG_TEST_ROOT/etc/wireguard/wg0.conf")" == 'private-key-content-must-not-change' ]] || fail "wg0.conf content changed"
[[ "$(stat -c '%a' "$WG_TEST_ROOT/etc/wireguard/wg0.conf")" == 600 ]] || fail "wg0.conf was not secured to mode 0600"
[[ "$(<"$CALL_LOG")" == *"chown root:root -- $WG_TEST_ROOT/etc/wireguard/wg0.conf"* ]] || fail "wg0.conf root ownership was not enforced"
cmp -s "$DROPIN_SOURCE" "$WG_TEST_ROOT/etc/systemd/system/wg-quick@wg0.service.d/90-networkmanager-connectivity.conf" || fail "configured drop-in differs from the approved source"
[[ "$(<"$CALL_LOG")" == *'systemctl daemon-reload'* && "$(<"$CALL_LOG")" == *'systemctl enable wg-quick@wg0.service'* ]] || fail "configured service was not reloaded and boot-enabled"
[[ -e "$WG_SYSTEM_STATE/wg-quick@wg0.service.enabled" ]] || fail "systemctl enable did not mark the unit enabled"
assert_no_network_operations

# Repeated setup reuses identical tracked content and does not reinstall the drop-in.
install_count="$(grep -c '^sudo install -D -m 644 -- .*90-networkmanager-connectivity.conf$' "$CALL_LOG" || true)"
reload_count="$(grep -c '^systemctl daemon-reload$' "$CALL_LOG" || true)"
capture_helper
assert_output 0 $'[setup-services-wireguard] Reusing identical systemd drop-in at /etc/systemd/system/wg-quick@wg0.service.d/90-networkmanager-connectivity.conf\n[setup-services-wireguard] Enabling wg-quick@wg0.service for boot without starting the VPN\n[setup-services-wireguard] WireGuard boot configuration completed successfully\n' ''
[[ "$(grep -c '^sudo install -D -m 644 -- .*90-networkmanager-connectivity.conf$' "$CALL_LOG" || true)" == "$install_count" ]] || fail "idempotent run reinstalled the drop-in"
[[ "$(grep -c '^systemctl daemon-reload$' "$CALL_LOG" || true)" == "$reload_count" ]] || fail "idempotent run unnecessarily reloaded systemd"
[[ "$(<"$WG_TEST_ROOT/etc/wireguard/wg0.conf")" == 'private-key-content-must-not-change' ]] || fail "idempotent run changed wg0.conf content"
assert_no_network_operations

# Identical migration drop-in is reusable; differing content and symlinked configs are rejected safely.
new_case identical-dropin
mkdir -p "$WG_TEST_ROOT/etc/systemd/system/wg-quick@wg0.service.d"
cp "$DROPIN_SOURCE" "$WG_TEST_ROOT/etc/systemd/system/wg-quick@wg0.service.d/90-networkmanager-connectivity.conf"
: >"$CALL_LOG"
capture_helper
assert_output 0 $'[setup-services-wireguard] Reusing identical systemd drop-in at /etc/systemd/system/wg-quick@wg0.service.d/90-networkmanager-connectivity.conf\n[setup-services-wireguard] /etc/wireguard/wg0.conf is not found; not enabling or disabling wg-quick@wg0.service\n' ''
[[ "$(<"$CALL_LOG")" != *'sudo install '* && "$(<"$CALL_LOG")" != *'systemctl daemon-reload'* ]] || fail "identical drop-in was rewritten or needlessly reloaded"

new_case conflicting-dropin
mkdir -p "$WG_TEST_ROOT/etc/systemd/system/wg-quick@wg0.service.d"
printf 'local administrator content\n' >"$WG_TEST_ROOT/etc/systemd/system/wg-quick@wg0.service.d/90-networkmanager-connectivity.conf"
: >"$CALL_LOG"
capture_helper
assert_output 1 '' $'[setup-services-wireguard] ERROR: existing systemd drop-in conflicts with the tracked file; preserving /etc/systemd/system/wg-quick@wg0.service.d/90-networkmanager-connectivity.conf\n'
[[ "$(<"$WG_TEST_ROOT/etc/systemd/system/wg-quick@wg0.service.d/90-networkmanager-connectivity.conf")" == 'local administrator content' ]] || fail "conflicting drop-in was overwritten"
[[ "$(<"$CALL_LOG")" != *'systemctl '* && "$(<"$CALL_LOG")" != *'sudo install '* ]] || fail "drop-in conflict changed service state or installed content"

new_case symlink-config
mkdir -p "$WG_TEST_ROOT/etc/wireguard"
printf 'must remain untouched\n' >"$WG_TEST_ROOT/secret-referent.conf"
ln -s "$WG_TEST_ROOT/secret-referent.conf" "$WG_TEST_ROOT/etc/wireguard/wg0.conf"
: >"$CALL_LOG"
capture_helper
assert_output 1 '' $'[setup-services-wireguard] ERROR: /etc/wireguard/wg0.conf is a symlink; refusing to follow it or enable wg-quick@wg0.service\n'
[[ -L "$WG_TEST_ROOT/etc/wireguard/wg0.conf" && "$(readlink "$WG_TEST_ROOT/etc/wireguard/wg0.conf")" == "$WG_TEST_ROOT/secret-referent.conf" ]] || fail "unsafe wg0.conf symlink changed"
[[ "$(<"$WG_TEST_ROOT/secret-referent.conf")" == 'must remain untouched' ]] || fail "unsafe config referent changed"
[[ "$(<"$CALL_LOG")" != *'systemctl enable '* ]] || fail "symlinked config caused boot enablement"

# Privilege failures and absent package prerequisites fail without claiming success or mutating state.
new_case privilege-failure
: >"$CALL_LOG"
set +e
PATH="$BIN:$PATH" DOTFILES_ROOT="$ROOT_DIR" WG_CALL_LOG="$CALL_LOG" WG_SUDO_FAIL=1 \
  "$WIREGUARD_SETUP" >"$TEST_STDOUT" 2>"$TEST_STDERR"
privilege_status=$?
set -e
RESULT_STATUS="$privilege_status"
assert_output 1 '' $'simulated sudo failure\n[setup-services-wireguard] ERROR: could not inspect /etc/wireguard/wg0.conf safely\n'
[[ "$(<"$CALL_LOG")" != *'systemctl '* ]] || fail "privilege failure changed service state"

new_case missing-prerequisite
MINIMAL_BIN="$TEST_TMP_DIR/minimal-bin"
mkdir -p "$MINIMAL_BIN"
for tool in bash dirname; do
  ln -s "$(command -v "$tool")" "$MINIMAL_BIN/$tool"
done
for tool in systemctl sudo wg-quick resolvconf nmcli timeout; do
  ln -s "$BIN/$tool" "$MINIMAL_BIN/$tool"
done
: >"$CALL_LOG"
set +e
PATH="$MINIMAL_BIN" DOTFILES_ROOT="$ROOT_DIR" WG_CALL_LOG="$CALL_LOG" \
  "$WIREGUARD_SETUP" >"$TEST_STDOUT" 2>"$TEST_STDERR"
prerequisite_status=$?
set -e
RESULT_STATUS="$prerequisite_status"
assert_output 1 '' "[setup-services-wireguard] ERROR: required command 'wg' is not on PATH; install its package before --services"$'\n'
[[ ! -s "$CALL_LOG" ]] || fail "missing prerequisite invoked privilege or service commands"

printf 'PASS: Omarchy WireGuard startup contracts\n'
