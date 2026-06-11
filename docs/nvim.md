# Neovim Quick Reference

This setup uses `LazyVim` with a mostly stock configuration. Each page covers a specific mode or tool.

## Quick Path

1. Press `Esc` to return to normal mode.
2. Use `Space e` to open or close the file explorer.
3. Use `Ctrl+h/j/k/l` to move between windows.
4. Use `Shift+h` and `Shift+l` to switch buffers.
5. Use `Ctrl+s` to save.

## Modes

| Mode | How to Enter | Purpose |
| --- | --- | --- |
| Normal | `Esc` from any other mode | Move, delete, copy, run commands |
| Insert | `i`, `a`, `o`, `O` | Write text |
| Visual | `v`, `V`, `Ctrl+v` | Select text to operate on |

## Reference Pages

| Page | Content |
| --- | --- |
| [Normal Mode](nvim/normal-mode.md) | Movement, editing, copy/paste, undo, search, windows, buffers, LSP |
| [Insert Mode](nvim/insert-mode.md) | Quick edits while typing, `Ctrl+o` trick |
| [Visual Mode](nvim/visual-mode.md) | Selection types, operations, text objects |
| [Explorer](nvim/explorer.md) | File tree navigation and file operations |
| [Lazygit](nvim/lazygit.md) | Git operations inside Neovim |

## Project-Specific Keys

| Action | Shortcut |
| --- | --- |
| Toggle spell priority `es/en` | `Space u e` |

## Notes

- This setup uses `LazyVim`.
- The project explorer is provided by `snacks.nvim`.
- If something feels wrong, press `Esc` first.
- A word (`iw` / `aw`) includes letters, digits, and underscores.
- `W` / `B` / `E` (uppercase) move by whitespace-delimited WORDs, ignoring punctuation.
- `ci"` means: **c**hange **i**nside **"**. Works with `(`, `{`, `[`, `<`, `'`, `` ` ``, and `t` (HTML tag).

## Related Files

- `config/nvim/init.lua`
- `config/nvim/lua/config/options.lua`
- `config/nvim/lua/config/keymaps.lua`
- `config/nvim/lua/config/autocmds.lua`
- `config/nvim/lua/config/lazy.lua`
- `config/nvim/lua/plugins/init.lua`
