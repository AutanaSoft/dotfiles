# dotfiles

This repository provides profiles for Omarchy and Fedora WSL2. Managed files are linked into `$HOME`
and `~/.config/`; generated backups are stored under `backup/` and are ignored by Git.

## Quick path

On an existing Omarchy-family installation with a running Hyprland session:

```bash
git clone git@github.com:AutanaSoft/dotfiles.git dotfiles
cd dotfiles
./setup --profile omarchy --dots-only --dry-run
./setup --profile omarchy --dots-only
```

Use [`docs/setup.md`](docs/setup.md) for available flags and
[`docs/post-setup.md`](docs/post-setup.md) for manual host setup.

For Fedora WSL2:

```bash
./setup --profile fedora-wsl2 --dots-only
./setup --profile fedora-wsl2 --deps
./setup --profile fedora-wsl2 --services
./setup --profile fedora-wsl2 --locale
```

## Tests

Run all isolated profile contracts with:

```bash
./tests/run.sh
```

Run only one profile when changing a profile-specific setup helper:

```bash
./tests/run.sh omarchy
./tests/run.sh fedora-wsl2
```

## Current limits

The `./setup` entrypoint is a dispatcher, not a distribution-neutral installer. The implemented
`omarchy` profile currently:

- selects the `omarchy/` profile;
- requires an existing Omarchy 4.x installation and a Hyprland session;
- uses the Arch package toolchain (`yay` and `pacman`) for dependencies;
- reads dependency names from `omarchy/deps-manifest`;
- requires the `omarchy` command and `hyprctl` from a running Hyprland session;
- validates the installed Herdr configuration during final graphical validation;
- applies user dotfiles by default when `--dots` is selected; and
- can explicitly run dependencies, fonts, services, locale, and final graphical validation as
  separate phases.

It does not install Omarchy. Ubuntu is not supported. `--dots-only` is the non-graphical user
configuration path. `--dry-run` previews actions without mutating the host.

The `fedora-wsl2` profile supports `--dots`, `--dots-only`, `--deps`, `--services`, and `--locale`.
Its dotfiles phase installs a new LazyVim starter instance, applies `dots-paths`, installs Mise and
OpenCode in the user home, and installs the tools declared in the linked Mise configuration. Its
dependency phase installs the groups and packages in `dnf-packages` and Google Chrome Stable from
Google's official RPM. Its services phase initializes, configures, and validates PostgreSQL and
Valkey. Its locale phase installs Spanish locale data and sets `LANG=es_VE.UTF-8`.

The `--deps`, `--fonts`, `--services`, and `--locale` flags are explicit phases for the same current
profile; they do not add support for another platform. The dependency phase installs the packages
declared in the TSV manifest, and the font phase installs each family directly under
`$HOME/.local/share/fonts/<family>/`.

## Configuration boundaries

Keep these boundaries explicit when adding files or changing setup behavior:

| Boundary         | Examples                                       | Rule                                  |
| ---------------- | ---------------------------------------------- | ------------------------------------- |
| Portable         | Shell, editor, and terminal settings           | Prefer reuse by future profiles.      |
| Omarchy-specific | Hyprland Lua, Quickshell, and keyd integration | Depend on Omarchy only when required. |
| Host-specific    | Monitors, locale, SSH, services, and mounts    | Keep values local or opt-in.          |

The repository currently stores all implemented content under `omarchy/`. This table defines intent;
it is not a reason to split the repository before a second profile requires that boundary.

## Safety rules

- Review scripts and use `./setup --profile omarchy --dots-only --dry-run` before a real run.
- Never commit secrets, private keys, passwords, or real SSH host values. `omarchy/home/ssh/config`
  is a safe template and is copied only when the local SSH config does not already exist.
- Existing targets are moved to a timestamped `backup/` path before symlinks replace them. Inspect
  those backups before deleting anything.
- Treat `omarchy/etc/` as privileged, host-specific configuration. Keyd and locale installation are
  opt-in through `--services` and `--locale`.
- Never edit `/usr/share/omarchy/`; Omarchy owns that tree and package updates overwrite it. Put
  personal Hyprland changes in the tracked Lua modules.
- Do not apply `omarchy/etc/fstab` automatically. Review and install host mount configuration
  separately when it is appropriate for that machine.

## Repository layout

- `omarchy/` — Omarchy profile.
- `fedora-wsl2/` — Fedora WSL2 development profile.
- `omarchy/home/` — files linked or copied into the user's home directory, including Herdr, Tmux,
  Zellij, and shell functions.
- `omarchy/etc/` — privileged or host-specific files requiring explicit care.
- `omarchy/utils/bash/` — profile helpers dispatched by `setup`.
- `setup` — the profile dispatcher and shared dry-run interface.
- `docs/` — setup, post-setup, Hyprland, and editor documentation.
- `backup/` — generated backups; ignored and never committed.

Source files omit the leading dot used by hidden destinations: for example, `omarchy/home/bashrc`
becomes `~/.bashrc`.

## Incremental roadmap

1. Keep `omarchy/` stable while documenting the current contracts and limits.
2. Extract only genuinely reusable configuration when a second profile is ready; do not create an
   abstract shared layer in advance.
3. Add the Ubuntu platform adapter with explicit support boundaries and tests.
4. Revisit the layout only when real cross-profile duplication or behavior differences justify it.
