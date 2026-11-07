# Setup

`./setup` is the profile dispatcher. It supports `omarchy` and `fedora-wsl2`, resolves the
repository root independently of the current directory, and validates the complete request before
invoking a profile helper. The Omarchy profile requires Omarchy 4.x.

## Quick path

Preview and apply only user dotfiles:

```bash
./setup --profile omarchy --dots-only --dry-run
./setup --profile omarchy --dots-only
```

For the full interactive flow, `--dots` applies dotfiles and asks which optional phases to run.
Empty or negative answers leave a phase disabled.

## CLI contract

| Flag                | Meaning                                                                                                                                                  |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--profile omarchy` | Select the implemented profile. Interactive runs offer `omarchy` when omitted.                                                                           |
| `--dots`            | Apply dotfiles, ask interactively about optional phases, then validate unless `--no-validate` is used.                                                   |
| `--dots-only`       | Apply only the manifest and permitted user copies. It cannot combine with optional phases and skips validation.                                          |
| `--deps`            | Validate and install the packages in `omarchy/deps-manifest` in one batch.                                                                               |
| `--fonts`           | Install verified, version-pinned user-local fonts under `$HOME/.local/share/fonts/<family>`; unowned or modified files stop installation.                |
| `--services`        | Configure keyd and prepare the WireGuard boot unit on Omarchy; `wg-quick@wg0` is enabled only when its safe config exists and is never started by setup. |
| `--containers`      | Install Docker Engine on Fedora WSL2. Unsupported by Omarchy.                                                                                            |
| `--locale`          | Install Spanish locale data and set `LANG=es_VE.UTF-8` on Fedora WSL2.                                                                                   |
| `--no-validate`     | Skip the final validation of a `--dots` run.                                                                                                             |
| `--non-interactive` | Require `--profile`, run only explicitly declared phases, and enable DNF automatic confirmation for Fedora mutations.                                    |
| `--dry-run`         | Show actions without downloads, writes, sudo, DNF, service changes, or graphical changes.                                                                |
| `--help`, `-h`      | Show usage.                                                                                                                                              |

Without `--non-interactive`, Omarchy `--dots` asks separately about `deps`, `fonts`, and `services`;
Fedora WSL2 additionally offers `containers` and `locale`. In non-interactive mode, no optional
phase is inferred. A request such as `--profile omarchy --deps --dry-run` runs only the dependency
phase; it does not apply dotfiles or validation.

For Omarchy, `--services` installs the tracked keyd configuration, enables keyd, and installs the
non-secret WireGuard systemd drop-in. The drop-in checks that NetworkManager reports full
connectivity before `wg-quick@wg0` starts and retries failures every 15 seconds. If
`/etc/wireguard/wg0.conf` is a regular, non-symlink file, setup enforces root ownership and mode
0600 and enables `wg-quick@wg0.service` for boot; it never starts or restarts the VPN during setup.
With no config, it reports the skip and leaves any existing enabled/disabled state unchanged. An
identical existing drop-in is reused; differing local content is preserved and reported as an error.
Run `--deps` first to install the declared WireGuard prerequisites: `--services` does not install
packages implicitly. Keyd reload retries up to ten times with a short delay for service startup;
persistent failure restores its prior configuration and service state where possible.

The Omarchy profile no longer installs or configures native PostgreSQL or Valkey. Manage PostgreSQL
and Redis instances separately through Omarchy Docker DB. Running `--deps` or `--services` does not
uninstall previously installed servers or migrate their data.

## Omarchy cleanup utility

`omarchy/utils/bash/cleanup` is a standalone selective cleanup utility; it is not part of `./setup`.
By default it asks for confirmation before removing its predefined Omarchy components and writes a
TSV audit log under `backup/`. `--yes` skips confirmation. `--dry-run` still asks for confirmation
unless combined with `--yes`; it writes an audit log recording simulated removals but never removes
components. `--list` only prints the categorized plan and does not write an audit log. The utility
invokes the existing Omarchy removal APIs with component names as separate arguments.

## Fedora WSL2

```bash
./setup --profile fedora-wsl2 --dots-only
./setup --profile fedora-wsl2 --deps
./setup --profile fedora-wsl2 --services
./setup --profile fedora-wsl2 --containers
./setup --profile fedora-wsl2 --locale
./setup --profile fedora-wsl2 --dots --deps --containers --services --locale
```

| Flag           | Meaning                                                                                                                                                                                                              |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--dots-only`  | Install a new LazyVim starter, apply `fedora-wsl2/dots-paths`, enable the `jdxcode/mise` COPR, install RPM-managed Mise with DNF if needed, and run `mise install`. It uses `sudo` only when Mise must be installed. |
| `--dots`       | Apply the same user configuration as `--dots-only`.                                                                                                                                                                  |
| `--deps`       | Install the groups and packages declared in `fedora-wsl2/dnf-packages`; dry-runs leave group state unqueried.                                                                                                        |
| `--services`   | Initialize, configure, enable, and validate PostgreSQL and Valkey.                                                                                                                                                   |
| `--containers` | Install Docker Engine from Docker's official Fedora repository, configure log rotation, and start the service.                                                                                                       |
| `--locale`     | Install Spanish locale data and set the system locale to `es_VE.UTF-8`.                                                                                                                                              |

