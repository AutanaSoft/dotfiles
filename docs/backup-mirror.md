# Backup mirror

`backup-mirror` previews a folder-scoped mirror from `$HOME` to the Backup volume by default. The
configured destination is `/run/media/lcardenas/Backup`; no command in this workflow mounts the
volume or creates that mountpoint. A transfer runs only when the exact mountpoint is present and its
mounted UUID matches `7AA6431BA642D6F3`.

## Quick path

```bash
backup-mirror
backup-mirror --apply
backup-mirror --config "$HOME/.config/backup/mirror.conf" --dry-run
```

The first command is a read-only rsync preview, including stale entries that `--apply` would delete.
Review the full plan before choosing `--apply`. Apply mirrors each configured folder independently
and deletes stale entries only beneath that folder's destination. Existing excluded entries are
protected from deletion. A failed run reports the failed folder; earlier folders may already have
changed.

## Configuration

The single config file is declarative data; the script does not source, evaluate, or include other
config files. Its default is `$HOME/.config/backup/mirror.conf`. `--config PATH` selects an
alternate file.

| Section         | Setting          | Meaning                                                             |
| --------------- | ---------------- | ------------------------------------------------------------------- |
| `[destination]` | `mount_path`     | Existing absolute mount path, default `/run/media/lcardenas/Backup` |
| `[destination]` | `uuid`           | Required identity, `7AA6431BA642D6F3`                               |
| `[folders]`     | `Folder`         | One HOME-relative folder to mirror                                  |
| `[exclusions]`  | `Folder:pattern` | Rsync pattern scoped to that folder's transfer root                 |

Blank lines and `#` comments are ignored. Folder and exclusion entries are bare lines; remove or
comment one out to disable it. Only destination settings use `key = value` syntax. Assignment-style
list entries are rejected. Sections and entries cannot be repeated. Folder paths must be distinct,
non-overlapping relative paths without `.` or `..` components. Exclusions may use patterns such as
`Projects:/**/node_modules/` for matching at arbitrary depth within Projects; they do not apply to
Documents or other transfer roots.

The default selection is `Documents`, `Downloads`, `Music`, `Pictures`, `Videos`, `Work`,
`Projects`, `.pi`, and `.engram`. Project-only exclusions omit nested `node_modules`, `.turbo`,
`.next`, `__pycache__`, the known project `.tmp` and `build` locations, and the confirmed project
`dist` locations. The legacy ignore list was considered but not copied wholesale: `.angular`, `out`,
`coverage`, `backup`, `npm`, `.atl`, `.codegraph`, `.git/gentle-ai`, and `.git/worktrees` are not
blanket exclusions. Git metadata, worktrees, `bin`, `public`, `vendor`, `fixtures`, and `snapshots`
are preserved by default; external linked worktrees are not discovered or excluded automatically.

## Safety and limits

- The command refuses to run as root; `--help` remains available. Required tools and rsync's
  `--mkpath` support are checked before config access or destination changes. All selected sources
  and destination paths are preflighted before transfer. Missing sources, symlinks,
  unsafe/overlapping paths, a non-mountpoint, or an unexpected/missing UUID aborts. Mount identity
  is checked again before each folder transfer. Previews and applies share a per-user, per-volume
  lock in the secure `/run/user/$UID` runtime directory, independent of `XDG_RUNTIME_DIR`.
- Rsync transfers regular files and directories with modification times. Source symlinks and special
  files are omitted. In particular, a dangling source symlink is omitted while a pre-existing
  same-name destination file remains, so skipped source types are not a faithful mirror. Unix
  ownership, permissions, ACLs, extended attributes, hard-link identity, and other metadata are not
  preserved. The NTFS destination can also have case-folding conflicts between distinct source
  names.
- Updates are not atomic. Live application state can change during a copy; disconnects or source
  changes can interrupt a transfer. A device disconnect race remains possible after the identity
  check and while rsync is running. Inspect partial progress after any error and rerun the preview.
- Nested mounts within transfer trees are rejected when visible to `findmnt` during preflight, but
  mount topology may change afterward. No backup is promised to be a point-in-time snapshot.

The script uses Bash and standard system tools (`cat`, `realpath`, `findmnt`, `mountpoint`, `flock`,
`stat`, `dirname`, `cksum`, and `mkdir`) plus rsync with `--mkpath` support. It never requests root
privileges or invokes mount automation.
