#!/usr/bin/env bash

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

setup_test_environment() {
  TEST_TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-tests.XXXXXX")"
  export HOME="$TEST_TMP_DIR/home"
  export TMPDIR="$TEST_TMP_DIR/tmp"
  TEST_STDOUT="$TEST_TMP_DIR/stdout"
  TEST_STDERR="$TEST_TMP_DIR/stderr"
  mkdir -p "$HOME" "$TMPDIR"
}

cleanup_test_environment() {
  rm -rf "${TEST_TMP_DIR:-}"
}

assert_status() {
  local expected="$1"
  shift

  set +e
  "$@" >"$TEST_STDOUT" 2>"$TEST_STDERR"
  local actual=$?
  set -e
  [[ "$actual" -eq "$expected" ]] || fail "expected status $expected, got $actual: $*"
}
