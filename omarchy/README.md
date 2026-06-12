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
system from this repo. See
[Repairing a symlink](#repairing-a-symlink) if it ever happens.

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

### Creating a symlink

From the repo root:

```bash
ln -sfn omarchy/config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf
```

Format:

```
ln -sfn <path-in-repo> <where-you-want-the-symlink>
```

- `ln` — create a symlink
- `-s` — symbolic (not a hard link)
- `-f` — force: overwrite an existing file or symlink
- `-n` — **important**: treat the destination as a regular
  target even if it is a directory. Without `-n`, `ln` creates
  the symlink *inside* an existing directory instead of replacing
  it, which silently breaks the chain. Always use `-sfn`.

### Verifying the symlink

```bash
ls -la ~/.config/hypr/hyprland.conf
```

The first column must read `lrwxrwxrwx` (the `l` means it is a
link) and the arrow must point into this repo. If you see:

- `-rw-r--r--` — it is a regular file (a process replaced the
  symlink).
- `drwxr-xr-x` for a target that should be a symlink to a
  directory (for example `~/.config/nvim/`) — the symlink landed
  *inside* an existing directory instead of replacing it. See
  [Repairing a symlink](#repairing-a-symlink).

### Repairing a symlink

If `omarchy refresh` or any other process replaces a symlink
with a regular file or directory, recreate it with `ln -sfn`:

```bash
rm ~/.config/hypr/hyprland.conf   # use rm -rf for a directory
ln -sfn omarchy/config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf
hyprctl reload
```

For directory targets, `rm -rf` is required: a directory that
should be a symlink to a directory (for example `~/.config/nvim/`)
is itself the broken symlink target, not the wrong content. If
you took a `~/.config/` snapshot before bootstrapping (for
example `~/.config.bak-<date>/`), restore the original from
there.

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

## Omarchy-specific rules

These extend the [tracking policy](../README.md#tracking-policy)
and the forbidden paths in the root README:

- **Removal policy** — do not delete an existing configuration
  line when deactivating behavior. Comment it out and add a
  `# Reason:` line. This keeps the history of what was tried
  and why.
- **Default comment block** — for every override, keep the
  original Omarchy default commented above. Example:

  ```ini
  # Omarchy default (kept for reference)
  # monitor=,preferred,auto,auto

  # Personal override
  # Reason: explicit dual-monitor layout for the current desk setup
  monitor = HDMI-A-1, 2560x1440@143.91, 0x0, 1
  monitor = DP-2, 1920x1080@165, 2560x180, 1
  ```
