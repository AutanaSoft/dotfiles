# Insert Mode

Insert mode is where you type text. You enter it from Normal mode with `i`, `a`, `o`, `O`, `I`, or `A`.

## Quick Edits While Typing

| Action | Shortcut |
| --- | --- |
| Return to normal mode | `Esc` |
| Delete word backward | `Ctrl+w` |
| Delete to start of line | `Ctrl+u` |
| Paste from register | `Ctrl+r` then register name (`"` for clipboard) |

## Run a Normal-Mode Command Without Leaving Insert

`Ctrl+o` runs a single Normal-mode command and then returns to Insert mode. Useful for quick selections or deletes without fully leaving insert mode.

Examples:
- `Ctrl+o v i w` — select the current word
- `Ctrl+o d d` — delete the current line
- `Ctrl+o y y p` — copy the current line and paste it
