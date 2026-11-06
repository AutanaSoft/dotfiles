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
assert_status 2 "$SETUP" --profile omarchy --locale --dry-run
help_output="$("$SETUP" --help)"
[[ "$help_output" == *"--locale"*"Install the Fedora WSL2 locale."* ]] || fail "shared help does not identify --locale as Fedora WSL2-only"
[[ ! -e "$ROOT_DIR/omarchy/utils/bash/setup-locale" ]] || fail "obsolete Omarchy locale helper still exists"

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

hypr_entry="$ROOT_DIR/omarchy/home/config/hypr/hyprland.lua"
hypr_entry_content="$(<"$hypr_entry")"
[[ "$hypr_entry_content" == *'require("hypr.windows")'* ]] || fail "Hyprland entry point does not explicitly load windows.lua"
[[ "$hypr_entry_content" == *'require("hypr.autostart")'*$'\n\n-- Toggle config flags dynamically.'*'require("hypr.workspaces")'*'require("hypr.windows")'* ]] || fail "Hyprland module load order changed unexpectedly"
hypr_docs="$(<"$ROOT_DIR/docs/hypr.md")"
hypr_docs_flat="$(printf '%s' "$hypr_docs" | tr '\n' ' ')"
[[ "$hypr_docs_flat" == *'busca primero en `state`, después en `config` y finalmente en las rutas de Omarchy'* ]] || fail "Hyprland docs do not record the confirmed bootstrap search order"
[[ "$hypr_docs_flat" == *'Los archivos `input` y `autostart` existen en la instalación del usuario, pero son configuraciones personales no administradas por este repositorio'* ]] || fail "Hyprland docs do not distinguish the user's unmanaged input and autostart files"
[[ "$hypr_docs_flat" == *'no constituye una garantía general de portabilidad'* ]] || fail "Hyprland docs imply an unsupported portability guarantee"
[[ "$hypr_docs_flat" == *'`hypr.windows` se carga explícitamente'* ]] || fail "Hyprland docs do not state that windows is explicitly loaded"

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
# Every managed source in the current manifest must exist in this checkout.
while IFS=$'\t' read -r action source target; do
  [[ -z "$action" || "$action" =~ ^[[:space:]]*# ]] && continue
  case "$action" in
    dir|file|copy) [[ -e "$ROOT_DIR/$source" ]] || fail "manifest source is missing: $source" ;;
    glob) compgen -G "$ROOT_DIR/$source" >/dev/null || fail "manifest glob has no sources: $source" ;;
    skip) ;;
    *) fail "unexpected manifest action in source check: $action" ;;
  esac
done < "$ROOT_DIR/omarchy/dots-manifest"

# Interactive consent must describe every service in the Omarchy phase.
prompt_output="$(script -q -c "$SETUP --profile omarchy --dots --dry-run" /dev/null <<< $'n\nn\nn\n' 2>&1)"
[[ "$prompt_output" == *"keyd"* && "$prompt_output" != *"PostgreSQL"* && "$prompt_output" != *"Valkey"* ]] || fail "Omarchy services consent prompt does not describe keyd-only setup"
[[ "$prompt_output" != *"ratbagd"* ]] || fail "Omarchy services consent prompt still names ratbagd"
[[ "$prompt_output" != *"[setup-services]"* ]] || fail "declined service consent still dispatched services"

# Service orchestrator forwards flags and dispatches only the keyd helper.
service_root="$TEST_TMP_DIR/services-root"
mkdir -p "$service_root/omarchy/utils/bash"
service_log="$TEST_TMP_DIR/services.log"
for helper in setup-services-input; do
  cat >"$service_root/omarchy/utils/bash/$helper" <<EOF
#!/usr/bin/env bash
printf '%s %s\\n' '$helper' "\$*" >>'$service_log'
EOF
  chmod +x "$service_root/omarchy/utils/bash/$helper"
done
DOTFILES_ROOT="$service_root" "$ROOT_DIR/omarchy/utils/bash/setup-services" --dry-run --non-interactive
expected_services='setup-services-input --dry-run --non-interactive'
[[ "$(<"$service_log")" == "$expected_services" ]] || fail "service helpers were not dispatched in order with flags"

