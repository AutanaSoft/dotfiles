#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
SETUP="$ROOT_DIR/setup"
FEDORA_DEPS_SETUP="$ROOT_DIR/fedora-wsl2/utils/bash/setup-deps"
FEDORA_SERVICES_SETUP="$ROOT_DIR/fedora-wsl2/utils/bash/setup-services"
FEDORA_LOCALE_SETUP="$ROOT_DIR/fedora-wsl2/utils/bash/setup-locale"

# shellcheck source=../lib/test-helpers.sh
source "$ROOT_DIR/tests/lib/test-helpers.sh"

setup_test_environment
trap cleanup_test_environment EXIT

fake_bin="$TEST_TMP_DIR/bin"
mkdir -p "$fake_bin"
printf '#!/usr/bin/env bash\nexit 1\n' >"$fake_bin/rpm"
printf '#!/usr/bin/env bash\nexit 1\n' >"$fake_bin/dnf"
for command in postgresql-setup pg_isready psql valkey-cli; do
  printf '#!/usr/bin/env bash\nexit 0\n' >"$fake_bin/$command"
done
printf '#!/usr/bin/env bash\nprintf "wheel\\n"\n' >"$fake_bin/id"
chmod +x "$fake_bin"/*
export PATH="$fake_bin:$PATH"

assert_status 2 "$SETUP" --profile fedora-wsl2 --fonts --dry-run
assert_status 2 "$SETUP" --profile fedora-wsl2 --dots-only --deps --dry-run
assert_status 2 "$SETUP" --profile fedora-wsl2 --dots-only --services --dry-run

fedora_deps_output="$("$SETUP" --profile fedora-wsl2 --deps --non-interactive --dry-run)"
[[ "$fedora_deps_output" == *"[setup-deps]"* ]] || fail "Fedora --deps did not dispatch to setup-deps"
[[ "$fedora_deps_output" != *"[setup-dots]"* ]] || fail "Fedora --deps unexpectedly dispatched dots"
[[ "$fedora_deps_output" != *"[setup-services]"* ]] || fail "Fedora --deps unexpectedly dispatched services"
[[ "$fedora_deps_output" != *"[setup-locale]"* ]] || fail "Fedora --deps unexpectedly dispatched locale"
[[ "$fedora_deps_output" != *"would initialize PostgreSQL"* ]] || fail "Fedora --deps previewed PostgreSQL initialization"
[[ "$fedora_deps_output" != *"would enable postgresql"* ]] || fail "Fedora --deps previewed service management"
[[ "$fedora_deps_output" == *"google-chrome-stable"* ]] || fail "Fedora --deps did not check Google Chrome"

fedora_dots_output="$("$SETUP" --profile fedora-wsl2 --dots-only --non-interactive --dry-run)"
[[ "$fedora_dots_output" == *"[setup-dots]"* ]] || fail "Fedora --dots-only did not dispatch to setup-dots"
[[ "$fedora_dots_output" != *"[setup-deps]"* ]] || fail "Fedora --dots-only unexpectedly dispatched deps"
[[ "$fedora_dots_output" != *"would install configuration"* ]] || fail "Fedora --dots-only previewed system configuration"
[[ "$fedora_dots_output" == *"Installing LazyVim starter"* ]] || fail "Fedora --dots-only did not preview LazyVim installation"
[[ "$fedora_dots_output" != *"Copying Neovim bootstrap"* ]] || fail "Fedora --dots-only retained the Neovim bootstrap copy"
[[ "$fedora_dots_output" != *"[setup-services]"* ]] || fail "Fedora --dots-only dispatched services"
[[ "$fedora_dots_output" == *"Installing OpenCode at"* ]] || fail "Fedora --dots-only did not preview OpenCode installation"

mkdir -p "$HOME/.config/nvim"
fedora_existing_nvim_output="$("$SETUP" --profile fedora-wsl2 --dots-only --non-interactive --dry-run)"
[[ "$fedora_existing_nvim_output" == *"Keeping existing Neovim configuration"* ]] || fail "Fedora --dots-only did not keep existing Neovim configuration"
[[ "$fedora_existing_nvim_output" == *"Installing tools declared by Mise"* ]] || fail "Fedora --dots-only did not continue after existing Neovim configuration"
rm -rf "$HOME/.config/nvim"

fedora_services_output="$("$SETUP" --profile fedora-wsl2 --services --non-interactive --dry-run)"
[[ "$fedora_services_output" == *"[setup-services] [dry-run] would initialize PostgreSQL if the cluster is absent"* ]] || fail "Fedora --services did not preview PostgreSQL initialization"
[[ "$fedora_services_output" == *"[setup-services] [dry-run] would install configuration: /var/lib/pgsql/data/pg_hba.conf"* ]] || fail "Fedora --services did not preview PostgreSQL configuration"
[[ "$fedora_services_output" == *"[setup-services] [dry-run] would install configuration: /etc/systemd/system/valkey.service.d/socket-group.conf"* ]] || fail "Fedora --services did not preview the Valkey drop-in"
[[ "$fedora_services_output" == *"[setup-services] [dry-run] would run: systemctl daemon-reload"* ]] || fail "Fedora --services did not preview systemd reload"

fedora_locale_output="$("$SETUP" --profile fedora-wsl2 --locale --non-interactive --dry-run)"
[[ "$fedora_locale_output" == *"glibc-langpack-es"* ]] || fail "Fedora --locale did not check Spanish locale data"
[[ "$fedora_locale_output" == *"[setup-locale] [dry-run] would install locale configuration: /etc/locale.conf"* ]] || fail "Fedora --locale did not preview locale configuration"
[[ "$fedora_locale_output" != *"[setup-deps]"* ]] || fail "Fedora --locale unexpectedly dispatched dependencies"

fedora_full_output="$("$SETUP" --profile fedora-wsl2 --dots --deps --services --locale --non-interactive --dry-run)"
[[ "$fedora_full_output" != *"unknown option: --final-validation"* ]] || fail "Fedora --dots forwarded Omarchy validation"
[[ "$fedora_full_output" == *"[setup-deps]"*"[setup-dots]"*"[setup-services]"*"[setup-locale]"* ]] || fail "Fedora full flow did not dispatch phases in order"

fedora_deps_config_output="$("$SETUP" --profile fedora-wsl2 --deps --non-interactive --dry-run)"
[[ "$fedora_deps_config_output" != *"would install configuration"* ]] || fail "Fedora --deps previewed custom configuration"
[[ "$fedora_deps_config_output" != *"would initialize PostgreSQL"* ]] || fail "Fedora --deps previewed PostgreSQL initialization"

manifest_root="$TEST_TMP_DIR/manifest"
mkdir -p "$manifest_root/fedora-wsl2"
printf '# comment\n\n@alpha\nalpha\nbeta\n' >"$manifest_root/fedora-wsl2/dnf-packages"
fake_bin="$manifest_root/bin"
mkdir -p "$fake_bin"
printf '#!/usr/bin/env bash\nif [[ $1 == group && $2 == info ]]; then exit 1; fi\nexit 0\n' >"$fake_bin/dnf"
chmod +x "$fake_bin/dnf"
fedora_dependency_output="$(PATH="$fake_bin:$PATH" DOTFILES_ROOT="$manifest_root" "$FEDORA_DEPS_SETUP" --dry-run)"
[[ "$fedora_dependency_output" == *"[missing] @alpha"* ]] || fail "Fedora manifest group alpha was not parsed"
[[ "$fedora_dependency_output" == *"[missing] alpha"* ]] || fail "Fedora manifest package alpha was not parsed"
[[ "$fedora_dependency_output" == *"[missing] beta"* ]] || fail "Fedora manifest package beta was not parsed"
[[ "$fedora_dependency_output" == *"Installing missing groups: alpha"* ]] || fail "Fedora groups were not batched"
printf '@alpha\n@alpha\n' >"$manifest_root/fedora-wsl2/dnf-packages"
set +e
PATH="$fake_bin:$PATH" DOTFILES_ROOT="$manifest_root" "$FEDORA_DEPS_SETUP" --dry-run >"$TEST_STDOUT" 2>"$TEST_STDERR"
fedora_dependency_status=$?
set -e
[[ "$fedora_dependency_status" -eq 1 ]] || fail "Fedora dependency manifest accepted a duplicate group"

assert_status 1 "$FEDORA_SERVICES_SETUP" --unknown
assert_status 1 "$FEDORA_LOCALE_SETUP" --unknown

[[ "$(<"$ROOT_DIR/fedora-wsl2/home/config/mise/config.toml")" == *'python = "3.14.7"'* ]] || fail "Fedora Mise configuration does not pin Python 3.14.7"
[[ "$(<"$ROOT_DIR/fedora-wsl2/home/config/mise/config.toml")" == *'"npm:markdownlint-cli2" = "latest"'* ]] || fail "Fedora Mise configuration does not install markdownlint-cli2"
[[ "$(<"$FEDORA_SERVICES_SETUP")" == *'log "PostgreSQL is ready"'* ]] || fail "Fedora services do not confirm PostgreSQL readiness"
[[ "$(<"$FEDORA_SERVICES_SETUP")" == *'log "Valkey socket is ready"'* ]] || fail "Fedora services do not confirm Valkey readiness"

tmux_functions="$(<"$ROOT_DIR/fedora-wsl2/home/config/bash/functions")"
[[ "$tmux_functions" == *$'tmux() {\n  if (($# == 0)); then\n    command tmux new-session -A -s AutanaSoft'* ]] || fail "tmux does not create or attach AutanaSoft without arguments"
[[ "$tmux_functions" == *'command tmux "$@"'* ]] || fail "tmux does not preserve subcommands"
[[ "$tmux_functions" == *'session_name="AutanaSoft"'* ]] || fail "tdl does not name the Tmux session AutanaSoft"
[[ "$tmux_functions" == *'tmux has-session -t "$session_name"'* ]] || fail "tdl does not reuse the AutanaSoft session"
[[ "$tmux_functions" == *'tmux new-session -d -P -F '\''#{session_name}'\'' -s "$session_name"'* ]] || fail "tdl does not create a named Tmux session"
[[ "$tmux_functions" == *'run this command inside the %s tmux session'* ]] || fail "tdl does not protect other Tmux sessions"

[[ "$(<"$ROOT_DIR/fedora-wsl2/home/bashrc")" == *"/etc/bashrc"* ]] || fail "Fedora bashrc does not source /etc/bashrc"

bash_home="$TEST_TMP_DIR/bash-home"
mkdir -p "$bash_home/.bashrc.d" "$bash_home/.config"
ln -s "$ROOT_DIR/fedora-wsl2/home/config/bash" "$bash_home/.config/bash"
printf 'export DOTFILES_BASHRC_D_TEST=loaded\n' >"$bash_home/.bashrc.d/test"
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

printf 'PASS: Fedora WSL2 setup contracts\n'