Fedora's `--deps` phase also installs Google Chrome Stable from Google's official RPM when it is
absent. Its `--dots` and `--dots-only` phases install OpenCode when it is absent. Their Mise setup
requires an RPM-managed executable: a standalone `~/.local/bin/mise` does not satisfy that state.
When needed, it installs DNF COPR support, enables `jdxcode/mise`, and installs `mise` through DNF.
`--fonts` and `--no-validate` are exclusive to Omarchy and are rejected for Fedora WSL2. Fedora's
`--services` can interactively set the PostgreSQL `postgres` role password; it never prompts in
`--non-interactive` or `--dry-run` mode. Valkey accepts local socket connections through
`/run/valkey/valkey.sock` for users in the `wheel` group. The profile installs a Valkey systemd
drop-in so the service can create that group-owned socket with mode `770`.

The Fedora Mise configuration selects the latest Herdr release. Its configuration is managed at
`~/.config/herdr/config.toml` with Windows Terminal-compatible pane and tab bindings derived from
the Fedora WSL2 tmux profile.

Fedora's Bash functions provide `pi-dev` for launching Pi with `PI_CODING_AGENT_DIR` set to
`$HOME/.pi/dev` (the `~/.pi/dev` development configuration), forwarding all arguments:

```bash
pi-dev --help
```

The function does not define `pi-ext`, link authentication files, or explicitly share sessions. It
leaves a caller-provided `PI_CODING_AGENT_SESSION_DIR` override unchanged.

`--non-interactive` requires `--profile`, runs only requested phases, and supplies DNF automatic
confirmation for every Fedora package mutation. `--dry-run` invokes neither `sudo` nor DNF; it
checks RPM package state but reports declared DNF groups as unverified rather than calling them
missing.

Fedora's `--containers` phase requires Fedora 44 under WSL2 with systemd running. It stops before
mutation when conflicting Docker packages, ambiguous data directories, repository state, or
`/etc/docker/daemon.json` configuration are detected; it never removes packages or data. The phase
installs Docker's official Engine, CLI, containerd, Buildx, and Compose packages, uses the `local`
logging driver for bounded container logs, and enables `docker.service`.

The invoking user is added to the `docker` group. **This grants root-level privileges.** The script
does not run `newgrp`; start a new WSL session after installation. Its final runtime validation runs
`docker version`, `docker info`, `docker compose version`, and the `hello-world` container. Preview
the complete phase without `sudo`, downloads, writes, or service changes:

```bash
./setup --profile fedora-wsl2 --containers --non-interactive --dry-run
```

## Safety boundaries

- `setup-dots` owns only user configuration, including LazyVim, the manifest, backups, symlinks,
  Mise, and Mise-managed tools.
