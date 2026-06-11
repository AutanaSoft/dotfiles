# Visual Mode

Visual mode lets you select text first, then apply an operation to the selection.

## Selection Types

| Action | Shortcut |
| --- | --- |
| Character-wise selection | `v` |
| Line-wise selection | `V` |
| Block (column) selection | `Ctrl+v` |

## Operations on Selection

Once text is selected, press one of these:

| Action | Shortcut |
| --- | --- |
| Delete | `d` |
| Copy (yank) | `y` |
| Change (replace with typed text) | `c` |
| Replace with paste | `p` |
| Indent right | `>` |
| Indent left | `<` |
| Toggle case | `~` |
| Uppercase | `U` |
| Lowercase | `u` |
| Move selection down / up | `Alt+j` / `Alt+k` |
| Comment / toggle selection | `gc` |
| Format selection | `Space cf` |

## Navigating Inside a Selection

| Action | Shortcut |
| --- | --- |
| Move to other end of selection | `o` |
| Move to other corner (block) | `O` |
| Reselect last visual selection | `gv` |
| Re-indent and re-select | `>` / `<` (with `gv`) |

## Selecting Text Objects (from Normal Mode)

Prefix any of these with `v` to enter visual mode with the selection active.

| Action | Shortcut |
| --- | --- |
| Select current word | `viw` |
| Select inside parens | `vi(` |
| Select inside braces | `vi{` |
| Select inside brackets | `vi[` |
| Select inside quotes | `vi"` / `vi'` / `` vi` `` |
| Select entire paragraph | `vip` (inner) / `vap` (around) |
| Select around parens / braces | `va(` / `va{` |
| Select around quotes | `va"` |
| Select to end of line | `v$` |
| Select to start of line | `v0` |
| Select inside HTML / XML tag | `vit` / `vat` (treesitter) |
| Select inside function | `vif` / `vaf` (treesitter) |
| Select inside class | `vic` / `vac` (treesitter) |
| Select inside conditional / loop | `vi?` / `va?` (treesitter) |

## Multi-Cursor from Visual

From any visual selection, `Ctrl+n` adds a cursor on the next match. See
[normal-mode.md#multi-cursor-vim-visual-multi](normal-mode.md#multi-cursor-vim-visual-multi)
for the full keymap.
