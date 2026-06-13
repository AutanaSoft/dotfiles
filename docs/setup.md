# Setup

`./setup` is the root entrypoint for this repo. It runs safe, repeatable setup
steps from the repo root.

## Commands

| Command | Purpose |
| --- | --- |
| `./setup --fonts` | Install fonts only. |
| `./setup --omarchy --fonts` | Apply Omarchy config and install fonts. |
| `./setup --omarchy` | Apply Omarchy config only. |
| `./setup --fedora --fonts` | Install fonts only; Fedora env setup is manual. |
| `./setup --dry-run ...` | Preview actions without mutating the system. |
| `./setup --help` | Show all options. |

## Scripts

| Script | Role |
| --- | --- |
| `setup` | Root entrypoint and dispatcher. |
| `scripts/setup-omarchy` | Applies Omarchy symlinks, SSH seed, theme, and reload. |
| `scripts/setup-fonts` | Installs local Nerd Fonts. |

## Notes

- Fedora setup has no env executor yet; use `fedora/README.md` for manual setup.
- `--dry-run` must not download files, move backups, or modify live configs.
- New env executors belong in `scripts/setup-<env>`.

## Related Files

- `setup`
- `scripts/setup-omarchy`
- `scripts/setup-fonts`
- `omarchy/README.md`
- `fedora/README.md`
