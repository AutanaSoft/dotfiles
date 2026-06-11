# Zellij Keybindings

This repo uses an `Alt-first` Zellij setup. Pane actions use `Alt Shift`, tab actions use
`Alt Ctrl`, and focus uses `Alt` + arrows. `Ctrl g` opens the normal command menu and actions
return to `locked` mode so Zellij does not keep intercepting terminal input.

The Zellij config is shared across `omarchy/` and `wsl2-fedora/` via `shared/zellij/`
(omarchy-canonical). See the [Symlink chain](#symlink-chain) section below and
[`docs/shared-layer.md`](shared-layer.md) for the full mapping.

## Quick Path

1. Press `Ctrl g` to leave `locked` mode and open `Normal` mode.
2. From `Normal`, press a single mode key like `p`, `t`, `n`, `h`, `s`, or `o`.
3. Press `Esc` or `Enter` to return to `locked` mode.
4. Use `Alt` + arrows for focus, `Alt Shift` for panes, and `Alt Ctrl` for tabs without opening the mode menu.
5. Press `Alt y` inside Zellij to open the shortcut helper.

## Core Model

| Action                               | Shortcut         |
| ------------------------------------ | ---------------- |
| Enter `Normal` from `locked`         | `Ctrl g`         |
| Return to `locked` from active modes | `Esc` or `Enter` |
| Show shortcut helper                 | `Alt y`          |

Only the `locked` mode `Ctrl g` binding switches to `Normal`. Other actions return to `locked` after
they run.

## Normal Mode Menu

After pressing `Ctrl g`, these keys select Zellij modes from `Normal` only:

| Mode    | Shortcut |
| ------- | -------- |
| Pane    | `p`      |
| Tab     | `t`      |
| Resize  | `n`      |
| Move    | `h`      |
| Scroll  | `s`      |
| Session | `o`      |
| Tmux    | `Ctrl b` |

## Direct Alt Shortcuts

These shortcuts work in both `locked` and `normal` mode.

| Action                        | Shortcut                        |
| ----------------------------- | ------------------------------- |
| New pane                      | `Alt Shift n`                   |
| Close focused pane            | `Alt Shift x`                   |
| Toggle floating panes         | `Alt Shift f`                   |
| Focus pane left/down/up/right | `Alt` + arrows                  |
| Move pane left/down/up/right  | `Alt Shift` + arrows            |
| Resize pane left              | `Alt +` or `Alt =`              |
| Resize pane right             | `Alt -`                         |
| New tab                       | `Alt Ctrl t`                    |
| Focus previous or next tab    | `Alt Ctrl Left/Right`           |
| Previous or next layout       | `Alt [` / `Alt ]`               |
| Toggle pane group             | `Alt Shift g`                   |
| Toggle group marking          | `Alt Shift m`                   |

## Helper Popup

`Alt y` launches `zellij_forgot.wasm` and shows the current direct shortcuts.

The helper disables automatic Zellij keybind loading with `LOAD_ZELLIJ_BINDINGS=false`; otherwise
the plugin includes every default binding and the popup can wrap entries into two lines.

## Symlink chain

The Zellij config and assets are shared via relative symlinks:

- **Canonical source**: `shared/zellij/` (omarchy-wins rule).
- **Per-env access**: each env exposes the shared files through a relative symlink:
  - `omarchy/config/zellij/` → `../../shared/zellij/`
  - `wsl2-fedora/config/zellij/` → `../../shared/zellij/`
- **Live resolution**: `~/.config/zellij/...` → per-env path → `shared/zellij/...`.

The canonical source rule and the full env-to-shared mapping live in
[`docs/shared-layer.md`](shared-layer.md).

## Plugins

The Zellij plugin binaries live in `shared/zellij/plugins/` (canonical) and are exposed in
each env via the per-env symlink:

- `zellij_forgot.wasm`
- `zjframes.wasm`
- `zjstatus.wasm`

The symlink chain (`~/.config/zellij/plugins/` → per-env → `shared/zellij/plugins/`) installs
both the config and the plugin binaries — no copy step needed.

## Maintenance

### Adding a theme or layout

1. Drop the new file in the appropriate subdirectory: `shared/zellij/themes/<name>.kdl` or
   `shared/zellij/layouts/<name>.kdl`.
2. Add a relative symlink from each env: `ln -s ../../../../shared/zellij/themes/<name>.kdl
   <env-repo>/config/zellij/themes/<name>.kdl`.
3. Update the mapping table in [`docs/shared-layer.md`](shared-layer.md) with the new row.
4. Commit (one row per work unit is fine; group related additions into the same commit).

### Adding a wasm plugin

Same as the layout/theme procedure, but under `shared/zellij/plugins/<name>.wasm`. Wasm plugins
are binary; verify md5 after the move to confirm no silent corruption.

## Related Files

- `shared/zellij/config.kdl` (canonical) → `omarchy/config/zellij/config.kdl` and `wsl2-fedora/config/zellij/config.kdl`
- `shared/zellij/layouts/autanasoft.kdl` → `omarchy/config/zellij/layouts/autanasoft.kdl` and `wsl2-fedora/config/zellij/layouts/autanasoft.kdl`
- `shared/zellij/themes/tokyo-night.kdl` → `omarchy/config/zellij/themes/tokyo-night.kdl` and `wsl2-fedora/config/zellij/themes/tokyo-night.kdl`
- `shared/zellij/plugins/{zellij_forgot,zjframes,zjstatus}.wasm` → per-env plugins folders
- See [`docs/shared-layer.md`](shared-layer.md) for the full env-to-shared mapping.
