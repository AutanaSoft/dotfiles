# Omarchy

User-managed configuration for the Omarchy Linux environment. The
repo is the source of truth; live files in `~/.config/...` are
symlinks into this folder.

See the [root README](../README.md) for the repo-wide layout
convention and change workflow.

## Setup on a new machine

### Quick Path

1. Clone this repo.
2. Run `omarchy refresh` to create the env-side symlinks.
3. Use `ln -sf` for any symlink that `omarchy refresh` does not manage.

The Omarchy install manages most symlinks via `omarchy refresh`. For the dotfiles in
this repo, that command creates the env-side symlinks automatically. The sections
below cover manual symlink creation, verification, and repair.

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

> Replace `<path-to-clone-dir>` with the directory where you cloned the repo (e.g. `Projects/autanasoft`).

```bash
ln -sf ~/<path-to-clone-dir>/dotfiles/omarchy/config/hypr/hypr.conf ~/.config/hypr/hypr.conf
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
ln -sf ~/<path-to-clone-dir>/dotfiles/omarchy/config/hypr/hypr.conf ~/.config/hypr/hypr.conf
```

## Documentation

All docs are organized by tool at [`docs/`](../docs/). The entries most relevant to this env:

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

- **Removal policy** — do not delete an existing configuration line
  when deactivating behavior. Comment it out and add a `# Reason:`
  line. This keeps the history of what was tried and why.
- **Default comment block** — for every override, keep the original
  Omarchy default commented above. Example:
