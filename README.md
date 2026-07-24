# dotfiles

This repository is the source of truth for one implemented profile:
`omarchy/`. It targets Omarchy, Arch with Omarchy installed, and CachyOS with
Omarchy installed. Managed files are linked into `$HOME` and `~/.config/`;
generated backups are stored under `backup/` and are ignored by Git.

Ubuntu, Fedora, and WSL2 profiles are future work. They are not supported by
the current installer or configuration set.

## Quick path

On an existing Omarchy-family installation with a running Hyprland session:

```bash
git clone git@github.com:AutanaSoft/dotfiles.git dotfiles
cd dotfiles
./setup --dots --dry-run
./setup --dots
```

Use [`docs/setup.md`](docs/setup.md) for available flags and
[`docs/post-setup.md`](docs/post-setup.md) for manual host setup.

## Current limits

The `./setup` entrypoint is a dispatcher, not a distribution-neutral installer.
The implemented `--dots` flow currently:

- selects the `omarchy/` profile;
- expects an existing Omarchy installation, or Arch/CachyOS with Omarchy
  installed;
- uses the Arch package toolchain (`yay` and `pacman`) for dependencies;
- requires the `omarchy` command and `hyprctl` from a running Hyprland session;
- installs packages, user-local fonts, symlinks, the keyd configuration, and
  input-device services; and
- applies the tracked Omarchy theme and validates Hyprland configuration.

It does not install Omarchy, support Ubuntu/Fedora/WSL2, or provide a headless
or non-graphical setup path. `--dry-run` previews actions, but it still expects
the relevant profile tools to be discoverable where the selected helper checks
them.

The standalone `--deps`, `--fonts`, and `--locale` flags are helpers for the
same current profile; they do not add support for another platform.

## Configuration boundaries

Keep these boundaries explicit when adding files or changing setup behavior:

| Boundary | Examples | Rule |
| --- | --- | --- |
| Portable | Shell, editor, and terminal settings | Prefer reuse by future profiles. |
| Omarchy-specific | Hyprland, Waybar, theme, and keyd integration | Depend on Omarchy only when required. |
| Host-specific | Monitors, locale, SSH, services, and mounts | Keep values local or opt-in. |

The repository currently stores all implemented content under `omarchy/`. This
table defines intent; it is not a reason to split the repository before a
second profile requires that boundary.

## Safety rules

- Review scripts and use `./setup --dots --dry-run` before a real run.
- Never commit secrets, private keys, passwords, or real SSH host values.
  `omarchy/home/ssh/config` is a safe template and is copied only when the
  local SSH config does not already exist.
- Existing targets are moved to a timestamped `backup/` path before symlinks
  replace them. Inspect those backups before deleting anything.
- Treat `omarchy/etc/` as privileged, host-specific configuration. The setup
  flow installs keyd configuration; locale installation is opt-in through
  `./setup --locale`.
- Never edit `~/.local/share/omarchy/`; Omarchy owns that tree and updates can
  overwrite it. Put personal Hyprland changes in the tracked user files.
- Do not apply `omarchy/etc/fstab` automatically. Review and install host mount
  configuration separately when it is appropriate for that machine.

## Repository layout

- `omarchy/` — the only implemented profile.
- `omarchy/home/` — files linked or copied into the user's home directory.
- `omarchy/etc/` — privileged or host-specific files requiring explicit care.
- `omarchy/utils/bash/` — profile helpers dispatched by `setup`.
- `setup` — the profile dispatcher and shared dry-run interface.
- `docs/` — setup, post-setup, Hyprland, and editor documentation.
- `backup/` — generated backups; ignored and never committed.

Source files omit the leading dot used by hidden destinations: for example,
`omarchy/home/bashrc` becomes `~/.bashrc`.

## Incremental roadmap

1. Keep `omarchy/` stable while documenting the current contracts and limits.
2. Extract only genuinely reusable configuration when a second profile is
   ready; do not create an abstract shared layer in advance.
3. Add platform adapters and verification for Ubuntu, Fedora, and WSL2 one at a
   time, with explicit support boundaries and tests for each installer path.
4. Revisit the layout only when real cross-profile duplication or behavior
   differences justify it.
