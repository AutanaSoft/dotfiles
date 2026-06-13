# WSL2 + Fedora

User-managed configuration for Fedora running on WSL2. The repo is
the source of truth; live files in `~/.config/...` and `~/` are
symlinks into this folder.

See the [root README](../README.md) for the repo-wide layout
convention and change workflow.

## Setup on a new machine

### Quick Path

1. Clone this repo (see [root README](../README.md#setup)).
1. Create target directories.
1. Create home and config symlinks.
1. Copy and customize the SSH config.
1. Install the required tools and restart the affected applications.

### Clone the repo

```bash
git clone git@github.com:AutanaSoft/autanasoft-dots.git dotfiles
cd dotfiles
```

### Create target directories

```bash
mkdir -p ~/.config ~/.config/zellij ~/.config/nvim ~/.ssh
```

### Create home symlinks

```bash
ln -sf wsl2-fedora/home/.zshrc      ~/.zshrc
ln -sf wsl2-fedora/home/.zshenv     ~/.zshenv
ln -sf wsl2-fedora/home/.gitconfig  ~/.gitconfig
ln -sf wsl2-fedora/home/.wezterm.lua ~/.wezterm.lua
```

### Create config symlinks

```bash
ln -sf wsl2-fedora/config/starship.toml ~/.config/starship.toml
ln -sf wsl2-fedora/config/zellij       ~/.config/zellij
ln -sf wsl2-fedora/config/nvim         ~/.config/nvim
```

> `config/zellij` and `config/nvim` are directories; symlinking the directory itself
> creates a single link that points to the whole tree.

### Create the SSH config

Copy the tracked safe template to `~/.ssh/config` only when the
target is missing — the local file always has priority:

```bash
mkdir -m 700 -p ~/.ssh
if [ ! -e ~/.ssh/config ]; then
    install -m 600 shared/home/.ssh/config ~/.ssh/config
fi
```

See [docs/ssh.md](../docs/ssh.md).

### Required manual edits

| File | What to change |
| --- | --- |
| `~/.gitconfig` | Add your real Git name and email |
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

## Included configurations

| Tool | Repo path | Doc |
| --- | --- | --- |
| Zsh | `home/.zshrc`, `home/.zshenv` | [zsh](../docs/zsh.md) |
| Git | `home/.gitconfig` | [git](../docs/git.md) |
| WezTerm | `home/.wezterm.lua` | [wezterm](../docs/wezterm.md) |
| SSH | `shared/home/.ssh/config` (tracked safe template) | [ssh](../docs/ssh.md) |
| Starship | `config/starship.toml` | [starship](../docs/starship.md) |
| Zellij | `config/zellij/` | [zellij](../docs/zellij.md) |
| Neovim | `config/nvim/` | [nvim](../docs/nvim.md) |
| Lazygit | via snacks.nvim in Neovim | [nvim/lazygit](../docs/nvim/lazygit.md) |

## Documentation index

| Doc | Purpose |
| --- | --- |
| [conventions](../docs/conventions.md) | Style guide and repo rules. |
| [nvim](../docs/nvim.md) | Neovim reference by mode (Normal, Insert, Visual). |
| [nvim/lazygit](../docs/nvim/lazygit.md) | Lazygit inside Neovim. |
| [zellij](../docs/zellij.md) | Zellij keybindings and workflow. |
| [zsh](../docs/zsh.md) | Shell behavior and aliases. |
| [git](../docs/git.md) | Git config defaults and local customization. |
| [starship](../docs/starship.md) | Prompt structure and editing points. |
| [wezterm](../docs/wezterm.md) | Windows WezTerm behavior. |
| [ssh](../docs/ssh.md) | Safe SSH template usage. |
