#!/usr/bin/env bash

set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/test-helpers.sh
source "$ROOT_DIR/tests/lib/test-helpers.sh"
setup_test_environment
trap cleanup_test_environment EXIT
failures=0

check() {
  local name="$1"; shift
  if "$@"; then
    printf 'PASS: %s\n' "$name"
  else
    printf 'FAIL: %s\n' "$name" >&2
    failures=$((failures + 1))
  fi
}

no_native_dependencies() {
  local output status
  set +e
  output="$("$ROOT_DIR/setup" --profile omarchy --deps --non-interactive --dry-run 2>"$TEST_STDERR")"
  status=$?
  set -e
  [[ "$status" -eq 0 && ! -s "$TEST_STDERR" ]] &&
    [[ "$output" == *keyd* && "$output" != *postgresql* && "$output" != *valkey* ]]
}

only_keyd_services() {
  local root="$TEST_TMP_DIR/services" status
  mkdir -p "$root/omarchy/utils/bash"
  export RETIREMENT_LOG="$TEST_TMP_DIR/service-calls"
  : >"$RETIREMENT_LOG"
  local helper
  for helper in setup-services-input setup-services-wireguard setup-services-postgresql setup-services-valkey; do
    printf '#!/usr/bin/env bash\nprintf "%%s %%s\\n" "%s" "$*" >>"$RETIREMENT_LOG"\n' "$helper" >"$root/omarchy/utils/bash/$helper"
    chmod +x "$root/omarchy/utils/bash/$helper"
  done
  set +e
  DOTFILES_ROOT="$root" "$ROOT_DIR/omarchy/utils/bash/setup-services" --dry-run --non-interactive >"$TEST_STDOUT" 2>"$TEST_STDERR"
  status=$?
  set -e
  [[ "$status" -eq 0 && ! -s "$TEST_STDOUT" && ! -s "$TEST_STDERR" ]] &&
    [[ "$(<"$RETIREMENT_LOG")" == $'setup-services-input --dry-run --non-interactive\nsetup-services-wireguard --dry-run --non-interactive' ]]
}

keyd_only_help_and_prompt() {
  local help prompt status
  set +e
  help="$("$ROOT_DIR/setup" --help 2>"$TEST_STDERR")"
  status=$?
  set -e
  [[ "$status" -eq 0 && ! -s "$TEST_STDERR" ]] || return 1
  [[ "$help" == *keyd* && "$help" == *WireGuard* && "$help" != *PostgreSQL* && "$help" != *Valkey* ]] || return 1
  set +e
  prompt="$(script -q -e -c "$ROOT_DIR/setup --profile omarchy --dots --dry-run" /dev/null <<< $'n\nn\nn\n' 2>"$TEST_STDERR")"
  status=$?
  set -e
  [[ "$status" -eq 0 && ! -s "$TEST_STDERR" ]] &&
    [[ "$prompt" == *keyd* && "$prompt" == *WireGuard* && "$prompt" != *PostgreSQL* && "$prompt" != *Valkey* && "$prompt" != *'[setup-services-input]'* ]]
}

check 'Omarchy dependencies exclude native databases and retain keyd' no_native_dependencies
check 'Omarchy services dispatch only keyd with flags' only_keyd_services
check 'Omarchy help and declined consent describe only keyd' keyd_only_help_and_prompt
[[ "$failures" -eq 0 ]]
