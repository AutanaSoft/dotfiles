# Repository Conventions

Single source of truth for repo formatting and documentation style. All
contributors (humans and AI) follow these rules.

## Quick Path

1. Put `$HOME` files under `src/home/`, `~/.config` files under `src/home/config/`.
1. Apply the formatting table below.
1. Use [`docs/skeletons.md`](skeletons.md) for any new doc.

## Repo layout

| Path | Purpose |
| --- | --- |
| `src/home/` | Files that live directly in `$HOME` (e.g. `.bashrc`, `.ssh/`) |
| `src/home/config/` | Files and folders that map to `$HOME/.config/<app>/` |
| `src/home/local/bin/` | Personal executable scripts (manual only) |
| `src/etc/` | Files that flow to `/etc/` (system-managed, sudo install) |
| `src/utils/bash/` | Setup helpers dispatched by the root `./setup` entrypoint |
| `docs/` | Guides, conventions, and operational notes |

## Formatting

| File type | Indentation |
| --- | --- |
| Default | 2 spaces |
| KDL, Shell, Hyprland `.conf` | 4 spaces |
| Markdown | Exempt from trailing whitespace trimming |

These rules are also encoded in [`.editorconfig`](../.editorconfig).

## Configuration files

Use consistent section headers in config files:

```txt
# ------------------------------------------------------------------------------
# Section Name
# ------------------------------------------------------------------------------
```

Comment out removed content with `# Reason:` instead of deleting.

## Change workflow

1. Edit the file in the repo. The symlink makes the change visible to the
   live system immediately.
1. Reload the affected service:
   - Hyprland: `hyprctl reload` then `hyprctl configerrors` (must be empty).
   - Zellij: close and reopen the session, or `zellij -l <layout>`.
   - Neovim: restart, or `:Lazy reload` for a single plugin.
1. Validate that no configuration errors were reported.

## Documentation

Three doc categories, each with a fixed role and location:

1. **Runbook** — step-by-step restoration procedure. Lives in the per-env
   `README.md` (`src/README.md`) under "Setup on a new machine".
   Not in `docs/`.
1. **Conventions** — repo rules and current decisions. This file.
1. **Reference** — looks up decisions taken in this repo, not tool tutorials.

### Hard rules

- **H1 format**: always `<Tool> <Type>`, with a 1-3 sentence opening
  paragraph (what it covers, where the file lives, one key fact).
- **Root docs must have** `Quick Path` (3-5 steps, high level), `Notes`
  (bullets, gotchas), and `Related Files` (source paths + linked docs).
  `AGENTS.md` is exempt; it is an execution contract, not a user guide.
- **Tables over prose** for any reference content.
- **Code blocks only** in setup docs (bash) and `docs/skeletons.md` (templates).
  Tool docs are tables.
- **Subdocs are minimal**: use the grouped, quick-reference, or plugin shape
  from [`docs/skeletons.md`](skeletons.md). Do not repeat related links unless
  the subdoc is meant to be a standalone quick reference.

### Cross-linking

- The per-env `README.md` (`src/README.md`) is the doc index for that env:
  tool→doc mapping and doc index.
- Hub-and-spoke for grouped tools (e.g. `nvim.md` → `nvim/normal-mode.md`):
  the parent doc lists subdocs in a "Reference Pages" table.

### Length budgets

- Root docs: 30-120 lines. Runbooks run longer.
- Grouped subdocs: 20-150 lines. Dense table dumps are fine.
- A new root doc exceeding ~120 lines should be split into parent + subdocs.

## Source of truth

| Type | Source of truth |
| --- | --- |
| Active shell dotfiles | `src/home/` |
| Tool configs under `.config` | `src/home/config/` |
| System-level configs (root-installed) | `src/etc/` |
| Human-readable guidance | `docs/` |
| Env executor (Omarchy flow) | `src/utils/bash/setup-dots` |
