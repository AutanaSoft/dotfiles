# `shared/zellij/` — Zellij config shared across environments

This directory holds the canonical Zellij config (`config.kdl`), themes, layouts, and wasm plugins used by both `omarchy/` and `wsl2-fedora/`. Per-env copies are relative symlinks into this directory.

The canonical source for every file in this directory is the **omarchy** working copy (per `shared/README.md` → "Canonical source rule"). If a shared file ever needs to be modified, edit it here; both envs pick up the change on next Zellij launch.

## Mapping table

| Env path | Shared path | Mechanism | Notes |
| --- | --- | --- | --- |
| `omarchy/config/zellij/config.kdl` | `shared/zellij/config.kdl` | symlink | canonical (post-`pane_frames` decision; `pane_frames false` is the uncommented value) |
| `wsl2-fedora/config/zellij/config.kdl` | `shared/zellij/config.kdl` | symlink | same target as omarchy |
| `omarchy/config/zellij/themes/tokyo-night.kdl` | `shared/zellij/themes/tokyo-night.kdl` | symlink | bit-identical |
| `wsl2-fedora/config/zellij/themes/tokyo-night.kdl` | `shared/zellij/themes/tokyo-night.kdl` | symlink | same target as omarchy |
| `omarchy/config/zellij/themes/tokyo-night-storm.kdl` | `shared/zellij/themes/tokyo-night-storm.kdl` | symlink | bit-identical |
| `wsl2-fedora/config/zellij/themes/tokyo-night-storm.kdl` | `shared/zellij/themes/tokyo-night-storm.kdl` | symlink | same target as omarchy |
| `omarchy/config/zellij/layouts/autanasoft.kdl` | `shared/zellij/layouts/autanasoft.kdl` | symlink | bit-identical |
| `wsl2-fedora/config/zellij/layouts/autanasoft.kdl` | `shared/zellij/layouts/autanasoft.kdl` | symlink | same target as omarchy |
| `omarchy/config/zellij/plugins/{zellij_forgot,zjframes,zjstatus}.wasm` | `shared/zellij/plugins/<name>.wasm` | symlink | md5 parity preserved |
| `wsl2-fedora/config/zellij/plugins/{zellij_forgot,zjframes,zjstatus}.wasm` | `shared/zellij/plugins/<name>.wasm` | symlink | same target as omarchy |

## Procedure for adding a new theme or layout

1. Drop the new file in the appropriate subdirectory: `shared/zellij/themes/<name>.kdl` or `shared/zellij/layouts/<name>.kdl`.
2. Add a relative symlink from each env: `ln -s ../../../../shared/zellij/themes/<name>.kdl <env-repo>/config/zellij/themes/<name>.kdl`.
3. Update the mapping table above with the new row.
4. Commit (one row per work unit is fine; group related additions into the same commit).

## Procedure for adding a new wasm plugin

Same as the layout/theme procedure, but under `shared/zellij/plugins/<name>.wasm`. Wasm plugins are binary; verify md5 after the move to confirm no silent corruption.
