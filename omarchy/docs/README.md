# Omarchy Dotfiles

This directory stores the user-managed Omarchy configuration tracked by this repository.

## Quick path

1. Edit files in this repository first.
2. Link the real user paths to the repo-managed files with symlinks.
3. Reload or restart the affected component to apply the change.

## Scope

| Area | Rule |
|------|------|
| Source of truth | The repository is the source of truth for user-managed Omarchy files. |
| Allowed changes | Change only user-level configuration files and user-level commands. |
| Forbidden changes | Do not modify system files or Omarchy source files under `~/.local/share/omarchy/`. |
| Removal policy | Do not delete existing configuration when deactivating behavior; comment it and explain why. |
| Home mapping | `home/` in this repo maps to `~/.` in the user environment. |
| Repo layout | `config/` in this repo maps to `~/.config/` in the user environment. |

## Current structure

- `home/` — files that map to `~/` with their original dotfile names
- `bin/` — user-level helper commands managed by the repo
- `config/` — files that map to `~/.config/`
- `docs/` — repository documentation for Omarchy-specific workflow and decisions

## Working rule

Prefer small, explicit changes. Keep configuration in tracked files, then expose it to the live system through symlinks.
