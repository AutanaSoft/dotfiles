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

## Selecting Text Objects (from Normal Mode)

Prefix any of these with `v` to enter visual mode with the selection active.

| Action | Shortcut |
| --- | --- |
| Select current word | `viw` |
| Select inside braces | `vi{` or `vi(` |
| Select inside quotes | `vi"` |
| Select entire paragraph | `vip` or `vap` |
| Select around braces | `va{` or `va(` |
| Select around quotes | `va"` |
| Select to end of line | `v$` |
| Select to start of line | `v0` |
