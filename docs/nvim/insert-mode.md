# Insert Mode

Insert mode is where you type text. You enter it from Normal mode with `i`, `a`, `o`, `O`, `I`, or `A`.

## Quick Edits While Typing

| Action | Shortcut |
| --- | --- |
| Return to normal mode | `Esc` |
| Delete word backward | `Ctrl+w` |
| Delete to start of line | `Ctrl+u` |
| Move line down / up | `Alt+j` / `Alt+k` |
| Paste from register | `Ctrl+r` then register name (`"` for clipboard) |
| Paste from system clipboard | `Ctrl+r "` |

## Run a Normal-Mode Command Without Leaving Insert

`Ctrl+o` runs a single Normal-mode command and then returns to Insert mode. Useful for quick selections or deletes without fully leaving insert mode.

Examples:
- `Ctrl+o v i w` — select the current word
- `Ctrl+o d d` — delete the current line
- `Ctrl+o y y p` — copy the current line and paste it

## Completion

`Ctrl+x` enters a sub-mode with completion options. Useful variants:

| Action | Shortcut |
| --- | --- |
| Trigger completion | `Ctrl+x Ctrl+o` |
| Trigger filename completion | `Ctrl+x Ctrl+f` |
| Trigger line completion | `Ctrl+x Ctrl+l` |

LazyVim's `blink.cmp` is the default completion engine; the popup appears as you type
and is unrelated to the `Ctrl+x` sub-mode (but both work).
