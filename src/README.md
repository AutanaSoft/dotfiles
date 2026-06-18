# Omarchy

User-managed configuration for the Omarchy Linux environment. The repo is the
source of truth; live files in `~/.config/...` are symlinked from this folder.

## Setup on a new machine

The target machine must already have Omarchy installed and running.

### Automated setup

Run from the repo root:

```bash
./setup --dots --fonts
```

Use `./setup --help` for all options.

### Manual setup

1. Optional backup: `cp -a ~/.config ~/.config.bak-$(date +%F)`.
2. Create the symlinks marked `Yes` in [Managed paths](#managed-paths).
3. Reload Hyprland: `hyprctl reload && hyprctl configerrors`.
4. Apply theme: `omarchy theme set tokyo-night-autana`.
5. Restart waybar: `killall waybar && waybar &`.

Do **not** run `omarchy refresh`; it replaces symlinks with regular files.

## Managed paths

| Repo path                                                  | Target                                        | Automated            |
| ---------------------------------------------------------- | --------------------------------------------- | -------------------- |
| `src/home/config/hypr/hyprland.conf`                       | `~/.config/hypr/hyprland.conf`                | Yes                  |
| `src/home/config/hypr/hypridle.conf`                       | `~/.config/hypr/hypridle.conf`                | Yes                  |
| `src/home/config/hypr/p-bindings.conf`                     | `~/.config/hypr/p-bindings.conf`              | Yes                  |
| `src/home/config/hypr/p-index.conf`                        | `~/.config/hypr/p-index.conf`                 | Yes                  |
| `src/home/config/hypr/p-looknfeel.conf`                    | `~/.config/hypr/p-looknfeel.conf`             | Yes                  |
| `src/home/config/hypr/p-monitors.conf`                     | `~/.config/hypr/p-monitors.conf`              | Yes                  |
| `src/home/config/hypr/p-rules.conf`                        | `~/.config/hypr/p-rules.conf`                 | Yes                  |
| `src/home/config/waybar/config.jsonc`                      | `~/.config/waybar/config.jsonc`               | Yes                  |
| `src/home/config/alacritty/alacritty.toml`                 | `~/.config/alacritty/alacritty.toml`          | Yes                  |
| `src/home/config/nvim/`                                    | `~/.config/nvim`                              | Yes                  |
| `src/home/config/zellij/`                                  | `~/.config/zellij`                            | Yes                  |
| `src/home/config/omarchy/themes/tokyo-night-autana/`       | `~/.config/omarchy/themes/tokyo-night-autana` | Yes                  |
| `src/home/config/starship.toml`                            | `~/.config/starship.toml`                     | Yes                  |
| `src/home/.bashrc`                                         | `~/.bashrc`                                   | Yes                  |
| `src/home/.ssh/config`                                     | `~/.ssh/config`                               | Copy only if missing |
| `src/home/local/bin/monitor`                               | `~/.local/bin/monitor`                        | No — manual only     |
| `src/etc/keyd/default.conf`                                | `/etc/keyd/default.conf`                      | Yes (sudo install)   |

To seed SSH manually, copy the template only if the local config is missing:

```bash
mkdir -m 700 -p ~/.ssh
[ -e ~/.ssh/config ] || install -m 600 src/home/.ssh/config ~/.ssh/config
```

## Related docs

- [hypr](../docs/hypr.md)
- [setup](../docs/setup.md)
- [ssh](../docs/ssh.md)
- [shared layer](../docs/shared-layer.md)
- [bin](../docs/bin.md)