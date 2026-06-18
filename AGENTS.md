# AGENTS.md — Dotfiles Autanasoft

Repo rules for AI agents and contributors. Keep this file focused on
execution rules; full repo docs live in [`README.md`](README.md) and
[`docs/conventions.md`](docs/conventions.md).

## Repository Purpose

Personal dotfiles for Omarchy-family hosts (stock Omarchy, CachyOS with
Omarchy layered on top, Arch with Omarchy layered on top). Distribution-
specific configuration is owned by the Omarchy installer; this repo's only
AUR-helper concern is `yay`.

| Environment | Main stack |
| --- | --- |
| **Omarchy** (Arch + Hyprland) | Hyprland, Alacritty, Zellij, nvim, Mako, Waybar |

The repo is the source of truth. Live files are symlinks; edit the repo
and reload the affected service. Layout, setup, and policy:
[`README.md`](README.md).

## Applied Conventions

### Organization

| Rule | Details |
| --- | --- |
| `p-` prefix (Hyprland) | Personal files that survive `omarchy update` |
| Canonical source | `src/home/config/` is the only tracked config tree |
| Removal policy | Comment out with `# Reason:` instead of deleting |
| Setup entrypoint | Root: `./setup`. Env executors: `src/utils/bash/<name>` |
| Sensitive SSH | `src/home/.ssh/*` is gitignored except for the safe `config` template |

### Formatting

| File type | Indentation |
| --- | --- |
| Default | 2 spaces |
| KDL, Shell, Hyprland `.conf` | 4 spaces |
| Markdown | Exempt from trailing whitespace trimming |

Source of truth: [`docs/conventions.md`](docs/conventions.md#formatting).

### Main tools

Canonical source in `src/home/config/`: Zellij, Neovim +
LazyVim, Starship, opencode.nvim, Hyprland (`p-` prefix), Alacritty,
Waybar, Mako.

## Forbidden Paths

System-managed or per-host — never edit, never commit:

- `~/.local/share/omarchy/` — managed by omarchy
- SSH private keys, `known_hosts`, machine-specific tokens
- Hyprland / Mako / Waybar / Walker configs that are pure omarchy
  defaults (only the per-host overrides in `src/home/config/` are
  tracked; the rest stay at the omarchy default)

Full list: [`docs/shared-layer.md`](docs/shared-layer.md#forbidden-content).

## Communication Rules

### Language

- Reply to the developer in neutral Latin American Spanish (no voseo, no regional slang).
- Technical artifacts (code, identifiers, comments, docs) in English unless the user requests otherwise.

### Execution

1. Do not commit, push, or PR without explicit request.
1. Clarify requirements before executing when in doubt.
1. Verify technical claims before stating them. If the developer is wrong, explain why with evidence.

### Response format

- Short by default. Expand only when the task requires it.
- One question at a time. Wait for the answer before continuing.
