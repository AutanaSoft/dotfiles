#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
SETUP="$ROOT_DIR/setup"
FEDORA_DEPS_SETUP="$ROOT_DIR/fedora-wsl2/utils/bash/setup-deps"
FEDORA_TIMEZONE_SETUP="$ROOT_DIR/fedora-wsl2/utils/bash/setup-timezone"
FEDORA_POSTGRES_SETUP="$ROOT_DIR/fedora-wsl2/utils/bash/setup-postgres"
FEDORA_CONTAINERS_SETUP="$ROOT_DIR/fedora-wsl2/utils/bash/setup-containers"
FEDORA_COMMON_SETUP="$ROOT_DIR/fedora-wsl2/utils/bash/setup-common"

# shellcheck source=../lib/test-helpers.sh
source "$ROOT_DIR/tests/lib/test-helpers.sh"

setup_test_environment
trap cleanup_test_environment EXIT

fake_bin="$TEST_TMP_DIR/bin"
mkdir -p "$fake_bin"
printf '#!/usr/bin/env bash\nexit 1\n' >"$fake_bin/rpm"
printf '#!/usr/bin/env bash\nexit 1\n' >"$fake_bin/dnf"
printf '#!/usr/bin/env bash\nprintf "wheel\\n"\n' >"$fake_bin/id"
printf '#!/usr/bin/env bash\nif [[ $1 == show ]]; then printf "%%s\\n" "${TEST_CURRENT_TZ:-America/Caracas}"; else printf "%%s\\n" "$*" >>"${TIMEZONE_LOG:-/dev/null}"; fi\n' >"$fake_bin/timedatectl"
chmod +x "$fake_bin"/*
export PATH="$fake_bin:$PATH"

[[ -r "$FEDORA_COMMON_SETUP" ]] || fail "Fedora shared setup helpers are missing"

assert_status 2 "$SETUP" --profile fedora-wsl2 --fonts --dry-run
assert_status 2 "$SETUP" --profile fedora-wsl2 --dots-only --deps --dry-run
assert_status 2 "$SETUP" --profile fedora-wsl2 --dots-only --services --dry-run
assert_status 2 "$SETUP" --profile fedora-wsl2 --services --dry-run
assert_status 2 "$SETUP" --profile fedora-wsl2 --dots-only --containers --dry-run
assert_status 2 "$SETUP" --profile omarchy --containers --dry-run
assert_status 2 "$SETUP" --profile omarchy --postgres --dry-run
assert_status 2 "$SETUP" --profile fedora-wsl2 --dots-only --postgres --dry-run

fedora_deps_output="$("$SETUP" --profile fedora-wsl2 --deps --non-interactive --dry-run)"
[[ "$fedora_deps_output" == *"[setup-deps]"* ]] || fail "Fedora --deps did not dispatch to setup-deps"
[[ "$fedora_deps_output" != *"[setup-dots]"* ]] || fail "Fedora --deps unexpectedly dispatched dots"
[[ "$fedora_deps_output" != *"[setup-timezone]"* ]] || fail "Fedora --deps unexpectedly dispatched timezone"
[[ "$fedora_deps_output" != *"google-chrome-stable"* ]] || fail "Fedora --deps unexpectedly checked Google Chrome"
[[ "$fedora_deps_output" == *"pulseaudio-utils"* ]] || fail "Fedora --deps did not include Herdr audio playback support"

fedora_dots_output="$("$SETUP" --profile fedora-wsl2 --dots-only --non-interactive --dry-run)"
[[ "$fedora_dots_output" == *"[setup-dots]"* ]] || fail "Fedora --dots-only did not dispatch to setup-dots"
[[ -f "$ROOT_DIR/fedora-wsl2/home/config/herdr/config.toml" ]] || fail "Fedora Herdr config source is missing"
[[ "$(<"$ROOT_DIR/fedora-wsl2/home/config/mise/config.toml")" == *'herdr = "latest"'* ]] || fail "Fedora Mise configuration does not select the latest Herdr"
[[ "$(<"$ROOT_DIR/fedora-wsl2/dots-paths")" == *'config/herdr/config.toml | .config/herdr/config.toml'* ]] || fail "Fedora dots manifest does not map the Herdr config"
[[ "$fedora_dots_output" == *"Creating symlink: $HOME/.config/herdr/config.toml -> $ROOT_DIR/fedora-wsl2/home/config/herdr/config.toml"* ]] || fail "Fedora --dots-only did not preview the Herdr config link"
[[ "$fedora_dots_output" != *"[setup-deps]"* ]] || fail "Fedora --dots-only unexpectedly dispatched deps"
[[ "$fedora_dots_output" != *"would install configuration"* ]] || fail "Fedora --dots-only previewed system configuration"
[[ "$fedora_dots_output" == *"Installing LazyVim starter"* ]] || fail "Fedora --dots-only did not preview LazyVim installation"
[[ "$fedora_dots_output" != *"Copying Neovim bootstrap"* ]] || fail "Fedora --dots-only retained the Neovim bootstrap copy"
[[ "$fedora_dots_output" != *"[setup-services]"* ]] || fail "Fedora --dots-only dispatched services"
[[ "$fedora_dots_output" == *"Installing DNF COPR support if needed"* ]] || fail "Fedora --dots-only did not preview the Mise COPR prerequisite"
[[ "$fedora_dots_output" == *"Enabling jdxcode/mise COPR"* ]] || fail "Fedora --dots-only did not preview the Mise COPR"
[[ "$fedora_dots_output" == *"Installing Mise with DNF"* ]] || fail "Fedora --dots-only did not preview the DNF Mise installation"
[[ "$fedora_dots_output" != *"Installing Mise at"* ]] || fail "Fedora --dots-only retained the standalone Mise installer"
[[ "$fedora_dots_output" != *"OpenCode"* ]] || fail "Fedora --dots-only unexpectedly installs OpenCode outside Mise"

mkdir -p "$HOME/.local/bin"
printf '#!/usr/bin/env bash\nexit 0\n' >"$HOME/.local/bin/mise"
chmod +x "$HOME/.local/bin/mise"
standalone_mise_output="$(PATH="$HOME/.local/bin:$PATH" "$SETUP" --profile fedora-wsl2 --dots-only --non-interactive --dry-run)"
[[ "$standalone_mise_output" == *"Installing Mise with DNF"* ]] || fail "Fedora standalone Mise bypassed the RPM installation"

mkdir -p "$HOME/.config/nvim"
fedora_existing_nvim_output="$("$SETUP" --profile fedora-wsl2 --dots-only --non-interactive --dry-run)"
[[ "$fedora_existing_nvim_output" == *"Keeping existing Neovim configuration"* ]] || fail "Fedora --dots-only did not keep existing Neovim configuration"
[[ "$fedora_existing_nvim_output" == *"Installing tools declared by Mise"* ]] || fail "Fedora --dots-only did not continue after existing Neovim configuration"
rm -rf "$HOME/.config/nvim"

containers_root="$TEST_TMP_DIR/containers"
mkdir -p "$containers_root/etc" "$containers_root/bin"
printf 'ID=fedora\nVERSION_ID=44\n' >"$containers_root/etc/os-release"
printf '6.15.0-microsoft-standard-WSL2\n' >"$containers_root/kernel-release"
for command in rpm dnf sudo getent; do
  printf '#!/usr/bin/env bash\nexit 1\n' >"$containers_root/bin/$command"
done
printf '#!/usr/bin/env bash\nif [[ $* == *"-p 1 -o comm="* ]]; then printf "systemd\\n"; fi\n' >"$containers_root/bin/ps"
printf '#!/usr/bin/env bash\n[[ $1 == is-system-running ]] && printf "running\\n"\n' >"$containers_root/bin/systemctl"
printf '#!/usr/bin/env bash\nif [[ $1 == -un ]]; then printf "developer\\n"; elif [[ $1 == -nG ]]; then printf "wheel\\n"; else exit 0; fi\n' >"$containers_root/bin/id"
chmod +x "$containers_root/bin"/*
fedora_containers_output="$(
  PATH="$containers_root/bin:$PATH" \
    DOTFILES_OS_RELEASE_FILE="$containers_root/etc/os-release" \
    DOTFILES_KERNEL_RELEASE_FILE="$containers_root/kernel-release" \
    DOTFILES_DOCKER_REPO_FILE="$containers_root/docker-ce.repo" \
    DOTFILES_DOCKER_CONFIG_FILE="$containers_root/daemon.json" \
    DOTFILES_DOCKER_DATA_DIR="$containers_root/docker-data" \
    DOTFILES_CONTAINERD_DATA_DIR="$containers_root/containerd-data" \
    "$SETUP" --profile fedora-wsl2 --containers --non-interactive --dry-run
)"
[[ "$fedora_containers_output" == *"[setup-containers] Adding Docker's official Fedora repository"* ]] || fail "Fedora --containers did not preview the official Docker repository"
[[ "$fedora_containers_output" == *"docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"* ]] || fail "Fedora --containers did not preview all official Docker packages"
[[ "$fedora_containers_output" == *"log-driver"* || "$fedora_containers_output" == *"log rotation configuration"* ]] || fail "Fedora --containers did not preview log rotation configuration"
[[ "$fedora_containers_output" == *"root-level privileges"* ]] || fail "Fedora --containers did not warn about docker group privileges"
[[ "$fedora_containers_output" == *"Adding developer to the docker group"* ]] || fail "Fedora --containers selected the invoking user"
[[ "$fedora_containers_output" == *"would enable and start docker.service"* ]] || fail "Fedora --containers did not preview Docker service activation"
[[ "$fedora_containers_output" != *"hello-world"* ]] || fail "Fedora --containers dry-run attempted hello-world"

printf '[docker-ce-stable]\nbaseurl=https://download.docker.com/linux/fedora\n' >"$containers_root/docker-ce.repo"
containers_dnf_log="$containers_root/dnf.log"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >>"$DOTFILES_DNF_LOG"\nexit 1\n' >"$containers_root/bin/dnf"
chmod +x "$containers_root/bin/dnf"
DOTFILES_DNF_LOG="$containers_dnf_log" PATH="$containers_root/bin:$PATH" \
  DOTFILES_OS_RELEASE_FILE="$containers_root/etc/os-release" \
  DOTFILES_KERNEL_RELEASE_FILE="$containers_root/kernel-release" \
  DOTFILES_DOCKER_REPO_FILE="$containers_root/docker-ce.repo" \
  DOTFILES_DOCKER_CONFIG_FILE="$containers_root/daemon.json" \
  DOTFILES_DOCKER_DATA_DIR="$containers_root/docker-data" \
  DOTFILES_CONTAINERD_DATA_DIR="$containers_root/containerd-data" \
  "$FEDORA_CONTAINERS_SETUP" --dry-run >/dev/null
[[ ! -s "$containers_dnf_log" ]] || fail "Fedora containers dry-run invoked DNF"
rm "$containers_root/docker-ce.repo"

printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >>"$DOTFILES_SUDO_LOG"\n' >"$containers_root/bin/sudo"
printf '#!/usr/bin/env bash\nexit 0\n' >"$containers_root/bin/docker"
chmod +x "$containers_root/bin/sudo" "$containers_root/bin/docker"
containers_sudo_log="$containers_root/sudo.log"
DOTFILES_SUDO_LOG="$containers_sudo_log" PATH="$containers_root/bin:$PATH" \
  DOTFILES_OS_RELEASE_FILE="$containers_root/etc/os-release" \
  DOTFILES_KERNEL_RELEASE_FILE="$containers_root/kernel-release" \
  DOTFILES_DOCKER_REPO_FILE="$containers_root/docker-ce.repo" \
  DOTFILES_DOCKER_CONFIG_FILE="$containers_root/daemon.json" \
  DOTFILES_DOCKER_DATA_DIR="$containers_root/docker-data" \
  DOTFILES_CONTAINERD_DATA_DIR="$containers_root/containerd-data" \
  "$FEDORA_CONTAINERS_SETUP" --non-interactive >/dev/null
[[ "$(<"$containers_sudo_log")" == *"dnf --assumeyes install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"* ]] || fail "Fedora non-interactive containers install did not enable DNF automatic confirmation"

: >"$containers_sudo_log"
DOTFILES_SUDO_LOG="$containers_sudo_log" PATH="$containers_root/bin:$PATH" \
  DOTFILES_OS_RELEASE_FILE="$containers_root/etc/os-release" \
  DOTFILES_KERNEL_RELEASE_FILE="$containers_root/kernel-release" \
  DOTFILES_DOCKER_REPO_FILE="$containers_root/docker-ce.repo" \
  DOTFILES_DOCKER_CONFIG_FILE="$containers_root/daemon.json" \
  DOTFILES_DOCKER_DATA_DIR="$containers_root/docker-data" \
  DOTFILES_CONTAINERD_DATA_DIR="$containers_root/containerd-data" \
  "$FEDORA_CONTAINERS_SETUP" >/dev/null
[[ "$(<"$containers_sudo_log")" == *"dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"* ]] || fail "Fedora interactive containers install did not preserve DNF confirmation"
[[ "$(<"$containers_sudo_log")" != *"dnf --assumeyes install"* ]] || fail "Fedora interactive containers install forced DNF automatic confirmation"

for fedora_version in 44 46; do
  printf 'ID=fedora\nVERSION_ID=%s\n' "$fedora_version" >"$containers_root/etc/os-release-$fedora_version"
  assert_status 0 env PATH="$containers_root/bin:$PATH" \
    DOTFILES_OS_RELEASE_FILE="$containers_root/etc/os-release-$fedora_version" \
    DOTFILES_KERNEL_RELEASE_FILE="$containers_root/kernel-release" \
    DOTFILES_DOCKER_REPO_FILE="$containers_root/docker-ce.repo" \
    DOTFILES_DOCKER_CONFIG_FILE="$containers_root/daemon.json" \
    DOTFILES_DOCKER_DATA_DIR="$containers_root/docker-data" \
    DOTFILES_CONTAINERD_DATA_DIR="$containers_root/containerd-data" \
    "$FEDORA_CONTAINERS_SETUP" --dry-run
done
for fedora_version in 43 rawhide; do
  printf 'ID=fedora\nVERSION_ID=%s\n' "$fedora_version" >"$containers_root/etc/os-release-$fedora_version"
  assert_status 1 env PATH="$containers_root/bin:$PATH" \
    DOTFILES_OS_RELEASE_FILE="$containers_root/etc/os-release-$fedora_version" \
    DOTFILES_KERNEL_RELEASE_FILE="$containers_root/kernel-release" \
    "$FEDORA_CONTAINERS_SETUP" --dry-run
  grep -q "Fedora 44 or newer is required" "$TEST_STDERR" || fail "Fedora $fedora_version did not report the minimum Fedora version"
done

printf 'ID=ubuntu\nVERSION_ID=24.04\n' >"$containers_root/etc/not-fedora"
assert_status 1 env PATH="$containers_root/bin:$PATH" \
  DOTFILES_OS_RELEASE_FILE="$containers_root/etc/not-fedora" \
  DOTFILES_KERNEL_RELEASE_FILE="$containers_root/kernel-release" \
  "$FEDORA_CONTAINERS_SETUP" --dry-run

printf '#!/usr/bin/env bash\n[[ $1 == -q && $2 == docker ]] && exit 0\nexit 1\n' >"$containers_root/bin/rpm"
chmod +x "$containers_root/bin/rpm"
assert_status 1 env PATH="$containers_root/bin:$PATH" \
  DOTFILES_OS_RELEASE_FILE="$containers_root/etc/os-release" \
  DOTFILES_KERNEL_RELEASE_FILE="$containers_root/kernel-release" \
  DOTFILES_DOCKER_REPO_FILE="$containers_root/docker-ce.repo" \
  DOTFILES_DOCKER_CONFIG_FILE="$containers_root/daemon.json" \
  DOTFILES_DOCKER_DATA_DIR="$containers_root/docker-data" \
  DOTFILES_CONTAINERD_DATA_DIR="$containers_root/containerd-data" \
  "$FEDORA_CONTAINERS_SETUP" --dry-run

fedora_timezone_output="$("$SETUP" --profile fedora-wsl2 --timezone --non-interactive --dry-run)"
[[ "$fedora_timezone_output" == *"[setup-timezone] [dry-run] would set time zone: America/Puerto_Rico"* ]] || fail "Fedora --timezone did not preview the Puerto Rico time zone"
[[ "$fedora_timezone_output" != *"[setup-deps]"* ]] || fail "Fedora --timezone unexpectedly dispatched dependencies"

fedora_postgres_output="$("$SETUP" --profile fedora-wsl2 --postgres --non-interactive --dry-run)"
[[ "$fedora_postgres_output" == *"[setup-postgres] [dry-run] would ensure container postgres (postgres:19) published on 127.0.0.1:5432"* ]] || fail "Fedora --postgres did not preview the loopback-only container"
[[ "$fedora_postgres_output" == *"--restart unless-stopped"* ]] || fail "Fedora --postgres did not preview the restart policy"
[[ "$fedora_postgres_output" != *"[setup-deps]"* ]] || fail "Fedora --postgres unexpectedly dispatched dependencies"
fedora_postgres_order_output="$("$SETUP" --profile fedora-wsl2 --deps --postgres --timezone --non-interactive --dry-run)"
[[ "$fedora_postgres_order_output" == *"[setup-deps]"*"[setup-postgres]"*"[setup-timezone]"* ]] || fail "Fedora --postgres did not run between dependencies and timezone"

fedora_full_output="$("$SETUP" --profile fedora-wsl2 --dots --deps --timezone --non-interactive --dry-run)"
[[ "$fedora_full_output" != *"unknown option: --final-validation"* ]] || fail "Fedora --dots forwarded Omarchy validation"
[[ "$fedora_full_output" == *"[setup-deps]"*"[setup-dots]"*"[setup-timezone]"* ]] || fail "Fedora full flow did not dispatch phases in order"

fedora_deps_config_output="$("$SETUP" --profile fedora-wsl2 --deps --non-interactive --dry-run)"
[[ "$fedora_deps_config_output" != *"would install configuration"* ]] || fail "Fedora --deps previewed custom configuration"

manifest_root="$TEST_TMP_DIR/manifest"
mkdir -p "$manifest_root/fedora-wsl2"
printf '# comment\n\n@alpha\nalpha\nbeta\n' >"$manifest_root/fedora-wsl2/dnf-packages"
fake_bin="$manifest_root/bin"
mkdir -p "$fake_bin"
printf '#!/usr/bin/env bash\nif [[ $1 == group && $2 == info ]]; then exit 1; fi\nexit 0\n' >"$fake_bin/dnf"
chmod +x "$fake_bin/dnf"
fedora_dependency_output="$(PATH="$fake_bin:$PATH" DOTFILES_ROOT="$manifest_root" "$FEDORA_DEPS_SETUP" --dry-run)"
[[ "$fedora_dependency_output" == *"[unverified] @alpha (dry-run does not query DNF group state)"* ]] || fail "Fedora dry-run did not preserve unknown group state"
[[ "$fedora_dependency_output" == *"[missing] alpha"* ]] || fail "Fedora manifest package alpha was not parsed"
[[ "$fedora_dependency_output" == *"[missing] beta"* ]] || fail "Fedora manifest package beta was not parsed"
[[ "$fedora_dependency_output" == *"Would install declared groups without querying installed state: alpha"* ]] || fail "Fedora dry-run groups were not reported accurately"
[[ "$fedora_dependency_output" != *"[missing] @alpha"* ]] || fail "Fedora dry-run claimed an unqueried group was missing"

dnf_log="$manifest_root/dnf.log"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >>"$DNF_LOG"\nexit 1\n' >"$fake_bin/dnf"
chmod +x "$fake_bin/dnf"
DNF_LOG="$dnf_log" PATH="$fake_bin:$PATH" DOTFILES_ROOT="$manifest_root" "$FEDORA_DEPS_SETUP" --dry-run >/dev/null
[[ ! -s "$dnf_log" ]] || fail "Fedora dependency dry-run invoked DNF"

printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >>"$DNF_LOG"\nexit 0\n' >"$fake_bin/dnf"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >>"$SUDO_LOG"\nif [[ $1 == -n ]]; then shift; fi\nif [[ ${1:-} == dnf ]]; then shift; dnf "$@"; fi\n' >"$fake_bin/sudo"
chmod +x "$fake_bin/dnf" "$fake_bin/sudo"
sudo_log="$manifest_root/sudo.log"
printf 'alpha\n' >"$manifest_root/fedora-wsl2/dnf-packages"
DNF_LOG="$dnf_log" SUDO_LOG="$sudo_log" PATH="$fake_bin:$PATH" DOTFILES_ROOT="$manifest_root" "$FEDORA_DEPS_SETUP" --non-interactive >/dev/null
[[ "$(<"$dnf_log")" == *"--assumeyes install alpha"* ]] || fail "Fedora non-interactive dependencies did not enable DNF automatic confirmation"
[[ "$(<"$dnf_log")" != *"google-chrome-stable"* ]] || fail "Fedora non-interactive dependencies unexpectedly installed Chrome"

timezone_root="$TEST_TMP_DIR/timezone"
mkdir -p "$timezone_root/bin"
printf '#!/usr/bin/env bash\nif [[ $1 == -n ]]; then shift; fi\n"$@"\n' >"$timezone_root/bin/sudo"
printf '#!/usr/bin/env bash\nif [[ $1 == show ]]; then printf "%%s\\n" "${TEST_CURRENT_TZ:-America/Caracas}"; else printf "%%s\\n" "$*" >>"${TIMEZONE_LOG:-/dev/null}"; fi\n' >"$timezone_root/bin/timedatectl"
chmod +x "$timezone_root/bin"/*
timezone_log="$timezone_root/timezone.log"
: >"$timezone_log"
TIMEZONE_LOG="$timezone_log" PATH="$timezone_root/bin:$PATH" "$FEDORA_TIMEZONE_SETUP" --non-interactive >/dev/null
[[ "$(<"$timezone_log")" == *"set-timezone America/Puerto_Rico"* ]] || fail "Fedora timezone setup did not set America/Puerto_Rico"
: >"$timezone_log"
TEST_CURRENT_TZ=America/Puerto_Rico TIMEZONE_LOG="$timezone_log" PATH="$timezone_root/bin:$PATH" "$FEDORA_TIMEZONE_SETUP" --non-interactive >/dev/null
[[ ! -s "$timezone_log" ]] || fail "Fedora timezone setup changed an already configured time zone"
printf '@alpha\n@alpha\n' >"$manifest_root/fedora-wsl2/dnf-packages"
set +e
PATH="$fake_bin:$PATH" DOTFILES_ROOT="$manifest_root" "$FEDORA_DEPS_SETUP" --dry-run >"$TEST_STDOUT" 2>"$TEST_STDERR"
fedora_dependency_status=$?
set -e
[[ "$fedora_dependency_status" -eq 1 ]] || fail "Fedora dependency manifest accepted a duplicate group"

assert_status 1 "$FEDORA_TIMEZONE_SETUP" --unknown
assert_status 1 "$FEDORA_POSTGRES_SETUP" --unknown

postgres_root="$TEST_TMP_DIR/postgres"
mkdir -p "$postgres_root/bin"
printf '#!/usr/bin/env bash\nif [[ $1 == -n ]]; then shift; fi\n"$@"\n' >"$postgres_root/bin/sudo"
printf '#!/usr/bin/env bash\nif [[ ${POSTGRES_TEST_PORT_BUSY:-0} == 1 ]]; then printf "LISTEN 0 4096 127.0.0.1:5432 0.0.0.0:*\\n"; fi\n' >"$postgres_root/bin/ss"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >>"$DOCKER_LOG"\ncase "$1 $2" in\n  "container inspect") [[ ${DOCKER_CONTAINER_EXISTS:-0} == 1 ]] ;;\n  "volume inspect") [[ ${DOCKER_VOLUME_EXISTS:-0} == 1 ]] ;;\n  "inspect -f") printf "true\\n" ;;\n  "run --rm") printf "1\\n" ;;\n  *) exit 0 ;;\nesac\n' >"$postgres_root/bin/docker"
chmod +x "$postgres_root/bin"/*
postgres_log="$postgres_root/docker.log"
: >"$postgres_log"
DOCKER_LOG="$postgres_log" PATH="$postgres_root/bin:$PATH" "$FEDORA_POSTGRES_SETUP" --non-interactive >/dev/null
postgres_calls="$(<"$postgres_log")"
[[ "$postgres_calls" == *"volume create pgdata"* ]] || fail "Fedora postgres did not create the data volume"
[[ "$postgres_calls" == *"pull postgres:19"* ]] || fail "Fedora postgres did not pull the pinned image"
[[ "$postgres_calls" == *"run -d --name postgres --restart unless-stopped"* ]] || fail "Fedora postgres did not create a restarting container"
[[ "$postgres_calls" == *"-p 127.0.0.1:5432:5432"* ]] || fail "Fedora postgres did not publish only on loopback"
[[ "$postgres_calls" == *"-v pgdata:/var/lib/postgresql"* ]] || fail "Fedora postgres did not mount the PostgreSQL 18+ data path"
[[ "$postgres_calls" == *"run --rm --network host"* ]] || fail "Fedora postgres did not validate the password over TCP"
: >"$postgres_log"
DOCKER_CONTAINER_EXISTS=1 DOCKER_LOG="$postgres_log" PATH="$postgres_root/bin:$PATH" "$FEDORA_POSTGRES_SETUP" --non-interactive >/dev/null
postgres_calls="$(<"$postgres_log")"
[[ "$postgres_calls" != *"run -d"* && "$postgres_calls" != *"volume create"* && "$postgres_calls" != *"pull "* ]] || fail "Fedora postgres recreated an existing container"
assert_status 1 env POSTGRES_TEST_PORT_BUSY=1 DOCKER_LOG="$postgres_log" PATH="$postgres_root/bin:$PATH" "$FEDORA_POSTGRES_SETUP" --non-interactive
grep -q "port 5432 is already in use" "$TEST_STDERR" || fail "Fedora postgres did not report the busy port"

[[ "$(<"$ROOT_DIR/fedora-wsl2/home/config/mise/config.toml")" == *'python = "latest"'* ]] || fail "Fedora Mise configuration does not select the latest Python"
[[ "$(<"$ROOT_DIR/fedora-wsl2/home/config/mise/config.toml")" == *'markdownlint-cli2 = "latest"'* ]] || fail "Fedora Mise configuration does not select the latest markdownlint-cli2"
[[ "$(<"$ROOT_DIR/fedora-wsl2/home/config/mise/config.toml")" == *'lazydocker = "latest"'* ]] || fail "Fedora Mise configuration does not install Lazydocker"

[[ "$(<"$ROOT_DIR/fedora-wsl2/home/bashrc")" == *"/etc/bashrc"* ]] || fail "Fedora bashrc does not source /etc/bashrc"
bash_init="$(<"$ROOT_DIR/fedora-wsl2/home/config/bash/init")"
[[ "$bash_init" == *'command -v mise >/dev/null 2>&1'* ]] || fail "Fedora Bash does not resolve Mise from PATH"
[[ "$bash_init" == *'eval "$(mise activate bash)"'* ]] || fail "Fedora Bash does not activate the PATH Mise executable"
[[ "$bash_init" != *'.local/bin/mise'* ]] || fail "Fedora Bash hardcodes the standalone Mise executable"

bash_home="$TEST_TMP_DIR/bash-home"
mkdir -p "$bash_home/.bashrc.d" "$bash_home/.config"
ln -s "$ROOT_DIR/fedora-wsl2/home/config/bash" "$bash_home/.config/bash"
printf 'export DOTFILES_BASHRC_D_TEST=loaded\n' >"$bash_home/.bashrc.d/test"
bash_output="$(HOME="$bash_home" PATH=/usr/bin:/bin bash --noprofile --norc -c '
  source "$HOME/.config/bash/rc"
  source "$HOME/.config/bash/envs"
  [[ ${DOTFILES_BASHRC_D_TEST:-} == loaded ]]
  for path in "$HOME/.local/bin" "$HOME/bin"; do
    case ":$PATH:" in *":$path:"*) ;; *) exit 1 ;; esac
    path_without_current=":$PATH:"
    path_without_current="${path_without_current/":$path:"/:}"
    [[ "$path_without_current" != *":$path:"* ]] || exit 1
  done
  printf "%s" "$PATH"
')" || fail "Fedora Bash configuration did not load correctly"
[[ "$bash_output" == "$bash_home/.local/bin:$bash_home/bin:"* ]] || fail "Fedora Bash PATH order is incorrect"

printf 'PASS: Fedora WSL2 setup contracts\n'
