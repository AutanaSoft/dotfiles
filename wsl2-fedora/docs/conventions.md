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
