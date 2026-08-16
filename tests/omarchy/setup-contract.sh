#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
SETUP="$ROOT_DIR/setup"
FONT_SETUP="$ROOT_DIR/omarchy/utils/bash/setup-fonts"
SERVICES_SETUP="$ROOT_DIR/omarchy/utils/bash/setup-services"
DEP_SETUP="$ROOT_DIR/omarchy/utils/bash/setup-deps"

# shellcheck source=../lib/test-helpers.sh
source "$ROOT_DIR/tests/lib/test-helpers.sh"

assert_dependency_status() {
  local expected="$1"

  set +e
  DOTFILES_ROOT="$manifest_root" "$DEP_SETUP" --omarchy --dry-run >"$TEST_STDOUT" 2>"$TEST_STDERR"
  local actual=$?
  set -e
  [[ "$actual" -eq "$expected" ]] || fail "expected dependency status $expected, got $actual"
}

setup_test_environment
trap cleanup_test_environment EXIT

assert_status 2 "$SETUP" --profile omarchy --dots-only --services --dry-run
assert_status 2 "$SETUP" --profile omarchy --dots --dots-only --dry-run
assert_status 2 "$SETUP" --profile omarchy --no-validate --dry-run

omarchy_3_bin="$TEST_TMP_DIR/omarchy-3-bin"
mkdir -p "$omarchy_3_bin"
printf '#!/usr/bin/env bash\nprintf "3.8.4\\n"\n' >"$omarchy_3_bin/omarchy"
chmod +x "$omarchy_3_bin/omarchy"
set +e
PATH="$omarchy_3_bin:$PATH" "$SETUP" --profile omarchy --dots-only --non-interactive --dry-run >"$TEST_STDOUT" 2>"$TEST_STDERR"
omarchy_3_status=$?
set -e
[[ "$omarchy_3_status" -eq 1 ]] || fail "Omarchy 3.x was accepted for dotfiles"
[[ "$(<"$TEST_STDERR")" == *"Omarchy 4.x is required"* ]] || fail "Omarchy 3.x rejection was not explained"

deps_output="$("$SETUP" --profile omarchy --deps --non-interactive --dry-run)"
[[ "$deps_output" == *"[setup-deps]"* ]] || fail "--deps did not dispatch to setup-deps"
[[ "$deps_output" != *"[setup-fonts]"* ]] || fail "--deps unexpectedly dispatched fonts"
[[ "$deps_output" != *"[setup-services]"* ]] || fail "--deps unexpectedly dispatched services"

dots_output="$("$SETUP" --profile omarchy --dots-only --non-interactive --dry-run)"
[[ "$dots_output" == *"[setup-dots]"* ]] || fail "--dots-only did not dispatch to setup-dots"
for excluded in setup-deps setup-fonts setup-services setup-locale setup-validate; do
  [[ "$dots_output" != *"[$excluded]"* ]] || fail "--dots-only dispatched excluded phase $excluded"
done
[[ "$dots_output" == *"hyprland.lua"* ]] || fail "--dots-only did not preview the Omarchy 4 Hyprland entry point"
[[ "$dots_output" != *"waybar"* ]] || fail "--dots-only previewed retired Waybar configuration"

validate_output="$("$SETUP" --profile omarchy --dots --non-interactive --dry-run)"
[[ "$validate_output" == *"would verify: Omarchy 4."* ]] || fail "validation did not check Omarchy 4"
[[ "$validate_output" == *"would run: herdr config check"* ]] || fail "validation did not check Herdr configuration"
[[ "$validate_output" != *"tokyo-night-autana"* ]] || fail "validation retained the custom theme"

before="$(find "$HOME" -mindepth 1 -print | sort)"
"$FONT_SETUP" --dry-run >"$TEST_STDOUT"
font_output="$(<"$TEST_STDOUT")"
for family in MonaspaceNerdFont FiraCodeNerdFont FiraMonoNerdFont; do
  [[ "$font_output" == *"$HOME/.local/share/fonts/$family"* ]] || fail "font dry-run did not preview direct destination for $family"
done
[[ "$font_output" != *"autanasoft"* ]] || fail "font dry-run exposed the removed autanasoft subtree"
"$SERVICES_SETUP" --dry-run >>"$TEST_STDOUT"
after="$(find "$HOME" -mindepth 1 -print | sort)"
[[ "$before" == "$after" ]] || fail "dry-run changed HOME"
[[ "$(<"$TEST_STDOUT")" == *"[dry-run] would run"* ]] || fail "dry-run preview missing"

manifest_root="$TEST_TMP_DIR/manifest"
mkdir -p "$manifest_root/omarchy"
printf '# comment\n\npackage\talpha\npackage\tbeta\n' >"$manifest_root/omarchy/deps-manifest"
dependency_output="$(DOTFILES_ROOT="$manifest_root" "$DEP_SETUP" --omarchy --dry-run)"
[[ "$dependency_output" == *"[missing] alpha"* ]] || fail "manifest package alpha was not parsed"
[[ "$dependency_output" == *"[missing] beta"* ]] || fail "manifest package beta was not parsed"
[[ "$dependency_output" == *"yay -S --needed alpha beta"* ]] || fail "manifest packages were not batched"

printf 'wrong\talpha\n' >"$manifest_root/omarchy/deps-manifest"
assert_dependency_status 1
printf 'package\talpha\textra\n' >"$manifest_root/omarchy/deps-manifest"
assert_dependency_status 1
printf 'package\talpha\npackage\talpha\n' >"$manifest_root/omarchy/deps-manifest"
assert_dependency_status 1

[[ ! -e "$ROOT_DIR/omarchy/home/config/waybar/config.jsonc" ]] || fail "Omarchy profile still includes Waybar configuration"
[[ ! -e "$ROOT_DIR/omarchy/home/config/hypr/hypridle.conf" ]] || fail "Omarchy profile still includes hypridle configuration"
[[ ! -e "$ROOT_DIR/omarchy/home/config/omarchy/themes/tokyo-night-autana" ]] || fail "Omarchy profile still includes a custom theme"
[[ "$(<"$ROOT_DIR/omarchy/dots-manifest")" == *"hypr/*.lua"* ]] || fail "Omarchy manifest does not link Lua modules"
[[ "$(<"$ROOT_DIR/omarchy/dots-manifest")" == *$'file\tomarchy/home/config/herdr/config.toml\t.config/herdr/config.toml'* ]] || fail "Omarchy manifest does not link Herdr configuration"
[[ "$(<"$ROOT_DIR/omarchy/dots-manifest")" != *"waybar"* ]] || fail "Omarchy manifest still links Waybar"
[[ "$(<"$ROOT_DIR/omarchy/home/bashrc")" == *"/usr/share/omarchy/default/bash/env-bootstrap"* ]] || fail "Omarchy Bash does not bootstrap Omarchy 4"
[[ "$(<"$ROOT_DIR/omarchy/home/bashrc")" != *".local/share/omarchy"* ]] || fail "Omarchy Bash still references Omarchy 3"

herdr_config="$ROOT_DIR/omarchy/home/config/herdr/config.toml"
[[ -f "$herdr_config" ]] || fail "Herdr configuration is missing"
[[ "$(<"$ROOT_DIR/omarchy/home/config/bash/functions")" == *"hdl() {"* ]] || fail "Herdr hdl function is missing"

printf 'PASS: Omarchy setup contracts\n'