- `setup-deps`, `setup-fonts`, `setup-containers`, `setup-services`, `setup-locale`, and
  `setup-validate` each own one phase. Omarchy `setup-services` coordinates keyd and WireGuard.
- `--dry-run` never invokes `sudo`, DNF, package downloads, `fc-cache`, service management, or
  Hyprland commands.
- Existing Omarchy dotfile targets, including distinct or dangling destination symlinks, are moved
  to a timestamped `backup/` path before replacement. Backup name collisions receive a numeric
  suffix. Symlinks themselves are moved, without following or modifying their referents; relative
  link text is preserved but may not resolve from the backup location. Correct links remain
  unchanged, and `--dry-run` only previews backups and replacements. This policy does not change
  stale parent-link handling or obsolete monitor-link cleanup.
- Herdr's `config.toml` is managed as a symlink from `omarchy/dots-manifest`.
- Omarchy links `omarchy/home/pi/agent/settings.json` to `~/.pi/agent/settings.json` and
  `omarchy/home/pi/gentle-ai/{persona,profiles}.json` to their matching paths under
  `~/.pi/gentle-ai/`. Changes written through these links can modify the repository files, including
  active profiles and changelog state. Review them before committing. Credentials, sessions,
  history, and other Pi runtime data remain unmanaged. This does not install Pi, its packages, or
  its theme, or configure provider authentication.
- Fonts are installed under `$HOME/.local/share/fonts/<family>/` from Monaspace v1.400 and Nerd
  Fonts v3.5.1 archives. Download URLs and SHA-256 values are pinned in `setup-fonts` from official
  release metadata:
  [Monaspace v1.400](https://api.github.com/repos/githubnext/monaspace/releases/tags/v1.400) and
  [Nerd Fonts v3.5.1](https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest). Every
  archive is checked before any extraction or destination change. The installer records the exact
  SHA-256 hash and relative path of each file it installs in
  `.local/share/fonts/.dotfiles-fonts-ownership`. Subsequent runs update only files whose current
  content still matches that record; unowned collisions, symlinks, and locally modified managed
  files are preserved and cause a clear stop. The record is replaced with the current release
  inventory, but files from older releases are never pruned automatically. Existing fonts without
  safe ownership evidence are not adopted. `--dry-run` only previews pinned URLs and expected
  hashes.

## Related files

- `setup` — public dispatcher.
- `omarchy/utils/bash/setup-omarchy` — Omarchy phase orchestrator.
- `omarchy/utils/bash/setup-dots` — user dotfiles and manifest executor.
- `omarchy/deps-manifest` — the package manifest consumed by the dependency phase.
- `omarchy/utils/bash/setup-deps` — dependency manifest parser and installer.
- `omarchy/utils/bash/setup-fonts` — user-local Nerd Font installer.
- `omarchy/utils/bash/setup-services` — Omarchy service orchestrator.
- `omarchy/utils/bash/setup-services-input` — keyd configuration and service setup.
- `omarchy/utils/bash/setup-services-wireguard` — WireGuard config safety and boot enablement.
- `omarchy/etc/systemd/system/wg-quick@wg0.service.d/90-networkmanager-connectivity.conf` —
  connectivity check and retry policy.
- `omarchy/utils/bash/setup-validate` — Omarchy 4, Hyprland, and Herdr configuration validation.
- `fedora-wsl2/utils/bash/setup-fedora-wsl2` — Fedora WSL2 phase orchestrator.
- `fedora-wsl2/utils/bash/setup-dots` — Mise bootstrap, dotfiles, and tools.
- `fedora-wsl2/utils/bash/setup-deps` — DNF group and package setup.
- `fedora-wsl2/utils/bash/setup-services` — PostgreSQL and Valkey setup.
- `fedora-wsl2/utils/bash/setup-containers` — official Docker Engine setup for Fedora WSL2.
- `fedora-wsl2/utils/bash/setup-locale` — Spanish locale setup.