# keyd readiness and rollback contracts use shims and a temporary target; no host service is touched.
input_bin="$TEST_TMP_DIR/input-bin"
input_state="$TEST_TMP_DIR/input-state"
input_target="$TEST_TMP_DIR/input-keyd.conf"
input_log="$TEST_TMP_DIR/input-commands.log"
mkdir -p "$input_bin" "$input_state"
cat >"$input_bin/sudo" <<'EOF'
#!/usr/bin/env bash
set -e
case "$1" in
  cp|install|rm|test|bash)
    command="$1"; shift
    if [[ "$command" == bash && "${INPUT_FAIL_TARGET_INSPECTION:-0}" == 1 ]]; then
      printf 'simulated privileged inspection failure\n' >&2
      exit 2
    fi
    args=()
    for arg in "$@"; do
      case "$arg" in
        /etc/keyd/default.conf*) arg="${INPUT_TARGET}${arg#/etc/keyd/default.conf}" ;;
      esac
      args+=("$arg")
    done
    exec "$command" "${args[@]}"
    ;;
  *) exec "$@" ;;
esac
EOF
cat >"$input_bin/systemctl" <<'EOF'
#!/usr/bin/env bash
set -e
state="${INPUT_STATE:?}"
log="${INPUT_LOG:?}"
printf 'systemctl %s\n' "$*" >>"$log"
command="$1"; shift
case "$command" in
  is-enabled) [[ "$1" == --quiet ]] && shift; [[ -f "$state/${1}.enabled" ]] ;;
  is-active) [[ "$1" == --quiet ]] && shift; [[ -f "$state/${1}.active" ]] ;;
  enable)
    [[ " $* " != *' ratbagd '* ]] || { printf 'Failed to enable unit: Unit ratbagd.service does not exist\n' >&2; exit 1; }
    for unit in "$@"; do touch "$state/${unit}.enabled" "$state/${unit}.active"; done
    ;;
  disable) rm -f "$state/${1}.enabled" ;;
  start) touch "$state/${1}.active" ;;
  stop) rm -f "$state/${1}.active" ;;
  *) exit 0 ;;
