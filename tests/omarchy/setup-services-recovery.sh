#!/usr/bin/env bash

set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib/test-helpers.sh
source "$ROOT_DIR/tests/lib/test-helpers.sh"
setup_test_environment
trap cleanup_test_environment EXIT
# Run the contract from isolated caller directories to prove it preserves an existing
# service_log and does not create one when absent.
existing_cwd="$TEST_TMP_DIR/caller-existing"; absent_cwd="$TEST_TMP_DIR/caller-absent"
mkdir -p "$existing_cwd" "$absent_cwd"; printf 'caller-owned log\n' >"$existing_cwd/service_log"; cp "$existing_cwd/service_log" "$TEST_TMP_DIR/caller-log.expected"
(cd "$existing_cwd" && bash "$ROOT_DIR/tests/omarchy/setup-contract.sh" >"$TEST_TMP_DIR/contract-existing.out")
cmp -s "$existing_cwd/service_log" "$TEST_TMP_DIR/caller-log.expected" || fail 'contract test changed caller service_log'
(cd "$absent_cwd" && bash "$ROOT_DIR/tests/omarchy/setup-contract.sh" >"$TEST_TMP_DIR/contract-absent.out")
[[ ! -e "$absent_cwd/service_log" ]] || fail 'contract test created caller service_log'
printf 'PASS: Omarchy contract caller isolation\n'
