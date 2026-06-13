# Repository Conventions

Single source of truth for repo formatting and documentation style. All
contributors (humans and AI) follow these rules.

## Quick Path

1. Put `$HOME` files under `home/`, `~/.config` files under `config/`.
1. Apply the formatting table below.
1. Use [`docs/skeletons.md`](skeletons.md) for any new doc.

## Repo layout

| Path | Purpose |
| --- | --- |
| `home/` | Files that live directly in `$HOME` |
| `config/` | Files and folders that map to `$HOME/.config` |
| `bin/` | Personal executable scripts |
| `docs/` | Guides, conventions, and operational notes |
| `shared/` | Canonical configs valid for both environments |
| `scripts/` | Env executors dispatched by the root `./setup` entrypoint |

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
   `README.md` (`fedora/README.md`, `omarchy/README.md`) under "Setup on a
   new machine". Not in `docs/`.
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

- Each env `README.md` is the doc index for that env: tool→doc mapping and
  doc index.
- Hub-and-spoke for grouped tools (e.g. `nvim.md` → `nvim/normal-mode.md`):
  the parent doc lists subdocs in a "Reference Pages" table.

### Length budgets

- Root docs: 30-120 lines. Runbooks run longer.
- Grouped subdocs: 20-150 lines. Dense table dumps are fine.
- A new root doc exceeding ~120 lines should be split into parent + subdocs.

## Source of truth

| Type | Source of truth |
| --- | --- |
| Active shell dotfiles | `home/` |
| Tool configs under `.config` | `config/` |
| Human-readable guidance | `docs/` |
| Cross-env canonical config | `shared/` (see [`docs/shared-layer.md`](shared-layer.md)) |
