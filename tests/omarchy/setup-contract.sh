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

# Service orchestrator forwards flags and keeps the documented helper order.
service_root="$TEST_TMP_DIR/services-root"
mkdir -p "$service_root/omarchy/utils/bash"
service_log="$TEST_TMP_DIR/services.log"
for helper in setup-services-input setup-services-postgresql setup-services-valkey; do
  cat >"$service_root/omarchy/utils/bash/$helper" <<EOF
#!/usr/bin/env bash
printf '%s %s\\n' '$helper' "\$*" >>'$service_log'
EOF
  chmod +x "$service_root/omarchy/utils/bash/$helper"
done
DOTFILES_ROOT="$service_root" "$ROOT_DIR/omarchy/utils/bash/setup-services" --dry-run --non-interactive
expected_services=$'setup-services-input --dry-run --non-interactive\nsetup-services-postgresql --dry-run --non-interactive\nsetup-services-valkey --dry-run --non-interactive'
[[ "$(<"$service_log")" == "$expected_services" ]] || fail "service helpers were not dispatched in order with flags"

postgres_hba="$ROOT_DIR/omarchy/etc/postgresql/pg_hba.conf"
[[ -f "$postgres_hba" ]] || fail "PostgreSQL authentication configuration is missing"
[[ "$(<"$postgres_hba")" == *$'local   all             all                                     peer'* ]] || fail "PostgreSQL local authentication is not peer"
[[ "$(<"$postgres_hba")" == *'127.0.0.1/32            scram-sha-256'* ]] || fail "PostgreSQL IPv4 authentication is not SCRAM"
[[ "$(<"$postgres_hba")" == *'::1/128                 scram-sha-256'* ]] || fail "PostgreSQL IPv6 authentication is not SCRAM"
[[ "$(<"$postgres_hba")" != *'0.0.0.0/0'* ]] || fail "PostgreSQL authentication permits remote access"
postgres_helper="$ROOT_DIR/omarchy/utils/bash/setup-services-postgresql"
[[ "$(<"$postgres_helper")" == *'Set a password for the PostgreSQL postgres role?'* ]] || fail "PostgreSQL interactive password flow is missing"
[[ "$(<"$postgres_helper")" == *'(( !NON_INTERACTIVE )) && [[ -t 0 ]]'* ]] || fail "PostgreSQL password flow is not limited to interactive runs"

valkey_config="$ROOT_DIR/omarchy/etc/valkey/valkey.conf"
[[ "$(<"$valkey_config")" == *'bind 127.0.0.1 -::1'* ]] || fail "Valkey is not bound to loopback"
[[ "$(<"$valkey_config")" == *$'port 6379'* ]] || fail "Valkey TCP is disabled"
[[ "$(<"$valkey_config")" == *$'unixsocket /run/valkey/valkey.sock'* ]] || fail "Valkey socket is missing"
[[ "$(<"$valkey_config")" == *$'unixsocketgroup valkey'* ]] || fail "Valkey socket group is wrong"
[[ "$(<"$valkey_config")" == *$'unixsocketperm 770'* ]] || fail "Valkey socket permissions are wrong"
[[ ! -e "$ROOT_DIR/omarchy/etc/systemd/system/valkey.service.d/socket-group.conf" ]] || fail "Valkey still has a SupplementaryGroups drop-in"

# PostgreSQL and Valkey helpers use temporary roots and command shims; no host service is touched.
service_bin="$TEST_TMP_DIR/service-bin"
service_state="$TEST_TMP_DIR/service-state"
service_log="$TEST_TMP_DIR/service-commands.log"
export DOTFILES_BACKUP_DIR="$TEST_TMP_DIR/service-backups"
mkdir -p "$service_bin" "$service_state" "$DOTFILES_BACKUP_DIR"
cat >"$service_bin/sudo" <<'EOF'
#!/usr/bin/env bash
set -e
[[ "$1" == -u ]] && shift 2
if [[ "$1" == install ]]; then
  command=(install)
  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|-g) shift 2 ;;
      *) command+=("$1"); shift ;;
    esac
  done
  exec "${command[@]}"
fi
exec "$@"
EOF
cat >"$service_bin/systemctl" <<'EOF'
#!/usr/bin/env bash
set -e
state="${SERVICE_STATE:?}"
log="${SERVICE_LOG:?}"
printf 'systemctl %s\n' "$*" >>"$log"
command="$1"; shift
case "$command" in
  is-enabled) [[ "$1" == --quiet ]] && shift; [[ -f "$state/${1}.enabled" ]] ;;
  is-active) [[ "$1" == --quiet ]] && shift; [[ -f "$state/${1}.active" ]] ;;
  enable) touch "$state/${1}.enabled" ;;
  disable) rm -f "$state/${1}.enabled" ;;
  start) touch "$state/${1}.active" ;;
  stop) rm -f "$state/${1}.active" ;;
  reload|restart) [[ "${FAIL_SYSTEMCTL:-0}" != 1 ]] || exit 1; touch "$state/${1}.active" ;;
  *) exit 0 ;;
