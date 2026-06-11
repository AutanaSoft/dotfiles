# Setup Guide

This guide explains how to restore these dotfiles on a new machine using a simple manual flow.

## Quick Path

1. Clone this repo.
2. Copy each config file to its target location.
3. Install the required tools.
4. Restart the affected applications or shell.

## Repository Mapping

| Repo path                  | Target path               |
| -------------------------- | ------------------------- |
| `home/.zshrc`              | `~/.zshrc`                |
| `home/.zshenv`             | `~/.zshenv`               |
| `home/.gitconfig`          | `~/.gitconfig`            |
| `home/.wezterm.lua`        | `~/.wezterm.lua`          |
| `home/.ssh/config.example` | `~/.ssh/config`           |
| `config/starship.toml`     | `~/.config/starship.toml` |
| `config/zellij/`           | `~/.config/zellij/`       |
| `config/nvim/`             | `~/.config/nvim/`         |

## Clone The Repo

```bash
git clone git@github.com:AutanaSoft/autanasoft-dots.git ~/Projects/autanasoft/dots
cd ~/Projects/autanasoft/dots
```

## Copy Files Manually

Create target directories first:

```bash
mkdir -p ~/.config ~/.config/zellij ~/.config/nvim ~/.ssh
```

Copy home files:

```bash
cp home/.zshrc ~/.zshrc
cp home/.zshenv ~/.zshenv
cp home/.gitconfig ~/.gitconfig
cp home/.wezterm.lua ~/.wezterm.lua
```

Copy application configs:

```bash
cp config/starship.toml ~/.config/starship.toml
cp -r config/zellij/* ~/.config/zellij/
cp -r config/nvim/* ~/.config/nvim/
```

Create SSH config from the example:

```bash
cp home/.ssh/config.example ~/.ssh/config
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
```

## Required Manual Edits

Edit these files after copying:

| File             | What to change                                     |
| ---------------- | -------------------------------------------------- |
| `~/.gitconfig`   | Add your real Git name and email                   |
| `~/.ssh/config`  | Replace example hosts, users, and identity files   |
| `~/.wezterm.lua` | Remove or adjust `default_domain` if not using WSL |

## Required Tools

These dotfiles assume the following tools exist:

| Tool        | Why it matters                       |
| ----------- | ------------------------------------ |
| `zsh`       | Main shell                           |
| `zsh-autosuggestions` | Fish-style autosuggestions for `.zshrc` (Fedora package) |
| `zsh-syntax-highlighting` | Command-line syntax highlighting for `.zshrc` (Fedora package) |
| `starship`  | Prompt                               |
| `zellij`    | Terminal workspace manager           |
| `nvim`      | Editor                               |
| `git`       | Version control                      |
| `mise`      | Runtime activation from shell        |
| `eza`       | Replaces `ls` aliases                |
| `fd`        | Fast file search used by nvim picker |
| `ripgrep`   | Fast text search used by nvim picker |
| `lazygit`   | Git terminal UI inside Neovim        |

## Restart Steps

After copying configs:

- restart the shell for `zsh`, `starship`, and `git`
- restart `zellij` to pick up its new config
- restart `nvim`
- restart WezTerm on Windows if you changed `~/.wezterm.lua`

## Notes

- `home/.ssh/config.example` is only a template and must not be used as-is.
- `config/zellij/` includes the Zellij plugin binaries used by the config.
- `config/nvim/lazy-lock.json` is versioned to keep plugin versions reproducible.

## Related Docs

- `docs/conventions.md`
- `docs/zellij.md`
- `docs/nvim.md`
