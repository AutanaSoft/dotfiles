# Neovim Quick Reference

This setup uses `LazyVim` with a mostly stock configuration. The base config is shared via
`shared/nvim/` (omarchy-canonical); each env adds its own plugins. Each page below covers a
specific mode or tool. See [`docs/shared-layer.md`](shared-layer.md) for the shared mapping.

## Quick Path

1. Press `Esc` to return to normal mode.
1. Use `Space e` to open or close the file explorer.
1. Use `Ctrl+h/j/k/l` to move between windows.
1. Use `Shift+h` and `Shift+l` to switch buffers.
1. Use `Ctrl+s` to save.

## Quick Reference

The 25 keys that cover ~90% of daily editing. For full reference, see the subdocs.

### Movement & Edit

| Action | Shortcut |
| --- | --- |
| Move | `h` `j` `k` `l` |
| Word forward / back | `w` / `b` |
| Line start / end | `0` / `$` |
| File start / end | `gg` / `G` |
| Insert / append | `i` / `a` |
| New line below / above | `o` / `O` |
| Delete line | `dd` |
| Copy / paste | `yy` / `p` |
| Undo / redo | `u` / `Ctrl+r` |

### Navigation

| Action | Shortcut |
| --- | --- |
| Search | `/` then `n` / `N` |
| Find files | `Space ff` |
| Live grep | `Space /` |
| File explorer | `Space e` |
| Previous / next buffer | `Shift+h` / `Shift+l` |
| Move window | `Ctrl+h` `j` `k` `l` |

### Save & Quit

| Action | Shortcut |
| --- | --- |
| Save | `Ctrl+s` |
| Quit / save and quit | `:q` / `:wq` |

### Code (LSP)

| Action | Shortcut |
| --- | --- |
| Go to definition | `gd` |
| Find references | `gr` |
| Hover docs | `K` |
| Code actions | `Space ca` |
| Rename symbol | `Space cr` |

### Project-specific

| Action | Shortcut |
| --- | --- |
| Toggle spelllang `es/en` | `Space sp` |
| Open Lazygit | `Space gg` |
| Ask opencode | `Space oa` |

## Modes

| Mode | How to Enter | Purpose |
| --- | --- | --- |
| Normal | `Esc` from any other mode | Move, delete, copy, run commands |
| Insert | `i`, `a`, `o`, `O` | Write text |
| Visual | `v`, `V`, `Ctrl+v` | Select text to operate on |

## Reference Pages

| Page | Content |
| --- | --- |
| [Normal Mode](nvim/normal-mode.md) | Full normal-mode reference (movement, edit, search, windows, buffers, LSP) |
| [Insert Mode](nvim/insert-mode.md) | Quick edits while typing, `Ctrl+o` trick |
| [Visual Mode](nvim/visual-mode.md) | Selection types, operations, text objects |
| [Explorer](nvim/explorer.md) | File tree navigation and file operations (snacks.nvim) |
| [Lazygit](nvim/lazygit.md) | Git operations inside Neovim |
| [OpenCode](nvim/opencode.md) | OpenCode CLI integration via `opencode.nvim` |

## Notes

- This setup uses `LazyVim`.
- The project explorer is provided by `snacks.nvim`.
- If something feels wrong, press `Esc` first.

## Related Files

All plugin specs live in `shared/nvim/lua/plugins/`. Each env's `lua/plugins/` is a mirror of
symlinks to the shared files (lazy.nvim discovers plugins via `{ import = "plugins" }`, so the
symlinks make shared files appear in the per-env plugin directory).

- `shared/nvim/lua/config/options.lua` — shared options + the one custom keymap (`Space sp`)
- `shared/nvim/lua/config/keymaps.lua` — empty by design (LazyVim provides defaults)
- `shared/nvim/lua/config/lazy.lua`, `autocmds.lua` — shared lazy/autocmd config
- `shared/nvim/lua/plugins/opencode.lua` — opencode.nvim keymaps (`<Space>oa/oo/or/ol/ou/od`)
- `shared/nvim/lua/plugins/theme.lua` — tokyonight colorscheme spec
- `shared/nvim/lua/plugins/theme-hotreload.lua` — theme hot-reload on `LazyReload`
- `shared/nvim/lua/plugins/all-themes.lua` — preloads all theme plugins for hot-reload
- `shared/nvim/lua/plugins/editorconfig.lua` — `.editorconfig` support
- `shared/nvim/lua/plugins/conform-mdformat.lua` — mdformat as markdown formatter
- `shared/nvim/lua/plugins/snacks-animated-scrolling-off.lua` — disables snacks scroll animations
- `shared/nvim/lua/plugins/nvim-lint-config.lua` — wires nvim-lint to the shared lint config
- `shared/nvim/lua/plugins/disable-news-alert.lua` — disables LazyVim/Neovim news popups
- `omarchy/config/nvim/lua/plugins/`, `wsl2-fedora/config/nvim/lua/plugins/` — per-env symlink mirrors of the above
