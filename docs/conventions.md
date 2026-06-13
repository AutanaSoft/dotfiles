# Repository Conventions

This repo stores personal dotfiles in a predictable structure with minimal, consistent
documentation.

## Quick Path

1. Put files that live in `~` under `home/`.
2. Put files that live in `~/.config` under `config/`.
3. Put guides, notes, and usage references under `docs/`.

## Structure

| Path      | Purpose                                       |
| --------- | --------------------------------------------- |
| `home/`   | Files that live directly in `$HOME`           |
| `config/` | Files and folders that map to `$HOME/.config` |
| `bin/`    | Personal executable scripts                   |
| `docs/`   | Guides, conventions, and operational notes    |

## Configuration Files

Configuration files use consistent section headers:

```txt
# ------------------------------------------------------------------------------
# Section Name
# ------------------------------------------------------------------------------
```

## Documentation

Documentation belongs in `docs/`, not inside `config/`, unless the file is part of
the tool's native config format.

## Doc Style Guide

All docs in this repo follow a rigid skeleton for consistency. Three categories exist:

1. **Runbook** — step-by-step restoration or operational procedure. Lives in the per-environment `README.md` (`fedora/README.md` and `omarchy/README.md`), under a "Setup on a new machine" section. Not in `docs/`.
2. **Conventions** — repo rules and current decisions log. This file.
3. **Reference** — looks up specific decisions taken in this repo, not the tool in general. Not a tutorial.

### Skeleton for root docs

```txt
# <Tool> <Type>          (Type: Guide | Reference | Keybindings | Quick Reference)
<1-3 sentences: what it covers, where the file lives, one key fact>

## Quick Path
1. step
2. step
3-5 items max

## <Section 1>           (File / Model / Behavior / etc.)
(table | Action | Shortcut |)

## <Section 2>
(table or list)

## Notes
- gotcha
- gotcha

## Related Files
- path/to/file
- docs/other-doc.md
```

### Skeleton for grouped subdocs (e.g. `nvim/`)

Pure keybinding reference. No intro paragraph, no Quick Path, no Related Files.

```txt
# <Mode or Tool Name>
<one-sentence opener: what this is, how to enter it>

## <Category 1>
(table | Action | Shortcut |)

## <Category 2>
(table)
```

### Hard rules

- **H1 format**: always `<Tool> <Type>`, with a 1-3 sentence opening paragraph
  (what it covers, where the file lives, one key fact).
- **Root doc sections**: `Quick Path` (3-5 steps, high level), `Notes` (bullets,
  gotchas), and `Related Files` (paths to source files + links to related docs)
  are mandatory.
- **Tables over prose**: use `| Action | Shortcut |` or `| File | Purpose |`
  style for any reference content.
- **Code blocks scope**: only in `setup.md` (bash) and `conventions.md` (this
  template). Tool docs are tables.
- **Grouped subdocs are minimal**: pure keybinding tables, no intro, no
  `Quick Path`, no `Related Files`.

### Cross-linking

- The environment's `README.md` is the entry point with two tables: tool→doc
  mapping and a doc index.
- Hub-and-spoke for grouped tools (e.g. `nvim.md` → `nvim/normal-mode.md`): the
  parent doc lists subdocs in a "Reference Pages" table.

### Length budgets

- Root docs: 30-120 lines. Runbooks run longer.
- Grouped subdocs: 20-150 lines. Dense table dumps are fine for keybinding references.
- A new root doc exceeding ~120 lines should be split into a parent + subdocs.

## Source Of Truth

| Type                         | Source of truth |
| ---------------------------- | --------------- |
| Active shell dotfiles        | `home/`         |
| Tool configs under `.config` | `config/`       |
| Human-readable guidance      | `docs/`         |
