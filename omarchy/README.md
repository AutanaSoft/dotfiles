# Omarchy

User-managed configuration for the Omarchy Linux environment. The
repo is the source of truth; live files in `~/.config/...` are
symlinks into this folder.

See the [root README](../README.md) for the repo-wide layout
convention and change workflow.

## Documentation

| Doc | Purpose |
| --- | --- |
| [hypr](./docs/hypr.md) | Hyprland configuration: monitors, looknfeel, window rules, keybindings, idle. |
| [symlinks](./docs/symlinks.md) | How the repo maps to the live system, change workflow, repairing broken symlinks. |
| [bin](./docs/bin.md) | User scripts in `omarchy/bin/` (currently `monitor`). |
| [zellij](./docs/zellij.md) | Zellij keybindings, layout, and theme. |
| [nvim-opencode](./docs/nvim-opencode.md) | Neovim integration with the opencode CLI. |

Cross-environment docs (live at the repo root, not under `omarchy/`):

| Doc | Purpose |
| --- | --- |
| [shared/README.md](../shared/README.md) | The `shared/` layer: canonical-source rule, env-to-shared mapping, forbidden list. |
| [shared/zellij/README.md](../shared/zellij/README.md) | Zellij-specific shared mapping and add-theme/layout procedure. |

## Omarchy-specific rules

These extend the [tracking policy](../README.md#tracking-policy)
and the forbidden paths in the root README:

- **Removal policy** — do not delete an existing configuration line
  when deactivating behavior. Comment it out and add a `# Reason:`
  line. This keeps the history of what was tried and why.
- **Default comment block** — for every override, keep the original
  Omarchy default commented above. Example:
