# Setup

`./setup` is the profile dispatcher. The only implemented profile is `omarchy`.
It resolves the repository root independently of the current directory and
validates the complete request before invoking a profile helper.

## Quick path

Preview and apply only user dotfiles:

```bash
./setup --profile omarchy --dots-only --dry-run
./setup --profile omarchy --dots-only
```

For the full interactive flow, `--dots` applies dotfiles and asks which
optional phases to run. Empty or negative answers leave a phase disabled.

## CLI contract

| Flag | Meaning |
| --- | --- |
| `--profile omarchy` | Select the implemented profile. Interactive runs offer `omarchy` when omitted. |
| `--dots` | Apply dotfiles, ask interactively about optional phases, then validate unless `--no-validate` is used. |
| `--dots-only` | Apply only the manifest and permitted user copies. It cannot combine with optional phases and skips validation. |
| `--deps` | Validate and install the packages in `omarchy/deps-manifest` in one batch. |
| `--fonts` | Install user-local fonts under `$HOME/.local/share/fonts/<family>/`. |
| `--services` | Install keyd configuration and enable keyd/ratbagd. |
| `--locale` | Opt in to the locale declared by `omarchy/etc/locale.conf`. |
| `--no-validate` | Skip the final validation of a `--dots` run. |
| `--non-interactive` | Require `--profile` and run only phases explicitly declared by flags. |
| `--dry-run` | Show actions without downloads, writes, sudo, service changes, or graphical changes. |
| `--help`, `-h` | Show usage. |

Without `--non-interactive`, `--dots` asks separately about `deps`, `fonts`,
`services`, and `locale`. In non-interactive mode, no optional phase is
inferred. A request such as `--profile omarchy --deps --dry-run` runs only the
dependency phase; it does not apply dotfiles or validation.

## Safety boundaries

- `setup-dots` owns only manifest operations, backups, symlinks, and allowed copies.
- `setup-deps`, `setup-fonts`, `setup-services`, `setup-locale`, and
  `setup-validate` each own one phase.
- `--dry-run` never invokes `sudo`, package managers, downloads, `fc-cache`,
  service management, or Hyprland commands.
- Existing targets are moved to a timestamped `backup/` path before replacement.
- Fonts are installed directly under `$HOME/.local/share/fonts/<family>/`.

## Related files

- `setup` — public dispatcher.
- `omarchy/utils/bash/setup-omarchy` — Omarchy phase orchestrator.
- `omarchy/utils/bash/setup-dots` — user dotfiles and manifest executor.
- `omarchy/deps-manifest` — the package manifest consumed by the dependency phase.
- `omarchy/utils/bash/setup-deps` — dependency manifest parser and installer.
- `omarchy/utils/bash/setup-fonts` — user-local Nerd Font installer.
- `omarchy/utils/bash/setup-services` — keyd and ratbagd configuration.
- `omarchy/utils/bash/setup-validate` — theme and Hyprland validation.
- `omarchy/utils/bash/setup-locale` — opt-in locale installer.
