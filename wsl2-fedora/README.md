# WSL2 + Fedora

User-managed configuration for Fedora running on WSL2. The repo is
the source of truth; live files in `~/.config/...` and `~/` are
symlinks into this folder.

See the [root README](../README.md) for the repo-wide layout
convention and change workflow.

## Setup on a new machine

Start with [docs/setup.md](docs/setup.md) for the restore procedure,
and [docs/conventions.md](docs/conventions.md) for the file
organization rules used in this folder.

## Included configurations

| Tool | Repo path | Doc |
| --- | --- | --- |
| Zsh | `home/.zshrc`, `home/.zshenv` | [zsh](docs/zsh.md) |
| Git | `home/.gitconfig` | [git](docs/git.md) |
| WezTerm | `home/.wezterm.lua` | [wezterm](docs/wezterm.md) |
| SSH | `home/.ssh/config.example` | [ssh](docs/ssh.md) |
| Starship | `config/starship.toml` | [starship](docs/starship.md) |
| Zellij | `config/zellij/` | [zellij](docs/zellij.md) |
| Neovim | `config/nvim/` | [nvim](docs/nvim.md) |
| Lazygit | via snacks.nvim in Neovim | [nvim/lazygit](docs/nvim/lazygit.md) |

## Documentation index

| Doc | Purpose |
| --- | --- |
| [setup](docs/setup.md) | Restore these dotfiles on a new machine. |
| [conventions](docs/conventions.md) | Repo rules and file organization. |
| [nvim](docs/nvim.md) | Neovim reference by mode (Normal, Insert, Visual). |
| [nvim/lazygit](docs/nvim/lazygit.md) | Lazygit inside Neovim. |
| [zellij](docs/zellij.md) | Zellij keybindings and workflow. |
| [zsh](docs/zsh.md) | Shell behavior and aliases. |
| [git](docs/git.md) | Git config defaults and local customization. |
| [starship](docs/starship.md) | Prompt structure and editing points. |
| [wezterm](docs/wezterm.md) | Windows WezTerm behavior. |
| [ssh](docs/ssh.md) | Safe SSH template usage. |
