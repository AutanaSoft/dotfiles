# Git Guide

This repo keeps a portable Git base in `home/.gitconfig`. Local identity can be added directly to `~/.gitconfig` after copying it to a machine.

## Quick Path

1. Copy `home/.gitconfig` to `~/.gitconfig`.
2. Add your real name and email to the local `~/.gitconfig`.

## Files

| File | Purpose |
| --- | --- |
| `home/.gitconfig` | Portable Git defaults |

## Shared Defaults

| Setting | Value |
| --- | --- |
| Default branch | `main` |
| Fetch prune | `true` |
| Rebase auto stash | `true` |
| Push default | `simple` |
| Line endings | `input` + `lf` |
| Diff algorithm | `histogram` |
| Merge conflict style | `zdiff3` |
| Rerere | `enabled` |

## Notes

- Add your real personal or work email only to the local `~/.gitconfig`, not to the versioned file in this repo.

## Related Files

- `home/.gitconfig`
- `fedora/README.md#setup-on-a-new-machine`
