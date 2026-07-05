# dotfiles

Versioned configuration for Omarchy-family hosts (stock Omarchy, CachyOS with
Omarchy layered on top, Arch with Omarchy layered on top). The repo is the
source of truth; live files at `~/` and `~/.config/...` are symlinks into this
folder. Distribution-specific configuration is owned by the Omarchy installer;
this repo's only AUR-helper concern is `yay`.

## Quick Path

1. Clone the repo.
2. Run `./setup --dots` from the repo root.
3. See [`docs/post-setup.md`](docs/post-setup.md).
4. Edit, reload, validate on every change.

## Supported Hosts

| Host              | Notes                                              |
| ----------------- | -------------------------------------------------- |
| Stock Omarchy     | Primary target                                     |
| CachyOS + Omarchy | Works — Omarchy installer handles distro specifics |
| Arch + Omarchy    | Works — Omarchy installer handles distro specifics |

The repo carries one env config (`src/home/`); host differences are resolved at
install time by `src/utils/bash/setup-deps`, which auto-detects via
`yay`/`pacman` on `PATH`.

## Setup

```bash
git clone git@github.com:AutanaSoft/dotfiles.git dotfiles
cd dotfiles
./setup --dots
```

`./setup` is the only entrypoint. Common flags:

| Flag        | What it does                                              |
| ----------- | --------------------------------------------------------- |
| `--dots`    | Full env flow: deps + fonts + dotfile links (recommended) |
| `--deps`    | OS deps only — auto-detects host                          |
| `--fonts`   | Nerd Fonts only                                           |
| `--dry-run` | Preview without mutating the system                       |

See [`docs/setup.md`](docs/setup.md) for details and verification.

## Repo Layout

| Path                        | Maps to                                                    |
| --------------------------- | ---------------------------------------------------------- |
| `src/home/<dotfile>`       | `~/.<dotfile>` (source has no leading dot per the no-dot-prefix convention) |
| `src/home/config/<app>/`    | `~/.config/<app>/` (configs that survive `omarchy update`) |
| `src/home/local/bin/<name>` | `~/.local/bin/<name>` (personal, manual only)              |
| `src/etc/<path>`            | `/etc/<path>` (system-managed, root-installed)             |
| `src/utils/bash/<name>`     | Setup helpers (invoked by root `./setup`)                  |
