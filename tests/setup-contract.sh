#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP="$ROOT_DIR/setup"
FONT_SETUP="$ROOT_DIR/omarchy/utils/bash/setup-fonts"
SERVICES_SETUP="$ROOT_DIR/omarchy/utils/bash/setup-services"
DEP_SETUP="$ROOT_DIR/omarchy/utils/bash/setup-deps"
FEDORA_DEPS_SETUP="$ROOT_DIR/fedora-wsl2/utils/bash/setup-deps"
FEDORA_SERVICES_SETUP="$ROOT_DIR/fedora-wsl2/utils/bash/setup-services"

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
assert_status 2 "$SETUP" --profile fedora-wsl2 --fonts --dry-run
assert_status 2 "$SETUP" --profile fedora-wsl2 --dots-only --deps --dry-run
assert_status 2 "$SETUP" --profile fedora-wsl2 --dots-only --services --dry-run

deps_output="$($SETUP --profile omarchy --deps --non-interactive --dry-run)"
[[ "$deps_output" == *"[setup-deps]"* ]] || fail "--deps did not dispatch to setup-deps"
[[ "$deps_output" != *"[setup-fonts]"* ]] || fail "--deps unexpectedly dispatched fonts"
[[ "$deps_output" != *"[setup-services]"* ]] || fail "--deps unexpectedly dispatched services"

dots_output="$($SETUP --profile omarchy --dots-only --non-interactive --dry-run)"
[[ "$dots_output" == *"[setup-dots]"* ]] || fail "--dots-only did not dispatch to setup-dots"
for excluded in setup-deps setup-fonts setup-services setup-locale setup-validate; do
    [[ "$dots_output" != *"[$excluded]"* ]] || fail "--dots-only dispatched excluded phase $excluded"
done

fedora_deps_output="$($SETUP --profile fedora-wsl2 --deps --non-interactive --dry-run)"
[[ "$fedora_deps_output" == *"[setup-deps]"* ]] || fail "Fedora --deps did not dispatch to setup-deps"
[[ "$fedora_deps_output" != *"[setup-dots]"* ]] || fail "Fedora --deps unexpectedly dispatched dots"
[[ "$fedora_deps_output" != *"[setup-services]"* ]] || fail "Fedora --deps unexpectedly dispatched services"
[[ "$fedora_deps_output" != *"would initialize PostgreSQL"* ]] || fail "Fedora --deps previewed PostgreSQL initialization"
[[ "$fedora_deps_output" != *"would enable postgresql"* ]] || fail "Fedora --deps previewed service management"

fedora_dots_output="$($SETUP --profile fedora-wsl2 --dots-only --non-interactive --dry-run)"
[[ "$fedora_dots_output" == *"[setup-dots]"* ]] || fail "Fedora --dots-only did not dispatch to setup-dots"
[[ "$fedora_dots_output" != *"[setup-deps]"* ]] || fail "Fedora --dots-only unexpectedly dispatched deps"
[[ "$fedora_dots_output" != *"would install configuration"* ]] || fail "Fedora --dots-only previewed system configuration"
[[ "$fedora_dots_output" == *"Installing LazyVim starter"* ]] || fail "Fedora --dots-only did not preview LazyVim installation"
[[ "$fedora_dots_output" != *"Copying Neovim bootstrap"* ]] || fail "Fedora --dots-only retained the Neovim bootstrap copy"
[[ "$fedora_dots_output" != *"[setup-services]"* ]] || fail "Fedora --dots-only dispatched services"

mkdir -p "$tmp_home/.config/nvim"
fedora_existing_nvim_output="$($SETUP --profile fedora-wsl2 --dots-only --non-interactive --dry-run)"
[[ "$fedora_existing_nvim_output" == *"Keeping existing Neovim configuration"* ]] || fail "Fedora --dots-only did not keep existing Neovim configuration"
[[ "$fedora_existing_nvim_output" == *"Installing tools declared by Mise"* ]] || fail "Fedora --dots-only did not continue after existing Neovim configuration"
rm -rf "$tmp_home/.config/nvim"

fedora_services_output="$($SETUP --profile fedora-wsl2 --services --non-interactive --dry-run)"
[[ "$fedora_services_output" == *"[setup-services] [dry-run] would initialize PostgreSQL if the cluster is absent"* ]] || fail "Fedora --services did not preview PostgreSQL initialization"
[[ "$fedora_services_output" == *"[setup-services] [dry-run] would install configuration: /var/lib/pgsql/data/pg_hba.conf"* ]] || fail "Fedora --services did not preview PostgreSQL configuration"
[[ "$fedora_services_output" == *"[setup-services] [dry-run] would install configuration: /etc/systemd/system/valkey.service.d/socket-group.conf"* ]] || fail "Fedora --services did not preview the Valkey drop-in"
[[ "$fedora_services_output" == *"[setup-services] [dry-run] would run: systemctl daemon-reload"* ]] || fail "Fedora --services did not preview systemd reload"

fedora_full_output="$($SETUP --profile fedora-wsl2 --dots --deps --services --non-interactive --dry-run)"
[[ "$fedora_full_output" != *"unknown option: --final-validation"* ]] || fail "Fedora --dots forwarded Omarchy validation"
[[ "$fedora_full_output" == *"[setup-deps]"*"[setup-dots]"*"[setup-services]"* ]] || fail "Fedora full flow did not dispatch phases in order"

