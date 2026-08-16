#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<EOF
Usage: $0 [all|omarchy|fedora-wsl2]

Run setup contract tests for one profile or all profiles (default).
EOF
}

run_suite() {
  local profile="$1"

  printf '==> %s\n' "$profile"
  "$ROOT_DIR/tests/$profile/setup-contract.sh"
}

case "${1:-all}" in
  all)
    run_suite omarchy
    run_suite fedora-wsl2
    ;;
  omarchy|fedora-wsl2) run_suite "$1" ;;
  --help|-h) usage ;;
  *)
    usage >&2
    exit 2
    ;;
esac
