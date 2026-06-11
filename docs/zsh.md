# Zsh Guide

This shell setup uses `zsh` with `starship`, `mise`, and an automatic `zellij` entrypoint. The `zsh-autosuggestions` and `zsh-syntax-highlighting` plugins are loaded directly from the Fedora packages.

## Quick Path

1. Open a new shell.
2. If `zellij` is installed and you are not already inside a session, the shell enters `zellij` automatically.
3. Use the short aliases for common commands.
4. Keep edits in `home/.zshrc` and `home/.zshenv`.

## Files

| File | Purpose |
| --- | --- |
| `home/.zshrc` | Interactive shell behavior |
| `home/.zshenv` | Locale setup |

## What This Config Does

| Area | Behavior |
| --- | --- |
| Shell guard | Exits early for non-interactive shells |
| Homebrew | Adds Linuxbrew paths |
| Zellij | Starts `zellij` automatically in local interactive shells |
| Zsh Plugins | Loads `zsh-autosuggestions` and `zsh-syntax-highlighting` from `/usr/share/...` after the prompt |
| Runtime | Activates `mise` if present |
| Prompt | Initializes `starship` if present |
| Terminal | Disables flow control so `Ctrl+s` works normally |

## Main Aliases

| Alias | Command |
| --- | --- |
| `op` | `opencode` |
| `n` | `nvim` |
| `cl` | `clear` |
| `ls` | `eza -lh --icons=auto` |
| `ll` | `eza -lah --icons=auto --group-directories-first` |
| `la` | `eza -a --icons=auto --group-directories-first` |
| `tree` | `eza --tree --icons=auto --group-directories-first` |

## Notes

- `home/.zshenv` sets `LANG` and `LC_ALL` to `es_VE.UTF-8`.
- `zellij` only autostarts when not already inside `zellij` and not in an SSH session.
- `eza` must be installed for the file listing aliases to work.

## Related Files

- `home/.zshrc`
- `home/.zshenv`
- `config/starship.toml`
- `config/zellij/config.kdl`
