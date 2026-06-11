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

Configuration files use consistent section headers with minimal comments.

```txt
# ------------------------------------------------------------------------------
# Section Name
# ------------------------------------------------------------------------------
```

Rules:

- Use clear section names.
- Keep comments minimal.
- Prefer organizing by purpose over by tool internals.
- Avoid auto generated noise when a cleaner source version can be maintained.

## Documentation

Documentation belongs in `docs/`, not inside `config/`, unless the file is part of the tool's native
config format.

Use docs for:

- keybinding references
- setup notes
- workflow explanations
- repo-level conventions

## Doc Style Guide

All docs in this repo follow a rigid skeleton for consistency. Three categories exist:

1. **Runbook** — step-by-step restoration or operational procedure. Lives in the per-environment `README.md` (`wsl2-fedora/README.md` and `omarchy/README.md`), under a "Setup on a new machine" section. Not in `docs/`.
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

- H1 always in the form `<Tool> <Type>`.
- Opening paragraph is always 1-3 sentences: what it covers, where the file lives, one key fact.
- `Quick Path` is mandatory in root docs (3-5 numbered steps, high level).
- Tables over prose for any reference content. Use `| Action | Shortcut |` or `| File | Purpose |` style.
- `Notes` section at the end (bullets, gotchas).
- `Related Files` at the bottom: paths to source files and links to related docs.
- Code blocks only in `setup.md` (bash) and `conventions.md` (template example). Tool docs are tables.
- Grouped subdocs (e.g. `nvim/`) are deliberately minimal: pure keybinding tables.

### Cross-linking

- The environment's `README.md` is the entry point with two tables: tool→doc mapping and a doc index.
- Hub-and-spoke for grouped tools (e.g. `nvim.md` → `nvim/normal-mode.md`): the parent doc lists subdocs in a "Reference Pages" table.
- Per-environment tool docs (e.g. `docs/git.md`, `docs/ssh.md`, `docs/wezterm.md`) link to their env's `README.md#setup-on-a-new-machine` from `Related Files` for restoration context.
- Links are explicit and one-directional. No orphan docs.

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

## Current Decisions

| Topic                 | Decision                                                             |
| --------------------- | -------------------------------------------------------------------- |
| Zsh comments          | Uniform section headers with minimal comments                        |
| Starship organization | Keep behavior intact, group modules by category                      |
| Zellij keybindings    | `Alt-first`; `Ctrl g` opens `Normal`, and actions return to `locked` |
| Zellij binaries       | Version the `.wasm` plugins used by `config/zellij/config.kdl`       |
