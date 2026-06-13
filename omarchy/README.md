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

### Automated setup

From the repo root, run the root entrypoint `./setup`:

```bash
./setup --fonts                  # install fonts only
./setup --omarchy                # apply the Omarchy env configuration
./setup --omarchy --fonts        # install fonts first, then apply the env
./setup --dry-run --omarchy --fonts   # preview every action
```

`./setup` is a thin orchestrator: it dispatches to `scripts/setup-fonts`
(Nerd Fonts into `~/.local/share/fonts/autanasoft/`) and then to
`scripts/setup-omarchy` (env symlinks + theme + Hyprland reload). Order
is fonts first, env second. Use `./setup --help` for the full flag
summary. The script does not install Omarchy itself and will not touch
`omarchy/local/bin/monitor` (a personal/manual script).

#### Fonts

The Alacritty, Waybar, and Walker configs in this repo reference
`Monaspace Krypton NF` (and a `JetBrainsMono Nerd Font` fallback),
so a working fontconfig setup is part of the install. `./setup`
does **not** install fonts by default; opt in with `--fonts` (alias
`--font`):

```bash
./setup --fonts                    # install fonts only
./setup --omarchy --fonts          # install fonts, then apply env
./setup --dry-run --omarchy --fonts # preview the font install
```

The fonts step runs the executor at `scripts/setup-fonts`, which
installs the Nerd Fonts (Monaspace, FiraCode, FiraMono) into
`~/.local/share/fonts/autanasoft/` — no sudo, no system-wide
`/usr/share/fonts` changes. You can also run that executor
directly: `scripts/setup-fonts --help`.

### Quick Path

1. (Recommended) Snapshot the current `~/.config/` before touching
   anything: `cp -a ~/.config ~/.config.bak-$(date +%F)`. Lets you
   roll back if a symlink breaks something.
2. Clone this repo into a stable path (see [root README](../README.md#setup)).
3. Create the symlinks from the table below using `ln -sfn`.
4. Reload Hyprland: `hyprctl reload && hyprctl configerrors` (must be empty).
5. Apply the custom theme: `omarchy theme set tokyo-night-autana`.
6. Restart waybar: `killall waybar && waybar &`.

Do **not** run `omarchy refresh` after step 2. That command
replaces symlinks with regular files and disconnects the live
system from this repo.

### Symlink table

The paths under `omarchy/config/...` are the repo-side sources for
this env. Shared tools such as `nvim/` and `zellij/` are folder
symlinks into `shared/`; at install time, create only the live
`~/.config/...` symlink shown below.

| Repo path | Symlink on your system | Applied by `./setup --omarchy` |
| --- | --- | --- |
| `omarchy/config/hypr/hyprland.conf` | `~/.config/hypr/hyprland.conf` | Yes |
| `omarchy/config/hypr/hypridle.conf` | `~/.config/hypr/hypridle.conf` | Yes |
| `omarchy/config/hypr/p-bindings.conf` | `~/.config/hypr/p-bindings.conf` | Yes |
| `omarchy/config/hypr/p-index.conf` | `~/.config/hypr/p-index.conf` | Yes |
| `omarchy/config/hypr/p-looknfeel.conf` | `~/.config/hypr/p-looknfeel.conf` | Yes |
| `omarchy/config/hypr/p-monitors.conf` | `~/.config/hypr/p-monitors.conf` | Yes |
| `omarchy/config/hypr/p-rules.conf` | `~/.config/hypr/p-rules.conf` | Yes |
| `omarchy/config/waybar/config.jsonc` | `~/.config/waybar/config.jsonc` | Yes |
| `omarchy/config/alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` | Yes |
| `omarchy/config/nvim/` | `~/.config/nvim` | Yes |
| `omarchy/config/zellij/` | `~/.config/zellij` | Yes |
| `omarchy/config/omarchy/themes/tokyo-night-autana/` | `~/.config/omarchy/themes/tokyo-night-autana` | Yes |
| `omarchy/config/starship.toml` | `~/.config/starship.toml` | Yes |
| `omarchy/home/.bashrc` | `~/.bashrc` | Yes |
| `omarchy/local/bin/monitor` | `~/.local/bin/monitor` | No — manual only |

`~/.config/mako/` is intentionally left at the Omarchy default
(Omarchy ships mako config in `~/.local/share/omarchy/default/mako/`)
and is not symlinked from this repo.

## Documentation

All docs are organized by tool at [`docs/`](../docs/). The
entries most relevant to this env:

| Doc | Purpose |
| --- | --- |
| [hypr](../docs/hypr.md) | Hyprland configuration: monitors, looknfeel, window rules, keybindings, idle. |
| [bin](../docs/bin.md) | User scripts in `omarchy/local/bin/` (currently `monitor`). |
| [zellij](../docs/zellij.md) | Zellij keybindings, layout, and theme (shared with WSL2). |
| [nvim/opencode](../docs/nvim/opencode.md) | Neovim integration with the opencode CLI. |
| [conventions](../docs/conventions.md) | Style guide and repo rules. |
| [shared-layer](../docs/shared-layer.md) | The `shared/` layer: canonical-source rule, env-to-shared mapping, forbidden list. |
