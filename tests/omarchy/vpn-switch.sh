#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
command_path="$ROOT_DIR/omarchy/utils/bash/vpn-switch"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/state"
export VPN_TEST_STATE="$tmp/state" XDG_RUNTIME_DIR="$tmp" PATH="$tmp/bin:$PATH"
cat > "$tmp/bin/sudo" <<'SH'
#!/usr/bin/env bash
exec "$@"
SH
cat > "$tmp/bin/flock" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1" == -n && "$2" == -E && "$3" == 75 && "$4" == /run/lock/vpn-switch.lock ]] || exit 90
shift 4
[[ ! -f "$VPN_TEST_STATE/locked" ]] || exit 75
exec "$@"
SH
cat > "$tmp/bin/systemctl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$VPN_TEST_STATE/log"
action="$1"; shift
case "$action" in
 show)
  unit="${@: -1}"; unit="${unit#wg-quick@}"; unit="${unit%.service}"
  if [[ -f "$VPN_TEST_STATE/$unit" ]]; then echo active; else echo inactive; fi ;;
 stop)
  unit="${1#wg-quick@}"; unit="${unit%.service}"
  [[ ! -f "$VPN_TEST_STATE/fail-stop" ]] || exit 1
  rm -f "$VPN_TEST_STATE/$unit" ;;
 start)
  unit="${1#wg-quick@}"; unit="${unit%.service}"
  if [[ -f "$VPN_TEST_STATE/partial-$unit" ]]; then touch "$VPN_TEST_STATE/$unit"; exit 1; fi
  [[ ! -f "$VPN_TEST_STATE/fail-$unit" ]] || exit 1
  touch "$VPN_TEST_STATE/$unit" ;;
esac
SH
chmod +x "$tmp/bin/sudo" "$tmp/bin/flock" "$tmp/bin/systemctl"
run() { set +e; bash "$command_path" "$@" >"$tmp/out" 2>"$tmp/err"; status=$?; set -e; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
touch "$tmp/state/wg0" "$tmp/state/locked"
run wg1
[[ $status != 0 && -e "$tmp/state/wg0" && ! -e "$tmp/state/wg1" ]] || fail 'global lock prevents concurrent switches'
rm "$tmp/state/locked"
run wg1
[[ $status == 0 && ! -e "$tmp/state/wg0" && -e "$tmp/state/wg1" ]] || fail 'switch wg0 to wg1'
run wg0
[[ $status == 0 && -e "$tmp/state/wg0" && ! -e "$tmp/state/wg1" ]] || fail 'switch wg1 to wg0'
run invalid
[[ $status != 0 && -e "$tmp/state/wg0" && ! -e "$tmp/state/wg1" ]] || fail 'reject invalid profile without changes'
touch "$tmp/state/fail-wg1"
run wg1
[[ $status != 0 && -e "$tmp/state/wg0" && ! -e "$tmp/state/wg1" ]] || fail 'restore previous profile after failed start'
rm "$tmp/state/fail-wg1"
touch "$tmp/state/partial-wg1"
run wg1
[[ $status != 0 && ! -e "$tmp/state/wg0" && -e "$tmp/state/wg1" ]] || fail 'do not restore previous profile if target remains active'
rm "$tmp/state/partial-wg1" "$tmp/state/wg1"
touch "$tmp/state/wg0" "$tmp/state/wg1"
run wg0
[[ $status != 0 && -e "$tmp/state/wg0" && -e "$tmp/state/wg1" ]] || fail 'refuse to switch when both profiles are active'
rm "$tmp/state/wg1"
touch "$tmp/state/fail-stop"
run wg1
[[ $status != 0 && -e "$tmp/state/wg0" && ! -e "$tmp/state/wg1" ]] || fail 'do not start target when stop fails'
printf 'PASS: WireGuard profile switching\n'
