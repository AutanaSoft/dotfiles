# WezTerm Guide

This repo stores the Windows WezTerm config because it is part of the daily terminal workflow.

## Quick Path

1. Copy `home/.wezterm.lua` to your Windows home directory.
2. Restart WezTerm.
3. Adjust the default WSL domain if the machine name or distro changes.

## File

| File | Purpose |
| --- | --- |
| `home/.wezterm.lua` | Main WezTerm configuration |

## What This Config Does

| Area | Behavior |
| --- | --- |
| Default domain | Opens `WSL:Fedora` |
| Font | Uses `Monaspace Krypton NF` |
| Theme | Uses `Tokyo Night` |
| Window | Uses a translucent window with hidden tab bar when possible |
| Neovim support | Enables CSI-u key encoding and Kitty graphics |
| Keybinding | Releases `Alt+Enter` so terminal apps can receive it |

## Notes

- The real source config lives on Windows at `C:\Users\<user>\.wezterm.lua`.
- `AppData/Roaming/wezterm` and `AppData/Local/wezterm` were treated as runtime state, not dotfiles.

## Related Files

- `home/.wezterm.lua`
- `omarchy/README.md`
