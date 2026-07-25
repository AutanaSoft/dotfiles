#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP="$ROOT_DIR/setup"
FONT_SETUP="$ROOT_DIR/omarchy/utils/bash/setup-fonts"
SERVICES_SETUP="$ROOT_DIR/omarchy/utils/bash/setup-services"
DEP_SETUP="$ROOT_DIR/omarchy/utils/bash/setup-deps"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_status() {
    local expected="$1"
    shift
    set +e
    "$@" >/tmp/setup-contract.stdout 2>/tmp/setup-contract.stderr
    local actual=$?
    set -e
    [[ "$actual" -eq "$expected" ]] || fail "expected status $expected, got $actual: $*"
}

assert_output_contains() {
    local needle="$1"
    shift
    "$@" > /tmp/setup-contract.stdout 2>/tmp/setup-contract.stderr
    [[ "$(< /tmp/setup-contract.stdout)" == *"$needle"* ]] || {
        cat /tmp/setup-contract.stdout >&2
        fail "output did not contain: $needle"
    }
}

assert_dependency_status() {
    local expected="$1"
    shift
    set +e
    DOTFILES_ROOT="$manifest_root" "$DEP_SETUP" --omarchy --dry-run > /tmp/setup-contract.stdout 2>/tmp/setup-contract.stderr
    local actual=$?
    set -e
    [[ "$actual" -eq "$expected" ]] || fail "expected dependency status $expected, got $actual"
}

tmp_home="$(mktemp -d)"
trap 'rm -rf "$tmp_home" "${manifest_root:-}" /tmp/setup-contract.stdout /tmp/setup-contract.stderr' EXIT
export HOME="$tmp_home"
export TMPDIR="$tmp_home/tmp"
mkdir -p "$TMPDIR"

assert_status 2 "$SETUP" --profile omarchy --dots-only --services --dry-run
assert_status 2 "$SETUP" --profile omarchy --dots --dots-only --dry-run
assert_status 2 "$SETUP" --profile omarchy --no-validate --dry-run

deps_output="$($SETUP --profile omarchy --deps --non-interactive --dry-run)"
[[ "$deps_output" == *"[setup-deps]"* ]] || fail "--deps did not dispatch to setup-deps"
[[ "$deps_output" != *"[setup-fonts]"* ]] || fail "--deps unexpectedly dispatched fonts"
[[ "$deps_output" != *"[setup-services]"* ]] || fail "--deps unexpectedly dispatched services"

dots_output="$($SETUP --profile omarchy --dots-only --non-interactive --dry-run)"
[[ "$dots_output" == *"[setup-dots]"* ]] || fail "--dots-only did not dispatch to setup-dots"
for excluded in setup-deps setup-fonts setup-services setup-locale setup-validate; do
    [[ "$dots_output" != *"[$excluded]"* ]] || fail "--dots-only dispatched excluded phase $excluded"
done

before="$(find "$tmp_home" -mindepth 1 -print | sort)"
"$FONT_SETUP" --dry-run >/tmp/setup-contract.stdout
font_output="$(< /tmp/setup-contract.stdout)"
for family in MonaspaceNerdFont FiraCodeNerdFont FiraMonoNerdFont; do
    [[ "$font_output" == *"$tmp_home/.local/share/fonts/$family"* ]] || \
        fail "font dry-run did not preview direct destination for $family"
done
[[ "$font_output" != *"autanasoft"* ]] || fail 'font dry-run exposed the removed autanasoft subtree'
"$SERVICES_SETUP" --dry-run >>/tmp/setup-contract.stdout
after="$(find "$tmp_home" -mindepth 1 -print | sort)"
[[ "$before" == "$after" ]] || fail "dry-run changed HOME"
[[ "$(< /tmp/setup-contract.stdout)" == *'[dry-run] would run'* ]] || fail 'dry-run preview missing'

manifest_root="$(mktemp -d)"
mkdir -p "$manifest_root/omarchy"
printf '# comment\n\npackage\talpha\npackage\tbeta\n' > "$manifest_root/omarchy/deps-manifest"
dependency_output="$(DOTFILES_ROOT="$manifest_root" "$DEP_SETUP" --omarchy --dry-run)"
[[ "$dependency_output" == *'[missing] alpha'* ]] || fail 'manifest package alpha was not parsed'
[[ "$dependency_output" == *'[missing] beta'* ]] || fail 'manifest package beta was not parsed'
[[ "$dependency_output" == *'yay -S --needed alpha beta'* ]] || fail 'manifest packages were not batched'

printf 'wrong\talpha\n' > "$manifest_root/omarchy/deps-manifest"
assert_dependency_status 1
printf 'package\talpha\textra\n' > "$manifest_root/omarchy/deps-manifest"
assert_dependency_status 1
printf 'package\talpha\npackage\talpha\n' > "$manifest_root/omarchy/deps-manifest"
assert_dependency_status 1
rm -rf "$manifest_root"

printf 'PASS: setup parser, dispatch, exclusions, dependency manifest, and dry-run contracts\n'
