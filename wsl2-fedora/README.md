# autanasoft-dots

Personal dotfiles organized for backup, recovery, and incremental improvement.

## Quick Path

1. Read `docs/setup.md` to restore the environment on a new machine.
2. Read `docs/conventions.md` before adding or changing files.
3. Edit files in `home/` or `config/`.
4. Use the tool guides in `docs/` for day-to-day reference.

## Structure

| Path | Purpose |
| --- | --- |
| `home/` | Files that live directly in `~` |
| `config/` | Files and folders that map to `~/.config` |
| `bin/` | Personal executable scripts |
| `docs/` | Guides, conventions, and operational notes |

## Included Configs

| Tool | Repo path |
| --- | --- |
| Zsh | `home/.zshrc`, `home/.zshenv` |
| Git | `home/.gitconfig` |
| WezTerm | `home/.wezterm.lua` |
| SSH | `home/.ssh/config.example` |
| Starship | `config/starship.toml` |
| Zellij | `config/zellij/` |
| Neovim | `config/nvim/` |
| Lazygit | Via snacks.nvim in Neovim |

## Documentation

| Doc | Purpose |
| --- | --- |
| [setup](docs/setup.md) | Restore these dotfiles on a new machine |
| [conventions](docs/conventions.md) | Repo rules and file organization |
| [nvim](docs/nvim.md) | Neovim reference by mode (Normal, Insert, Visual) |
| [zellij](docs/zellij.md) | Zellij keybindings and workflow |
| [zsh](docs/zsh.md) | Shell behavior and aliases |
| [git](docs/git.md) | Git config defaults and local customization |
| [starship](docs/starship.md) | Prompt structure and editing points |
| [wezterm](docs/wezterm.md) | Windows WezTerm behavior |
| [ssh](docs/ssh.md) | Safe SSH template usage |

## Rules

- Version only configs that are actually customized.
- Keep sensitive or machine-specific data out of the repo.
- Use consistent section headers and minimal comments in config files.
- Keep operational documentation in `docs/`, not mixed into `config/`.


