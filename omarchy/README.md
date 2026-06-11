# Omarchy

User-managed configuration for the Omarchy Linux environment. The
repo is the source of truth; live files in `~/.config/...` are
symlinks into this folder.

See the [root README](../README.md) for the repo-wide layout
convention and change workflow.

## Documentation

All docs are organized by tool at [`docs/`](../docs/). The entries
most relevant to this env:

| Doc | Purpose |
| --- | --- |
| [hypr](../docs/hypr.md) | Hyprland configuration: monitors, looknfeel, window rules, keybindings, idle. |
| [setup](../docs/setup.md#omarchy) | Symlink workflow, `omarchy refresh` repair, change workflow. |
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
