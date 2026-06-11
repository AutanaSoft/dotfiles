# Normal Mode

Normal mode is where you spend most of your time. Use `Esc` from any other mode to return here.

## Movement

| Action | Shortcut |
| --- | --- |
| Left, down, up, right | `h`, `j`, `k`, `l` |
| Next word | `w` |
| Previous word | `b` |
| End of word | `e` |
| Start of line | `0` |
| First non-blank | `^` (`Shift+6`) |
| End of line | `$` (`Shift+4`) |
| Start of file | `gg` |
| End of file | `G` |
| Go to line `N` | `Ng` or `Ngg` |
| Paragraph down | `}` |
| Paragraph up | `{` |
| Page down | `Ctrl+f` |
| Page up | `Ctrl+b` |
| Half-page down | `Ctrl+d` |
| Half-page up | `Ctrl+u` |

## Entering Insert Mode

| From | Shortcut |
| --- | --- |
| Before cursor | `i` |
| After cursor | `a` |
| Start of line | `I` |
| End of line | `A` |
| New line below | `o` |
| New line above | `O` |

## Delete and Change

| Action | Shortcut |
| --- | --- |
| Delete character under cursor | `x` |
| Delete character before cursor | `X` |
| Delete line | `dd` |
| Delete to end of line | `D` or `d$` |
| Delete word | `dw` |
| Delete to end of word | `de` |
| Delete previous word | `db` |
| Delete current word | `diw` |
| Delete inside parentheses | `di(` or `di)` |
| Delete inside braces | `di{` or `di}` |
| Delete inside quotes | `di"` or `di'` |
| Delete around braces | `da{` or `da}` |
| Delete around quotes | `da"` or `da'` |
| Delete entire paragraph | `dip` or `dap` |
| Change line | `cc` |
| Change to end of line | `C` |
| Change current word | `ciw` |
| Change inside braces | `ci{` |
| Change inside quotes | `ci"` |
| Change entire paragraph | `cip` |
| Replace single character | `r` |
| Replace multiple characters | `R` (replace mode, `Esc` to stop) |
| Join line below to current | `J` |

## Copy and Paste (Yank and Put)

| Action | Shortcut |
| --- | --- |
| Copy line | `yy` |
| Copy to end of line | `y$` |
| Copy current word | `yiw` |
| Copy inside braces | `yi{` |
| Copy inside quotes | `yi"` |
| Copy entire paragraph | `yip` |
| Paste after cursor | `p` |
| Paste before cursor | `P` |
| Paste from system clipboard | `"+p` |

## Undo and Redo

| Action | Shortcut |
| --- | --- |
| Undo | `u` |
| Redo | `Ctrl+r` |

## Search

| Action | Shortcut |
| --- | --- |
| Search forward | `/text` then `Enter` |
| Search backward | `?text` then `Enter` |
| Next result | `n` |
| Previous result | `N` |
| Search word under cursor | `*` (forward), `#` (backward) |
| Find files by name | `Space Space` |
| Find text in project | `Space /` |

## Windows

| Action | Shortcut |
| --- | --- |
| Move to left window | `Ctrl+h` |
| Move to lower window | `Ctrl+j` |
| Move to upper window | `Ctrl+k` |
| Move to right window | `Ctrl+l` |
| Increase height | `Ctrl+Up` |
| Decrease height | `Ctrl+Down` |
| Increase width | `Ctrl+Right` |
| Decrease width | `Ctrl+Left` |

## Buffers

| Action | Shortcut |
| --- | --- |
| Previous buffer | `Shift+h` or `[b` |
| Next buffer | `Shift+l` or `]b` |
| Switch to last buffer | `Space b b` or `Space \`` |
| Close current buffer | `Space b d` |
| New empty file | `Space f n` |

## File Operations

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
| Code actions | `Space c a` |
| Rename symbol | `Space c r` |
| Go to implementation | `gI` |
| Go to type definition | `gy` |
| Format buffer | `Space c f` |
| Show diagnostics | `Space x x` |