esac
EOF
cat >"$input_bin/keyd" <<'EOF'
#!/usr/bin/env bash
printf 'keyd %s\n' "$*" >>"${INPUT_LOG:?}"
[[ "$1" == reload ]] || exit 0
count_file="${INPUT_STATE:?}/reload-count"
count=0
[[ -f "$count_file" ]] && count="$(<"$count_file")"
count=$((count + 1))
printf '%s\n' "$count" >"$count_file"
[[ "${FAIL_KEYD_RELOAD:-0}" != 1 ]] || { printf 'simulated keyd failure\n' >&2; exit 1; }
(( count > ${KEYD_TRANSIENT_FAILURES:-0} )) || { printf 'keyd socket not ready\n' >&2; exit 1; }
EOF
chmod +x "$input_bin"/*
: >"$input_log"
set +e
PATH="$input_bin:$PATH" INPUT_STATE="$input_state" INPUT_TARGET="$input_target" INPUT_LOG="$input_log" systemctl enable --now keyd ratbagd >"$TEST_STDOUT" 2>"$TEST_STDERR"
missing_ratbagd_status=$?
set -e
[[ "$missing_ratbagd_status" -ne 0 ]] || fail "missing-ratbagd shim did not reproduce the service enablement failure"
[[ "$(<"$TEST_STDERR")" == 'Failed to enable unit: Unit ratbagd.service does not exist' ]] || fail "missing-ratbagd shim did not report the original failure"

: >"$input_log"
set +e
PATH="$input_bin:$PATH" INPUT_STATE="$input_state" INPUT_TARGET="$input_target" INPUT_LOG="$input_log" "$ROOT_DIR/omarchy/utils/bash/setup-services-input" >"$TEST_STDOUT" 2>"$TEST_STDERR"
keyd_without_ratbagd_status=$?
set -e
[[ "$keyd_without_ratbagd_status" -eq 0 ]] || fail "keyd setup failed when ratbagd is absent: $(<"$TEST_STDERR")"
[[ "$(<"$input_log")" == *'systemctl enable --now keyd'* ]] || fail "keyd was not enabled without ratbagd"
[[ "$(<"$input_log")" != *ratbagd* ]] || fail "keyd setup attempted to manage ratbagd"
[[ -s "$input_target" ]] || fail "keyd setup did not install its configuration"

rm -f "$input_state"/*.enabled "$input_state"/*.active "$input_state/reload-count"
: >"$input_log"
printf 'existing keyd config\n' >"$input_target"
set +e
PATH="$input_bin:$PATH" INPUT_STATE="$input_state" INPUT_TARGET="$input_target" INPUT_LOG="$input_log" KEYD_TRANSIENT_FAILURES=2 "$ROOT_DIR/omarchy/utils/bash/setup-services-input" >"$TEST_STDOUT" 2>"$TEST_STDERR"
keyd_delayed_status=$?
set -e
[[ "$keyd_delayed_status" -eq 0 ]] || fail "keyd setup did not recover from delayed readiness: $(<"$TEST_STDERR")"
[[ "$(<"$input_target")" == "$(<"$ROOT_DIR/omarchy/etc/keyd/default.conf")" ]] || fail "keyd setup did not install its configuration"
[[ "$(<"$input_state/reload-count")" -eq 3 ]] || fail "keyd readiness was not retried until reload succeeded"

rm -f "$input_state"/*.enabled "$input_state"/*.active "$input_state/reload-count"
: >"$input_log"
printf 'preserve this config\n' >"$input_target"
touch "$input_state/keyd.enabled" "$input_state/keyd.active"
set +e
PATH="$input_bin:$PATH" INPUT_STATE="$input_state" INPUT_TARGET="$input_target" INPUT_LOG="$input_log" FAIL_KEYD_RELOAD=1 "$ROOT_DIR/omarchy/utils/bash/setup-services-input" >"$TEST_STDOUT" 2>"$TEST_STDERR"
keyd_rollback_status=$?
set -e
[[ "$keyd_rollback_status" -ne 0 ]] || fail "genuine keyd reload failure did not fail setup"
[[ "$(<"$input_target")" == 'preserve this config' ]] || fail "keyd failure did not restore the existing configuration"
[[ -e "$input_state/keyd.enabled" && -e "$input_state/keyd.active" ]] || fail "keyd failure did not preserve prior service state"
[[ "$(<"$input_state/reload-count")" -eq 11 ]] || fail "keyd reload failure did not stop after ten attempts plus recovery reload"
[[ "$(<"$input_log")" != *ratbagd* ]] || fail "keyd rollback attempted to manage ratbagd"

input_referent="$TEST_TMP_DIR/input-keyd-referent.conf"
printf 'symlink referent must survive\n' >"$input_referent"
rm -f "$input_target"
ln -s "$input_referent" "$input_target"
: >"$input_log"
: >"$TEST_STDOUT"
set +e
PATH="$input_bin:$PATH" INPUT_STATE="$input_state" INPUT_TARGET="$input_target" INPUT_LOG="$input_log" INPUT_FAIL_TARGET_INSPECTION=1 "$ROOT_DIR/omarchy/utils/bash/setup-services-input" >"$TEST_STDOUT" 2>"$TEST_STDERR"
keyd_inspection_status=$?
set -e
[[ "$keyd_inspection_status" -ne 0 ]] || fail "keyd setup continued after privileged target inspection failed"
[[ -L "$input_target" && "$(readlink "$input_target")" == "$input_referent" ]] || fail "inspection failure replaced the existing keyd symlink"
[[ "$(<"$input_referent")" == 'symlink referent must survive' ]] || fail "inspection failure changed the symlink referent"
[[ ! -s "$input_log" ]] || fail "inspection failure changed service state"
[[ "$(<"$TEST_STDERR")" == *"existing keyd configuration"* ]] || fail "inspection failure was not reported"

printf 'PASS: Omarchy setup contracts\n'
