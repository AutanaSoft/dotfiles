# dotfiles

Versioned configuration for Omarchy-family hosts (stock Omarchy, CachyOS with
Omarchy layered on top, Arch with Omarchy layered on top). The repo is the
source of truth; live files at `~/` and `~/.config/...` are symlinks into this
folder. Distribution-specific configuration is owned by the Omarchy installer;
this repo's only AUR-helper concern is `yay`.

## Quick Path

1. Clone the repo.
1. Run `./setup --dots` from the repo root.
1. Edit, reload, validate on every change.

## Environment

| Environment | Folder | Main stack |
| --- | --- | --- |
| Omarchy (Arch + Hyprland) | `src/home/config/` | Hyprland, Alacritty, Zellij, nvim, Mako, Waybar |

See [`src/README.md`](src/README.md) for the per-env runbook, managed
paths, and doc index.

## Setup

```bash
git clone git@github.com:AutanaSoft/autanasoft-dots.git dotfiles
cd dotfiles
./setup --dots --fonts
```

`./setup` is the root entrypoint. See [`docs/setup.md`](docs/setup.md) for
script roles and options.

## Repo layout

| Path | Maps to |
| --- | --- |
| `src/home/.<dotfile>` | `~/.<dotfile>` |
| `src/home/config/<app>/` | `~/.config/<app>/` (tools whose config survives `omarchy update`) |
| `src/home/local/bin/<name>` | `~/.local/bin/<name>` (personal, manual only) |
| `src/etc/<path>` | `/etc/<path>` (system-managed, root-installed) |
| `src/utils/bash/<name>` | Setup helpers (invoked by root `./setup`) |
| `src/README.md` | Per-env runbook + managed-paths table |
| `docs/` | Reference docs and conventions |

## Policy summary

| Rule | See |
| --- | --- |
| Setup entrypoint is the root `./setup`; env executors live in `src/utils/bash/` | [`docs/setup.md`](docs/setup.md) |
| Only files diverging from upstream defaults are tracked | [`docs/shared-layer.md`](docs/shared-layer.md#tracking-policy) |
| System files, per-host secrets, omarchy-only configs are forbidden in the repo | [`docs/shared-layer.md`](docs/shared-layer.md#forbidden-content) |
| AI agents do not commit, push, or PR without explicit request | [`AGENTS.md`](AGENTS.md) |
| Style, doc skeleton, and formatting rules | [`docs/conventions.md`](docs/conventions.md) |

## Related docs

- [`AGENTS.md`](AGENTS.md) — AI agent and contributor guidance
- [`docs/conventions.md`](docs/conventions.md) — repo style and doc skeleton
- [`docs/setup.md`](docs/setup.md) — setup commands and script roles
- [`docs/shared-layer.md`](docs/shared-layer.md) — shared config layer rules
- [`src/README.md`](src/README.md) — per-env runbook and doc index