esac
EOF
cat >"$service_bin/initdb" <<'EOF'
#!/usr/bin/env bash
set -e
printf 'initdb %s\n' "$*" >>"${SERVICE_LOG:?}"
while [[ $# -gt 0 ]]; do
  [[ "$1" == -D ]] && { mkdir -p "$2/base"; printf '18\n' >"$2/PG_VERSION"; exit 0; }
  shift
done
exit 1
EOF
cat >"$service_bin/postgres" <<'EOF'
#!/usr/bin/env bash
set -e
if [[ "$*" == *' -C listen_addresses'* ]]; then
  config="${POSTGRES_DATA_DIR:?}/postgresql.conf"
  if [[ -f "$config" ]] && grep -q "listen_addresses = '\*'" "$config"; then
    printf '*\n'
  else
    printf 'localhost\n'
  fi
  exit 0
fi
exit 1
EOF
cat >"$service_bin/pg_isready" <<'EOF'
#!/usr/bin/env bash
[[ "${FAIL_PG_READY:-0}" != 1 ]]
EOF
cat >"$service_bin/psql" <<'EOF'
#!/usr/bin/env bash
[[ "${FAIL_PSQL:-0}" != 1 ]] || exit 1
[[ "$*" == *'SHOW listen_addresses;'* ]] && printf 'localhost\n' || printf '1\n'
EOF
cat >"$service_bin/getent" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$service_bin/id" <<'EOF'
#!/usr/bin/env bash
[[ "$1" == -nG ]] && printf '%s\n' "${CURRENT_GROUPS:-users}"
EOF
cat >"$service_bin/usermod" <<'EOF'
#!/usr/bin/env bash
printf 'usermod %s\n' "$*" >>"${SERVICE_LOG:?}"
EOF
cat >"$service_bin/valkey-cli" <<'EOF'
#!/usr/bin/env bash
[[ "${FAIL_VALKEY_SOCKET:-0}" == 1 && "${1:-}" == -s ]] && exit 1
printf 'PONG\n'
EOF
cat >"$service_bin/ss" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${SS_OUTPUT:-LISTEN 0 511 127.0.0.1:6379 0.0.0.0:*}"
EOF
chmod +x "$service_bin"/*

postgres_data="$TEST_TMP_DIR/postgres-data"
set +e
PATH="$service_bin:$PATH" SERVICE_STATE="$service_state" SERVICE_LOG="$service_log" POSTGRES_DATA_DIR="$postgres_data" "$ROOT_DIR/omarchy/utils/bash/setup-services-postgresql" >"$TEST_STDOUT" 2>"$TEST_STDERR"
postgres_status=$?
set -e
[[ "$postgres_status" -eq 0 ]] || fail "PostgreSQL helper did not initialize an absent cluster: $(<"$TEST_STDERR")"
[[ -f "$postgres_data/PG_VERSION" && -d "$postgres_data/base" ]] || fail "PostgreSQL initialization did not create a cluster"
[[ "$(<"$service_log")" == *'--auth-local=peer'*'--auth-host=scram-sha-256'* ]] || fail "initdb did not receive peer and SCRAM authentication flags"

ambiguous_data="$TEST_TMP_DIR/postgres-ambiguous"
mkdir -p "$ambiguous_data"; printf bad >"$ambiguous_data/unrelated"
: >"$service_log"
set +e
PATH="$service_bin:$PATH" SERVICE_STATE="$service_state" SERVICE_LOG="$service_log" POSTGRES_DATA_DIR="$ambiguous_data" "$ROOT_DIR/omarchy/utils/bash/setup-services-postgresql" >"$TEST_STDOUT" 2>"$TEST_STDERR"
ambiguous_status=$?
set -e
[[ "$ambiguous_status" -eq 1 ]] || fail "PostgreSQL accepted an ambiguous data directory"
[[ ! -s "$service_log" ]] || fail "PostgreSQL mutated an ambiguous data directory"

external_data="$TEST_TMP_DIR/postgres-external"
mkdir -p "$external_data/base"; printf '18\n' >"$external_data/PG_VERSION"; printf "listen_addresses = '*'\n" >"$external_data/postgresql.conf"
: >"$service_log"
set +e
PATH="$service_bin:$PATH" SERVICE_STATE="$service_state" SERVICE_LOG="$service_log" POSTGRES_DATA_DIR="$external_data" "$ROOT_DIR/omarchy/utils/bash/setup-services-postgresql" >"$TEST_STDOUT" 2>"$TEST_STDERR"
external_status=$?
set -e
[[ "$external_status" -eq 1 ]] || fail "PostgreSQL accepted external listen_addresses"
[[ ! -s "$service_log" ]] || fail "PostgreSQL changed an externally exposed cluster"

rollback_data="$TEST_TMP_DIR/postgres-rollback"
mkdir -p "$rollback_data/base"; printf '18\n' >"$rollback_data/PG_VERSION"; printf original >"$rollback_data/pg_hba.conf"
: >"$service_log"; rm -f "$service_state"/*
set +e
PATH="$service_bin:$PATH" SERVICE_STATE="$service_state" SERVICE_LOG="$service_log" POSTGRES_DATA_DIR="$rollback_data" FAIL_PG_READY=1 "$ROOT_DIR/omarchy/utils/bash/setup-services-postgresql" >"$TEST_STDOUT" 2>"$TEST_STDERR"
rollback_status=$?
set -e
[[ "$rollback_status" -eq 1 ]] || fail "PostgreSQL readiness failure did not fail"
[[ "$(<"$rollback_data/pg_hba.conf")" == original ]] || fail "PostgreSQL failure did not restore pg_hba.conf"
[[ ! -e "$service_state/postgresql.service.enabled" && ! -e "$service_state/postgresql.service.active" ]] || fail "PostgreSQL failure did not restore unit state: $(<"$service_log")"

valkey_target="$TEST_TMP_DIR/valkey.conf"; printf original >"$valkey_target"
: >"$service_log"; rm -f "$service_state"/*
set +e
PATH="$service_bin:$PATH" SERVICE_STATE="$service_state" SERVICE_LOG="$service_log" VALKEY_CONFIG="$valkey_target" CURRENT_GROUPS=users SS_OUTPUT='LISTEN 0 511 0.0.0.0:6379 0.0.0.0:*' "$ROOT_DIR/omarchy/utils/bash/setup-services-valkey" --non-interactive >"$TEST_STDOUT" 2>"$TEST_STDERR"
valkey_status=$?
set -e
[[ "$valkey_status" -eq 1 ]] || fail "Valkey accepted an externally bound listener"
[[ "$(<"$valkey_target")" == original ]] || fail "Valkey failure did not restore its configuration"
[[ ! -e "$service_state/valkey.service.enabled" && ! -e "$service_state/valkey.service.active" ]] || fail "Valkey failure did not restore unit state"
[[ "$(<"$service_log")" != *usermod* ]] || fail "Valkey non-interactive setup changed group membership"
[[ "$(<"$TEST_STDOUT")" == *'Socket validation skipped'* ]] || fail "Valkey did not skip socket validation for current session"

missing_valkey_target="$TEST_TMP_DIR/missing-valkey.conf"
: >"$service_log"; rm -f "$service_state"/*
set +e
PATH="$service_bin:$PATH" SERVICE_STATE="$service_state" SERVICE_LOG="$service_log" VALKEY_CONFIG="$missing_valkey_target" CURRENT_GROUPS=users SS_OUTPUT='LISTEN 0 511 0.0.0.0:6379 0.0.0.0:*' "$ROOT_DIR/omarchy/utils/bash/setup-services-valkey" --non-interactive >"$TEST_STDOUT" 2>"$TEST_STDERR"
missing_valkey_status=$?
set -e
[[ "$missing_valkey_status" -eq 1 ]] || fail "Valkey external listener failure did not fail for a missing config"
[[ ! -e "$missing_valkey_target" ]] || fail "Valkey failure did not remove a newly installed configuration"
[[ ! -e "$service_state/valkey.service.enabled" && ! -e "$service_state/valkey.service.active" ]] || fail "Valkey missing-config failure did not restore unit state"

socket_valkey_target="$TEST_TMP_DIR/socket-valkey.conf"; printf original >"$socket_valkey_target"
: >"$service_log"; rm -f "$service_state"/*
set +e
PATH="$service_bin:$PATH" SERVICE_STATE="$service_state" SERVICE_LOG="$service_log" VALKEY_CONFIG="$socket_valkey_target" CURRENT_GROUPS='users valkey' FAIL_VALKEY_SOCKET=1 "$ROOT_DIR/omarchy/utils/bash/setup-services-valkey" --non-interactive >"$TEST_STDOUT" 2>"$TEST_STDERR"
socket_valkey_status=$?
set -e
[[ "$socket_valkey_status" -eq 1 ]] || fail "Valkey socket failure did not fail"
[[ "$(<"$socket_valkey_target")" == original ]] || fail "Valkey socket failure did not restore configuration"
[[ ! -e "$service_state/valkey.service.enabled" && ! -e "$service_state/valkey.service.active" ]] || fail "Valkey socket failure did not restore unit state"

# A dry run must not call privileged or service commands.
: >"$service_log"
PATH="$service_bin:$PATH" SERVICE_STATE="$service_state" SERVICE_LOG="$service_log" "$ROOT_DIR/omarchy/utils/bash/setup-services-postgresql" --dry-run >"$TEST_STDOUT"
PATH="$service_bin:$PATH" SERVICE_STATE="$service_state" SERVICE_LOG="$service_log" "$ROOT_DIR/omarchy/utils/bash/setup-services-valkey" --dry-run >>"$TEST_STDOUT"
[[ ! -s "$service_log" ]] || fail "service dry-run invoked a privileged or service command"

printf 'PASS: Omarchy setup contracts\n'
