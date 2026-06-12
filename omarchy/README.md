# Omarchy

User-managed configuration for the Omarchy Linux environment. The
repo is the source of truth; live files in `~/.config/...` are
symlinks into this folder.

See the [root README](../README.md) for the repo-wide layout
convention and change workflow.

## Setup on a new machine

The target machine must have Omarchy installed and running
(`~/.local/share/omarchy/default/` and the `omarchy-*` binaries
on `PATH`). The steps below create the env-side symlinks that
connect the live `~/.config/...` tree to this repo.

### Quick Path

1. (Recommended) Snapshot the current `~/.config/` before touching
   anything: `cp -a ~/.config ~/.config.bak-$(date +%F)`. Lets you
   roll back if a symlink breaks something.
2. Clone this repo into a stable path (see [root README](../README.md#setup)).
3. Create the symlinks from the table below using `ln -sfn`.
4. Reload Hyprland: `hyprctl reload && hyprctl configerrors` (must be empty).
5. Apply the custom theme: `omarchy theme tokyo-night-autana`.
6. Restart waybar: `killall waybar && waybar &`.

Do **not** run `omarchy refresh` after step 2. That command
replaces symlinks with regular files and disconnects the live
system from this repo.

### Symlink table

The paths under `omarchy/config/...` are the canonical sources
in this repo. For shared configs (`shared/zellij/...`,
`shared/nvim/...`, `shared/starship.toml`) the per-env path under
`omarchy/config/...` is itself a symlink into `shared/...`. That
two-level chain is already versioned in git; only the first hop
is created at install time.

| Repo path | Symlink on your system |
| --- | --- |
| `omarchy/config/hypr/hyprland.conf` | `~/.config/hypr/hyprland.conf` |
| `omarchy/config/hypr/hypridle.conf` | `~/.config/hypr/hypridle.conf` |
| `omarchy/config/hypr/p-bindings.conf` | `~/.config/hypr/p-bindings.conf` |
| `omarchy/config/hypr/p-index.conf` | `~/.config/hypr/p-index.conf` |
| `omarchy/config/hypr/p-looknfeel.conf` | `~/.config/hypr/p-looknfeel.conf` |
| `omarchy/config/hypr/p-monitors.conf` | `~/.config/hypr/p-monitors.conf` |
| `omarchy/config/hypr/p-rules.conf` | `~/.config/hypr/p-rules.conf` |
| `omarchy/config/waybar/config.jsonc` | `~/.config/waybar/config.jsonc` |
| `omarchy/config/alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` |
| `omarchy/config/nvim/` | `~/.config/nvim` |
| `omarchy/config/zellij/` | `~/.config/zellij` |
| `omarchy/config/omarchy/themes/tokyo-night-autana/` | `~/.config/omarchy/themes/tokyo-night-autana` |
| `omarchy/config/starship.toml` | `~/.config/starship.toml` |
| `omarchy/home/.bashrc` | `~/.bashrc` |
| `omarchy/bin/monitor` | `~/.local/bin/monitor` |

`~/.config/mako/` is intentionally left at the Omarchy default
(Omarchy ships mako config in `~/.local/share/omarchy/default/mako/`)
and is not symlinked from this repo.

## Documentation

All docs are organized by tool at [`docs/`](../docs/). The
entries most relevant to this env:

| Doc | Purpose |
| --- | --- |
| [hypr](../docs/hypr.md) | Hyprland configuration: monitors, looknfeel, window rules, keybindings, idle. |
| [bin](../docs/bin.md) | User scripts in `omarchy/bin/` (currently `monitor`). |
| [zellij](../docs/zellij.md) | Zellij keybindings, layout, and theme (shared with WSL2). |
| [nvim/opencode](../docs/nvim/opencode.md) | Neovim integration with the opencode CLI. |
| [conventions](../docs/conventions.md) | Style guide and repo rules. |
| [shared-layer](../docs/shared-layer.md) | The `shared/` layer: canonical-source rule, env-to-shared mapping, forbidden list. |
