# Neovim Quick Reference

This setup uses `LazyVim` with a mostly stock configuration. The canonical config lives in
`shared/nvim/`; Omarchy and WSL2 point to it through symlinks. Each page below covers a
specific mode or tool.

## Quick Path

1. Press `Esc` to return to normal mode.
1. Use `Space e` to open or close the file explorer.
1. Use `Ctrl+h/j/k/l` to move between windows.
1. Use `Shift+h` and `Shift+l` to switch buffers.
1. Use `Ctrl+s` to save.

## Quick Reference

The 25 keys that cover ~90% of daily editing. For full reference, see the subdocs.

### Movement & Edit

| Action                 | Shortcut        |
| ---------------------- | --------------- |
| Move                   | `h` `j` `k` `l` |
| Word forward / back    | `w` / `b`       |
| Line start / end       | `0` / `$`       |
| File start / end       | `gg` / `G`      |
| Insert / append        | `i` / `a`       |
| New line below / above | `o` / `O`       |
| Delete line            | `dd`            |
| Copy / paste           | `yy` / `p`      |
| Undo / redo            | `u` / `Ctrl+r`  |

### Navigation

| Action                 | Shortcut              |
| ---------------------- | --------------------- |
| Search                 | `/` then `n` / `N`    |
| Find files             | `Space ff`            |
| Live grep              | `Space /`             |
| File explorer          | `Space e`             |
| Previous / next buffer | `Shift+h` / `Shift+l` |
| Move window            | `Ctrl+h` `j` `k` `l`  |

### Save & Quit

| Action               | Shortcut     |
| -------------------- | ------------ |
| Save                 | `Ctrl+s`     |
| Quit / save and quit | `:q` / `:wq` |

### Code (LSP)

| Action           | Shortcut   |
| ---------------- | ---------- |
| Go to definition | `gd`       |
| Find references  | `gr`       |
| Hover docs       | `K`        |
| Code actions     | `Space ca` |
| Rename symbol    | `Space cr` |

### Project-specific

| Action                   | Shortcut   |
| ------------------------ | ---------- |
| Toggle spelllang `es/en` | `Space sp` |
| Open Lazygit             | `Space gg` |
| Ask opencode             | `Space oa` |

## Modes

| Mode   | How to Enter              | Purpose                          |
| ------ | ------------------------- | -------------------------------- |
| Normal | `Esc` from any other mode | Move, delete, copy, run commands |
| Insert | `i`, `a`, `o`, `O`        | Write text                       |
| Visual | `v`, `V`, `Ctrl+v`        | Select text to operate on        |

## Reference Pages

| Page                               | Content                                                                    |
| ---------------------------------- | -------------------------------------------------------------------------- |
| [Normal Mode](nvim/normal-mode.md) | Full normal-mode reference (movement, edit, search, windows, buffers, LSP) |
| [Insert Mode](nvim/insert-mode.md) | Quick edits while typing, `Ctrl+o` trick                                   |
| [Visual Mode](nvim/visual-mode.md) | Selection types, operations, text objects                                  |
| [Explorer](nvim/explorer.md)       | File tree navigation and file operations (snacks.nvim)                     |
| [Lazygit](nvim/lazygit.md)         | Git operations inside Neovim                                               |
| [OpenCode](nvim/opencode.md)       | OpenCode CLI integration via `opencode.nvim`                               |

## Formatting & Linting

LazyVim/Mason installs the editor tools from the enabled extras in `shared/nvim/lazyvim.json`.
Use `:Lazy sync` after changing plugins or extras.

| Type | Formatter | Diagnostics |
| --- | --- | --- |
| Markdown | `prettier` | `markdownlint-cli2` |
| TypeScript / JavaScript | `prettier` | ESLint LSP |
| Go | `goimports` + `gofumpt` | `golangci-lint` |

Manual fallback, only if the binaries are needed outside Neovim:

```sh
npm i -g prettier markdownlint-cli2 markdown-toc
```

## Notes

- This setup uses `LazyVim`.
- The project explorer is provided by `snacks.nvim`.
- If something feels wrong, press `Esc` first.

## Related Files

- `shared/nvim/` — canonical Neovim config for all environments.
- `shared/nvim/lazyvim.json` — enabled LazyVim extras.
- `shared/nvim/lazy-lock.json` — shared plugin lockfile.
- `shared/nvim/lua/plugins/` — plugin specs, one file per plugin or concern.
- `shared/nvim/lua/config/` — shared LazyVim config overrides.
- `shared/nvim/plugin/after/transparency.lua` — transparent highlight overrides.
- `docs/shared-layer.md` — symlink map for shared config.
