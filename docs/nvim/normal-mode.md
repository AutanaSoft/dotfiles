# Normal Mode

Normal mode is where you spend most of your time. Use `Esc` from any other mode to return here.

## Movement

| Action | Shortcut |
| --- | --- |
| Left, down, up, right | `h`, `j`, `k`, `l` |
| Word forward / back | `w` / `b` |
| End of word | `e` |
| Start / end of line | `0` / `$` |
| Start / end of file | `gg` / `G` |
| Half-page down / up | `Ctrl+d` / `Ctrl+u` |

## Entering Insert Mode

| From | Shortcut |
| --- | --- |
| Before / after cursor | `i` / `a` |
| New line below / above | `o` / `O` |

## Edit

| Action | Shortcut |
| --- | --- |
| Delete character | `x` |
| Delete line | `dd` |
| Delete to end of line | `D` |
| Change inside word | `ciw` |
| Change inside parens | `ci(` |
| Change inside quotes | `ci"` |
| Delete inside quotes | `di"` |
| Join line below to current | `J` |

## Copy and Paste

| Action | Shortcut |
| --- | --- |
| Copy line | `yy` |
| Copy inside word | `yiw` |
| Paste after / before | `p` / `P` |
| Paste from system clipboard | `"+p` |

## Undo and Redo

| Action | Shortcut |
| --- | --- |
| Undo / redo | `u` / `Ctrl+r` |

## Search

| Action | Shortcut |
| --- | --- |
| Search forward | `/text` then `Enter` |
| Next / previous result | `n` / `N` |
| Search word under cursor | `*` (forward), `#` (backward) |
| Find files by name | `Space ff` |
| Find text in project | `Space /` |

## Windows

| Action | Shortcut |
| --- | --- |
| Move to left / down / up / right window | `Ctrl+h` `j` `k` `l` |

## Buffers

| Action | Shortcut |
| --- | --- |
| Previous / next buffer | `Shift+h` / `Shift+l` |
| Switch to last buffer | `Space bb` |
| Close current buffer | `Space bd` |

## Save and Quit

| Action | Shortcut |
| --- | --- |
| Save | `Ctrl+s` or `:w` |
| Quit | `:q` |
| Save and quit | `:wq` |
| Quit without saving | `:q!` |

## Code Navigation (LSP)

| Action | Shortcut |
| --- | --- |
| Go to definition | `gd` |
| Show references | `gr` |
| Hover (documentation) | `K` |
| Code actions | `Space ca` |
| Rename symbol | `Space cr` |
| Format buffer | `Space cf` |