fedora_deps_config_output="$($SETUP --profile fedora-wsl2 --deps --non-interactive --dry-run)"
[[ "$fedora_deps_config_output" != *"would install configuration"* ]] || fail "Fedora --deps previewed custom configuration"
[[ "$fedora_deps_config_output" != *"would initialize PostgreSQL"* ]] || fail "Fedora --deps previewed PostgreSQL initialization"

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

manifest_root="$(mktemp -d)"
mkdir -p "$manifest_root/fedora-wsl2"
printf '# comment\n\n@alpha\nalpha\nbeta\n' > "$manifest_root/fedora-wsl2/dnf-packages"
fake_bin="$manifest_root/bin"
mkdir -p "$fake_bin"
printf '#!/usr/bin/env bash\nif [[ $1 == group && $2 == info ]]; then exit 1; fi\nexit 0\n' > "$fake_bin/dnf"
chmod +x "$fake_bin/dnf"
fedora_dependency_output="$(PATH="$fake_bin:$PATH" DOTFILES_ROOT="$manifest_root" "$FEDORA_DEPS_SETUP" --dry-run)"
[[ "$fedora_dependency_output" == *"[missing] @alpha"* ]] || fail "Fedora manifest group alpha was not parsed"
[[ "$fedora_dependency_output" == *"[missing] alpha"* ]] || fail "Fedora manifest package alpha was not parsed"
[[ "$fedora_dependency_output" == *"[missing] beta"* ]] || fail "Fedora manifest package beta was not parsed"
[[ "$fedora_dependency_output" == *"Installing missing groups: alpha"* ]] || fail "Fedora groups were not batched"
printf '@alpha\n@alpha\n' > "$manifest_root/fedora-wsl2/dnf-packages"
set +e
PATH="$fake_bin:$PATH" DOTFILES_ROOT="$manifest_root" "$FEDORA_DEPS_SETUP" --dry-run >/tmp/setup-contract.stdout 2>/tmp/setup-contract.stderr
fedora_dependency_status=$?
set -e
[[ "$fedora_dependency_status" -eq 1 ]] || fail "Fedora dependency manifest accepted a duplicate group"
rm -rf "$manifest_root"

assert_status 1 "$FEDORA_SERVICES_SETUP" --unknown

[[ "$(< "$ROOT_DIR/fedora-wsl2/home/config/mise/config.toml")" == *'python = "3.14.7"'* ]] || fail "Fedora Mise configuration does not pin Python 3.14.7"
[[ "$(< "$ROOT_DIR/fedora-wsl2/home/config/mise/config.toml")" == *'"npm:markdownlint-cli2" = "latest"'* ]] || fail "Fedora Mise configuration does not install markdownlint-cli2"
[[ "$(< "$FEDORA_SERVICES_SETUP")" == *'log "PostgreSQL is ready"'* ]] || fail "Fedora services do not confirm PostgreSQL readiness"
[[ "$(< "$FEDORA_SERVICES_SETUP")" == *'log "Valkey socket is ready"'* ]] || fail "Fedora services do not confirm Valkey readiness"

tmux_functions="$(< "$ROOT_DIR/fedora-wsl2/home/config/bash/functions")"
[[ "$tmux_functions" == *$'tmux() {\n  if (($# == 0)); then\n    command tmux new-session -A -s AutanaSoft'* ]] || fail "tmux does not create or attach AutanaSoft without arguments"
[[ "$tmux_functions" == *'command tmux "$@"'* ]] || fail "tmux does not preserve subcommands"
[[ "$tmux_functions" == *'session_name="AutanaSoft"'* ]] || fail "tdl does not name the Tmux session AutanaSoft"
[[ "$tmux_functions" == *'tmux has-session -t "$session_name"'* ]] || fail "tdl does not reuse the AutanaSoft session"
[[ "$tmux_functions" == *'tmux new-session -d -P -F '\''#{session_name}'\'' -s "$session_name"'* ]] || fail "tdl does not create a named Tmux session"
[[ "$tmux_functions" == *'run this command inside the %s tmux session'* ]] || fail "tdl does not protect other Tmux sessions"

[[ "$(< "$ROOT_DIR/fedora-wsl2/home/bashrc")" == *"/etc/bashrc"* ]] || fail "Fedora bashrc does not source /etc/bashrc"

bash_home="$(mktemp -d)"
mkdir -p "${bash_home}/.bashrc.d" "${bash_home}/.config"
ln -s "$ROOT_DIR/fedora-wsl2/home/config/bash" "${bash_home}/.config/bash"
printf 'export DOTFILES_BASHRC_D_TEST=loaded\n' > "${bash_home}/.bashrc.d/test"
bash_output="$(HOME="$bash_home" PATH=/usr/bin:/bin bash --noprofile --norc -c '
  source "$HOME/.config/bash/rc"
  source "$HOME/.config/bash/envs"
  [[ ${DOTFILES_BASHRC_D_TEST:-} == loaded ]]
  for path in "$HOME/.opencode/bin" "$HOME/.local/bin" "$HOME/bin"; do
    case ":$PATH:" in *":$path:"*) ;; *) exit 1 ;; esac
    path_without_current="${PATH//"$path:"/}"
    [[ ":$path_without_current:" != *":$path:"* ]] || exit 1
  done
  printf "%s" "$PATH"
')" || fail "Fedora Bash configuration did not load correctly"
[[ "$bash_output" == "$bash_home/.opencode/bin:$bash_home/bin:$bash_home/.local/bin:/usr/bin:/bin" ]] || fail "Fedora Bash PATH order is incorrect"
rm -rf "$bash_home"

printf 'PASS: setup parser, profile dispatch, manifest validation, and dry-run contracts\n'
