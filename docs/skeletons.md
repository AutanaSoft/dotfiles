# Documentation Skeletons

Copy the fenced block for the doc type you need. The headings below are
template names, not required headings for the final doc.

## Root doc

```txt
# <Tool> <Type>
<1-3 sentences: what it covers, where the file lives, one key fact>

## Quick Path
1. step
2. step
3. step

## <Section 1>
(table | Action | Shortcut | or similar)

## Notes
- gotcha
- gotcha

## Related Files
- path/to/source
- docs/other-doc.md
```

## Grouped subdoc

Pure reference: dense tables, minimal prose, no repeated related links.

```txt
# <Mode or Tool Name>

## <Category 1>
(table | Action | Shortcut |)

## <Category 2>
(table)
```

## Quick reference subdoc

For curated daily-use shortcuts, like `docs/nvim-keymaps.md`.

```txt
# <Tool> Quick Reference
<one sentence: what this quick reference includes>

## Quick Path
- most common action
- most common action

## <Category>
(table)

## Notes
- gotcha
```

## Plugin subdoc

For plugin-specific usage that needs a verification step.

```txt
# <Plugin Name>
<one sentence: what the plugin does in this repo>

## Quick Path
1. action
2. action

## Keymaps
(table)

## Verification
- check
```
