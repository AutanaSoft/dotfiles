# dotfiles

Versioned user configuration for two environments in one repository.

## Quick Path

1. Clone the repo (see [Setup](#setup)).
2. Follow the per-env setup (WSL2 + Fedora or Omarchy).
3. Edit, reload, validate on every change.

## Environments

| Environment | Folder | Stack |
| --- | --- | --- |
| Omarchy Linux (Arch + Hyprland) | `omarchy/` | Hyprland, Alacritty, Zellij, nvim, Mako, themes |
| Fedora on WSL2 | `wsl2-fedora/` | WezTerm, Zellij, nvim, Zsh, Starship, SSH, Git |

See each environment's README for the full per-tool index.

## Setup

Clone the repo to start using these dotfiles on any machine:

```bash
git clone git@github.com:AutanaSoft/autanasoft-dots.git dotfiles
cd dotfiles
```

All per-env setup assumes CWD is the repo root. After cloning, follow the env-specific
guide:

- WSL2 + Fedora: [`wsl2-fedora/README.md`](wsl2-fedora/README.md#setup-on-a-new-machine)
- Omarchy: [`omarchy/README.md`](omarchy/README.md#setup-on-a-new-machine)

## Repository layout convention

Each environment is a top-level folder with the same shape:

| Path in repo | Maps to |
| --- | --- |
| `home/.<dotfile>` | `~/.<dotfile>` |
| `config/<app>/<file>` | `~/.config/<app>/<file>` (see [shared layer](#shared-layer) for shared configs) |
| `bin/<name>` | User `PATH` (e.g. `~/.local/bin/<name>`) |
| `docs/` | Per-tool reference docs (organized by tool, not by env) |
| `shared/<area>/<files>` | Shared configs used by both environments (see [`docs/shared-layer.md`](docs/shared-layer.md)) |

### Shared layer

A `shared/` directory at the repo root holds configs that are
identical (or omarchy-canonical) across both environments. For
shared files the live `~/.config/<app>/<file>` resolves through a
two-level symlink chain: it points into
`<env>/config/<app>/<file>`, which itself points into
`shared/<app>/<file>`. The canonical-source rule (omarchy wins when
configs diverge), the env-to-shared mapping, and the list of files
forbidden in `shared/` all live in
[`docs/shared-layer.md`](docs/shared-layer.md).

The repository is the **source of truth**: the live files at
`~/.config/...` are symlinks pointing into the repo. Edit the repo
and the running system sees the change.

## Change workflow

1. Edit the file in the repo.
2. The symlink makes the change visible to the live system
   immediately.
3. Reload the affected service and validate. For Hyprland:
   `hyprctl reload` then `hyprctl configerrors` (must be empty).

## Tracking policy

Only files that **diverge from environment defaults** are tracked.
Anything that matches the upstream default stays out of the repo even
if it exists in `~/.config/`. This keeps the diff focused on what the
user actually changed. The shared layer's stricter tracking rules
(see [`docs/shared-layer.md`](docs/shared-layer.md#tracking-policy))
extend this for the `shared/` folder.

## Editor formatting

The repo declares formatting conventions in
[`.editorconfig`](.editorconfig) at the repo root. Editors that
respect EditorConfig (including Neovim with the
[`editorconfig-vim`](https://github.com/editorconfig/editorconfig-vim)
plugin) pick up the conventions automatically.

The Neovim plugin spec lives at
[`shared/nvim/lua/plugins/editorconfig.lua`](shared/nvim/lua/plugins/editorconfig.lua)
and is symlinked into both envs (per-env path → shared target).

**AI agents** working in this repo (such as opencode) should respect
the `.editorconfig` rules when generating or editing files. The file
is at the repo root for easy discovery.

## Forbidden paths

Do not modify system files or Omarchy source files under
`~/.local/share/omarchy/`. Those are managed by the system and any
edit is overwritten on the next `omarchy update`. The full forbidden
list (per-host secrets, omarchy-only paths, per-terminal configs that
legitimately differ) lives in
[`docs/shared-layer.md`](docs/shared-layer.md#forbidden-content).

## Related Files

- [`AGENTS.md`](AGENTS.md) — repo-wide AI agent and contributor guidance.
- [`docs/conventions.md`](docs/conventions.md) — style guide and Current Decisions.
- [`docs/shared-layer.md`](docs/shared-layer.md) — shared config layer rules.
- [`wsl2-fedora/README.md`](wsl2-fedora/README.md), [`omarchy/README.md`](omarchy/README.md) — per-env setup and doc index.
