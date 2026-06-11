# Zellij Keybindings

This repo uses an `Alt-first` Zellij setup. Pane actions use `Alt Shift`, tab actions use
`Alt Ctrl`, and focus uses `Alt` + arrows. `Ctrl g` opens the normal command menu and actions
return to `locked` mode so Zellij does not keep intercepting terminal input.

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

## Plugins

The Zellij plugin binaries are versioned in this repo under `config/zellij/plugins/`:

- `zellij_forgot.wasm`
- `zjframes.wasm`
- `zjstatus.wasm`

Copying `config/zellij/` into `~/.config/zellij/` installs both the config and the plugin binaries.

## Related Files

- `config/zellij/config.kdl`
- `config/zellij/plugins/README.md`
- `config/zellij/layouts/autanasoft.kdl`
- `config/zellij/themes/tokyo-night.kdl`
