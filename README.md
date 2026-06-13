# dotfiles

Versioned configuration for two work environments. The repo is the source of
truth; live files at `~/` and `~/.config/...` are symlinks into this folder.

## Quick Path

1. Clone the repo.
1. Run one of the setup commands below from the repo root.
1. Edit, reload, validate on every change.

## Environments

| Environment | Folder | Main stack |
| --- | --- | --- |
| Omarchy (Arch + Hyprland) | `omarchy/` | Hyprland, Alacritty, Zellij, nvim, Mako, Waybar |
| Fedora | `fedora/` | WezTerm, Zellij, nvim, Zsh, Starship, Git, SSH |

See each env's README for the per-env runbook, managed paths, and doc index.

## Setup

```bash
git clone git@github.com:AutanaSoft/autanasoft-dots.git dotfiles
cd dotfiles
./setup --omarchy --fonts
./setup --fedora --fonts    # fonts only; Fedora env setup is manual
```

`./setup` is the root entrypoint. See [`docs/setup.md`](docs/setup.md) for
script roles and options. Fedora env setup is manual for now:
[`fedora/README.md`](fedora/README.md#setup-on-a-new-machine).

## Repo layout

| Path | Maps to |
| --- | --- |
| `<env>/home/.<dotfile>` | `~/.<dotfile>` |
| `<env>/config/<app>/` | `~/.config/<app>` (shared tools symlink into [`shared/`](docs/shared-layer.md)) |
| `<env>/bin/<name>` | `~/.local/bin/<name>` (omarchy only) |
| `docs/` | Reference docs and conventions |
| `shared/` | Canonical configs valid for both environments |

## Policy summary

| Rule | See |
| --- | --- |
| Setup entrypoint is the root `./setup`; env executors live in `scripts/` | [`docs/setup.md`](docs/setup.md) |
| Only files diverging from upstream defaults are tracked | [`docs/shared-layer.md`](docs/shared-layer.md#tracking-policy) |
| System files, per-host secrets, omarchy-only configs are forbidden in the repo | [`docs/shared-layer.md`](docs/shared-layer.md#forbidden-content) |
| AI agents do not commit, push, or PR without explicit request | [`AGENTS.md`](AGENTS.md) |
| Style, doc skeleton, and formatting rules | [`docs/conventions.md`](docs/conventions.md) |

## Related docs

- [`AGENTS.md`](AGENTS.md) — AI agent and contributor guidance
- [`docs/conventions.md`](docs/conventions.md) — repo style and doc skeleton
- [`docs/setup.md`](docs/setup.md) — setup commands and script roles
- [`docs/shared-layer.md`](docs/shared-layer.md) — shared config layer rules
- [`fedora/README.md`](fedora/README.md), [`omarchy/README.md`](omarchy/README.md) — per-env runbook and doc index
