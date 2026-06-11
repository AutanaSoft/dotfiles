# Setup Guide

This guide explains how to install these dotfiles on a new machine. The repo is the source of
truth: live files in `~/.config/...` and `~/...` are symlinks pointing into the repo.

Two environments are supported. Each has its own flow:

- **WSL2 + Fedora** — manual symlink creation.
- **Omarchy** — `omarchy refresh` plus manual symlink repair when needed.

## Quick Path

1. Clone this repo.
2. Per-distro: create symlinks (or run `omarchy refresh`).
3. For SSH, copy `home/.ssh/config.example` to `~/.ssh/config` and customize.
4. Install the required tools (see per-distro sections).
5. Restart the affected applications or shell.

## Repository layout

| Path in repo | Maps to |
| --- | --- |
| `home/.<dotfile>` | `~/.<dotfile>` |
| `config/<app>/<file>` | `~/.config/<app>/<file>` (see [shared layer](#shared-layer)) |
| `bin/<name>` | User PATH (e.g. `~/.local/bin/<name>`) |
| `shared/<area>/<files>` | Shared configs used by both envs |

For the full layout convention, see the root `README.md`.

## WSL2 + Fedora

### Clone the repo

```bash
git clone git@github.com:AutanaSoft/autanasoft-dots.git ~/Projects/autanasoft/dots
cd ~/Projects/autanasoft/dots
```

### Create symlinks

Create target directories first:

```bash
mkdir -p ~/.config ~/.config/zellij ~/.config/nvim ~/.ssh
```

Create home symlinks:

```bash
ln -sf ~/Projects/autanasoft/dots/wsl2-fedora/home/.zshrc      ~/.zshrc
ln -sf ~/Projects/autanasoft/dots/wsl2-fedora/home/.zshenv     ~/.zshenv
ln -sf ~/Projects/autanasoft/dots/wsl2-fedora/home/.gitconfig  ~/.gitconfig
ln -sf ~/Projects/autanasoft/dots/wsl2-fedora/home/.wezterm.lua ~/.wezterm.lua
```

Create config symlinks:

```bash
ln -sf ~/Projects/autanasoft/dots/wsl2-fedora/config/starship.toml ~/.config/starship.toml
ln -sf ~/Projects/autanasoft/dots/wsl2-fedora/config/zellij       ~/.config/zellij
ln -sf ~/Projects/autanasoft/dots/wsl2-fedora/config/nvim         ~/.config/nvim
```

> `config/zellij` and `config/nvim` are directories; symlinking the directory itself creates
> a single link that points to the whole tree.

### Create the SSH config

The SSH config must be a real file (not a symlink) because each user customizes it.

```bash
cp wsl2-fedora/home/.ssh/config.example ~/.ssh/config
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
```

### Required manual edits

| File | What to change |
| --- | --- |
| `~/.gitconfig` | Add your real Git name and email |
| `~/.ssh/config` | Replace example hosts, users, and identity files |
| `~/.wezterm.lua` | Remove or adjust `default_domain` if not using WSL |

### Required tools

These dotfiles assume the following tools exist:

| Tool | Why it matters |
| --- | --- |
| `zsh` | Main shell |
| `zsh-autosuggestions` | Fish-style autosuggestions for `.zshrc` (Fedora package) |
| `zsh-syntax-highlighting` | Command-line syntax highlighting for `.zshrc` (Fedora package) |
| `starship` | Prompt |
| `zellij` | Terminal workspace manager |
| `nvim` | Editor |
| `git` | Version control |
| `mise` | Runtime activation from shell |
| `eza` | Replaces `ls` aliases |
| `fd` | Fast file search used by nvim picker |
| `ripgrep` | Fast text search used by nvim picker |
| `lazygit` | Git terminal UI inside Neovim |

### Restart steps

- restart the shell for `zsh`, `starship`, and `git`
- restart `zellij` to pick up its new config
- restart `nvim`
- restart WezTerm on Windows if you changed `~/.wezterm.lua`

## Omarchy

The Omarchy install manages most symlinks via `omarchy refresh`. For the dotfiles in this
repo, that command creates the env-side symlinks automatically. The sections below cover
manual repair and verification.

### Symlink table

| Repo file | Symlink on your system |
| --- | --- |
| `omarchy/config/hypr/hypr.conf` | `~/.config/hypr/hypr.conf` |
| `omarchy/config/waybar/config` | `~/.config/waybar/config` |
| `omarchy/config/alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` |
| `omarchy/config/foot/foot.ini` | `~/.config/foot/foot.ini` |
| `omarchy/home/.zshrc` | `~/.zshrc` |
| `omarchy/bin/omarchy-sync` | `~/.local/bin/omarchy-sync` |

For shared configs (`shared/zellij/...`, `shared/nvim/...`, `shared/starship.toml`), the
per-env path in `omarchy/config/...` is itself a symlink into `shared/...`. Two-level chain.

### Creating a symlink

```bash
ln -sf ~/Projects/autanasoft/dotfiles/omarchy/config/hypr/hypr.conf ~/.config/hypr/hypr.conf
```

Format:

```
ln -sf <path-in-repo> <where-you-want-the-symlink>
```

- `ln` — symlink command
- `-s` — symbolic (not a hard link)
- `-f` — force: overwrite if it already exists

### Verifying the symlink

```bash
ls -la ~/.config/hypr/hypr.conf
```

If the first column shows `lrwxrwxrwx`, the symlink is OK. If it shows `-rw-r--r--`, it is a regular file (the symlink was broken).

### If `omarchy refresh` breaks it

`omarchy refresh` replaces symlinks with regular files. To repair:

```bash
rm ~/.config/hypr/hypr.conf
ln -sf ~/Projects/autanasoft/dotfiles/omarchy/config/hypr/hypr.conf ~/.config/hypr/hypr.conf
```

## Notes

- `home/.ssh/config.example` is only a template and must not be used as-is.
- `config/zellij/` includes the Zellij plugin binaries used by the config.
- `config/nvim/lazy-lock.json` is versioned to keep plugin versions reproducible.
- The WSL2 + Fedora flow now uses symlinks (consistent with the Omarchy flow and the rest
  of the repo). The previous "copy" approach in the old `wsl2-fedora/docs/setup.md` is
  deprecated.

## Related Files

- [`docs/conventions.md`](conventions.md) (file organization and style guide)
- [`docs/shared-layer.md`](shared-layer.md) (shared config rules)
- [`docs/zellij.md`](zellij.md) (Zellij keybindings)
- [`docs/nvim.md`](nvim.md) (Neovim reference)
