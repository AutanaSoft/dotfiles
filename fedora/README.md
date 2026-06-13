# Fedora

User-managed configuration for Fedora (host: WSL2 on Windows). The repo
is the source of truth; live files in `~/.config/...` and `~/` are
symlinks into this folder.

See the [root README](../README.md) for the repo-wide layout
convention and change workflow.

## Setup on a new machine

The target host must already have Fedora installed and running. The
env executor (`scripts/setup-fedora`) is not implemented yet, so
follow the manual runbook below.

### Quick Path

1. Clone the repo (see [root README](../README.md#setup)).
2. Create target directories.
3. Create home and config symlinks.
4. Copy the SSH template only if missing.
5. Install the required tools and restart the affected applications.

### Create target directories

```bash
mkdir -p ~/.config ~/.ssh
```

### Create home symlinks

```bash
ln -sf fedora/home/.zshrc       ~/.zshrc
ln -sf fedora/home/.zshenv      ~/.zshenv
ln -sf fedora/home/.gitconfig   ~/.gitconfig
ln -sf fedora/home/.wezterm.lua ~/.wezterm.lua
```

### Create config symlinks

```bash
ln -sf fedora/config/starship.toml ~/.config/starship.toml
ln -sf fedora/config/zellij       ~/.config/zellij
ln -sf fedora/config/nvim         ~/.config/nvim
```

> `config/zellij` and `config/nvim` are directories; symlinking the
> directory exposes the whole tree.

### Create the SSH config

Copy the tracked safe template to `~/.ssh/config` only when the
target is missing — the local file always has priority:

```bash
mkdir -m 700 -p ~/.ssh
[ -e ~/.ssh/config ] || install -m 600 shared/home/.ssh/config ~/.ssh/config
```

See [docs/ssh.md](../docs/ssh.md).

### Fonts

Nerd Fonts are not part of the manual runbook. To install them
automatically:

```bash
./setup --fedora --fonts
```

## Managed paths

| Repo path                       | Target                            |
| ------------------------------- | --------------------------------- |
| `fedora/home/.zshrc`            | `~/.zshrc`                        |
| `fedora/home/.zshenv`           | `~/.zshenv`                       |
| `fedora/home/.gitconfig`        | `~/.gitconfig`                    |
| `fedora/home/.wezterm.lua`      | `~/.wezterm.lua`                  |
| `fedora/config/starship.toml`   | `~/.config/starship.toml`         |
| `fedora/config/zellij/`         | `~/.config/zellij`                |
| `fedora/config/nvim/`           | `~/.config/nvim`                  |
| `shared/home/.ssh/config`       | `~/.ssh/config`                   |

## Required manual edits

| File | What to change |
| --- | --- |
| `~/.gitconfig` | Add your real Git name and email |
| `~/.wezterm.lua` | Adjust `default_domain` if not using WSL |

## Required tools

| Tool | Why it matters |
| --- | --- |
| `zsh` | Main shell |
| `zsh-autosuggestions` | `.zshrc` plugin (Fedora package) |
| `zsh-syntax-highlighting` | `.zshrc` plugin (Fedora package) |
| `starship` | Prompt |
| `zellij` | Terminal workspace manager |
| `nvim` | Editor |
| `git` | Version control |
| `mise` | Runtime activation from shell |
| `eza`, `fd`, `ripgrep` | Shell aliases and Neovim picker |
| `lazygit` | Git TUI inside Neovim |

## Restart steps

- restart the shell for `zsh`, `starship`, and `git`
- restart `zellij` to pick up its new config
- restart `nvim`
- restart WezTerm on Windows if you changed `~/.wezterm.lua`

## Related docs

- [zsh](../docs/zsh.md)
- [git](../docs/git.md)
- [wezterm](../docs/wezterm.md)
- [ssh](../docs/ssh.md)
- [starship](../docs/starship.md)
- [zellij](../docs/zellij.md)
- [nvim](../docs/nvim.md)
- [shared layer](../docs/shared-layer.md)
