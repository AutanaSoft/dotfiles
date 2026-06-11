# Neovim Keybindings

The keybindings you actually use day-to-day. Dense, opinionated shortcut to LazyVim
defaults. For the complete per-mode reference, see the subdocs in
[`docs/nvim/`](nvim/).

## Quick Path

1. Press `Esc` to return to normal mode.
1. Move with `h j k l`, `w` `b`, `0` `$`; operators (`d` / `c` / `y`) compose with motions.
1. `Alt+j` / `Alt+k` moves lines in n / v / i. `Ctrl+n` adds multi-cursors.
1. `.` repeats the last change. `u` / `Ctrl+r` undoes / redoes.

## Movement

| Action | Shortcut |
| --- | --- |
| Left / down / up / right | `h` `j` `k` `l` |
| Word forward / back / end | `w` / `b` / `e` |
| Start / end of line | `0` / `$` |
| First / last non-blank | `^` / `g_` |
| File start / end | `gg` / `G` |
| Half-page down / up | `Ctrl+d` / `Ctrl+u` |
| Paragraph up / down | `{` / `}` |
| Jump to char forward / back | `f<char>` / `F<char>` |
| Jump up to char | `t<char>` / `T<char>` |
| Repeat last `f` / `t` (next / prev) | `;` / `,` |
| Next / prev word under cursor | `*` / `#` |
| Jump to matching bracket | `%` |

## Edit

| Action | Shortcut |
| --- | --- |
| Delete line | `dd` |
| Copy (yank) line | `yy` |
| Paste after / before | `p` / `P` |
| Delete to end of line | `D` |
| Delete character | `x` |
| Join line below to current | `J` |
| Undo / redo | `u` / `Ctrl+r` |
| Repeat last change | `.` |

## Move Lines (n / v / i)

| Action | Shortcut |
| --- | --- |
| Move line down / up | `Alt+j` / `Alt+k` |
| Move visual selection down / up | `Alt+j` / `Alt+k` |
| Move line and stay in insert | `Alt+j` / `Alt+k` (insert mode) |
| Move N lines at once | `3 Alt+j` (works in n / v) |
| Duplicate current line | `yyp` |

## Text Objects

Operators (`d` / `c` / `y`) and visual (`v` + object) use the same objects. `i` = inner,
`a` = around (includes delimiters and trailing space).

| Action | Shortcut |
| --- | --- |
| Word | `iw` / `aw` |
| Parens / braces / brackets | `i(` / `i{` / `i[` |
| Quotes (double / single / back) | `i"` / `i'` / `` i` `` |
| Paragraph | `ip` / `ap` |
| Function (treesitter) | `if` / `af` |
| Class (treesitter) | `ic` / `ac` |
| HTML / XML tag (treesitter) | `it` / `at` |

## Multi-Cursor (vim-visual-multi)

| Action | Shortcut |
| --- | --- |
| Add cursor on next match of word under cursor | `Ctrl+n` |
| Add cursor on previous match | `Ctrl+x` |
| Skip current match (don't add cursor) | `Ctrl+n` (again) |
| Move to next / previous cursor | `]n` / `[n` |
| Remove current / last cursor | `q` / `Q` |

## LSP

| Action | Shortcut |
| --- | --- |
| Go to definition | `gd` |
| Show references | `gr` |
| Hover (documentation) | `K` |
| Code actions | `Space ca` |
| Rename symbol | `Space cr` |
| Format buffer / selection | `Space cf` |
| Next / previous diagnostic | `]d` / `[d` |
| Toggle comment (n / v) | `gcc` / `gc` |

## VSCode Equivalents

| VSCode | Neovim |
| --- | --- |
| `Ctrl+Shift+Up/Down` move line | `Alt+j` / `Alt+k` |
| `Ctrl+D` add next match | `Ctrl+n` |
| `Alt+click` multi-cursor | `Ctrl+n` from selection |
| `Ctrl+/` toggle comment | `gcc` (n) / `gc` (v) |
| `Shift+Alt+F` format | `Space cf` |
| `F12` go to definition | `gd` |
| `Ctrl+Shift+P` command palette | `Space` (which-key) |

## Notes

- `Alt+j` / `Alt+k` requires the terminal to send `Alt` to Neovim. Alacritty, Foot, and
  WezTerm do this by default. If it doesn't work, remap to `<C-A-j>` / `<C-A-k>` in
  `shared/nvim/lua/config/keymaps.lua`.
- Operators compose: `d2w` deletes two words, `c3j` changes three lines down, `yap`
  yanks a paragraph.
- `vip` selects a paragraph; `dap` deletes it. Fastest way to refactor blocks.
- Treesitter text objects (`if` / `ic` / `it`) require a language parser installed for
  the buffer filetype. LazyVim installs them by default for common languages.

## Related Files

- [docs/nvim.md](nvim.md) — entry point and minimal quick-reference
- [docs/nvim/normal-mode.md](nvim/normal-mode.md) — full normal-mode reference
- [docs/nvim/insert-mode.md](nvim/insert-mode.md) — full insert-mode reference
- [docs/nvim/visual-mode.md](nvim/visual-mode.md) — full visual-mode reference
- [shared/nvim/lua/config/keymaps.lua](../shared/nvim/lua/config/keymaps.lua) — custom keymap overrides
