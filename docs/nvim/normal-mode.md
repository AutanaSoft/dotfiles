# Normal Mode

Normal mode is where you spend most of your time. Use `Esc` from any other mode to return here.

## Movement

| Action | Shortcut |
| --- | --- |
| Left, down, up, right | `h`, `j`, `k`, `l` |
| Word forward / back | `w` / `b` |
| End of word | `e` |
| Start / end of line | `0` / `$` |
| First / last non-blank | `^` / `g_` |
| Start / end of file | `gg` / `G` |
| Top / middle / bottom of screen | `H` / `M` / `L` |
| Half-page down / up | `Ctrl+d` / `Ctrl+u` |
| Full page down / up | `Ctrl+f` / `Ctrl+b` |
| Jump to matching bracket | `%` |
| Paragraph up / down | `{` / `}` |
| Next / previous word under cursor | `*` / `#` |
| Jump to char forward / back | `f<char>` / `F<char>` |
| Jump up to char | `t<char>` / `T<char>` |
| Repeat last `f`/`t` (next / prev) | `;` / `,` |

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
| Change inside braces | `ci{` |
| Change inside brackets | `ci[` |
| Change inside quotes | `ci"` / `ci'` / `` ci` `` |
| Delete inside parens / braces | `di(` / `di{` |
| Delete inside quotes | `di"` |
| Yank inside parens | `yi(` |
| Yank inside word | `yiw` |
| Join line below to current | `J` |
| Move line down / up | `Alt+j` / `Alt+k` |
| Comment / toggle line | `gcc` |
| Repeat last change | `.` |

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
| Go to declaration | `gD` |
| Go to implementation | `gI` |
| Go to type definition | `gy` |
| Show references | `gr` |
| Next / previous reference | `]]` / `[[` |
| Hover (documentation) | `K` |
| Signature help | `gK` (n) / `Ctrl+k` (i) |
| Code actions | `Space ca` |
| Source actions | `Space cA` |
| Rename symbol | `Space cr` |
| Format buffer | `Space cf` |
| Organize imports | `Space co` |
| Next / previous diagnostic | `]d` / `[d` |
| Next / previous error | `]e` / `[e` |
| Next / previous warning | `]w` / `[w` |

## Multi-Cursor (vim-visual-multi)

Add cursors on matching words to edit them at once. This is the closest thing to
`Ctrl+Shift+L` in VSCode.

| Action | Shortcut |
| --- | --- |
| Add cursor on next match of word under cursor | `Ctrl+n` |
| Add cursor on previous match | `Ctrl+x` |
| Skip current match (don't add cursor) | `Ctrl+n` again |
| Move to next / previous cursor | `]n` / `[n` |
| Remove current / last cursor | `q` / `Q` |
| Select cursors as visual regions | `i` (inner) / `a` (all) |
