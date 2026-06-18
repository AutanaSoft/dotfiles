# Zellij Keybindings

This repo uses an `Alt-first` Zellij setup: pane actions use `Alt Shift`, tab actions use
`Alt Ctrl`, focus uses `Alt` + arrows. Default mode is `locked`, so Zellij does not intercept
terminal input — `Ctrl g` opens the mode menu and most actions return to `locked` after they
run.

The config is canonical under `src/home/config/zellij/`. The symlink map is in
[`docs/shared-layer.md`](shared-layer.md).

## Quick Path

1. Press `Ctrl g` to enter `Normal` from `locked`.
1. Press a mode key — `p` (pane), `t` (tab), `n` (resize), `h` (move), `s` (scroll), `o`
   (session), `Ctrl b` (tmux) — and `Esc` or `Enter` to return to `locked`.
1. Skip the mode menu with the direct bindings below.
1. Press `Alt y` for the shortcut helper popup.

## Normal Mode Menu

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

`Alt y` launches `zellij_forgot.wasm` (from `src/home/config/zellij/plugins/`) and shows the current direct
shortcuts. The helper is configured with `LOAD_ZELLIJ_BINDINGS=false` so it does not bundle every
default binding.
