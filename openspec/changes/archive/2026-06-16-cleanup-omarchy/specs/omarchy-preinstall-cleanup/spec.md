# Spec: omarchy-preinstall-cleanup

## Purpose

Selective removal of the 29 Omarchy preinstalls marked `[R]` in
`docs/ideas/scripts/cleanup.md`, using only Omarchy's public
package/webapp/TUI removal APIs and `rm` on the six npx stubs.
Lets the user discard what they do not use (Signal, Discord, Zoom,
etc.) while keeping Spotify, Obsidian, lazydocker, and the 11 other
`[K]` items untouched. Idempotent, audited, gated by a single
`gum confirm` that lists the full command for every item.

## Requirements

### REQ-CLEANUP-001: Mode resolution

The script MUST accept `--interactive`, `--dry-run`, `--list`,
`--yes`, `--help`, and `-h`. The default mode MUST be
non-interactive and MUST run the safety confirm unless `--yes` is
given. `--dry-run` MUST simulate every removal and MUST write a
`dry-run` result line to the audit log. `--list` MUST be pure
discovery: print the categorized plan to stdout, exit 0, MUST NOT
write the audit log, and MUST NOT require a TTY.

#### Scenario: default mode runs the safety confirm

- GIVEN no flags are passed
- WHEN the script runs
- THEN a `gum confirm` prompt is shown before any removal

#### Scenario: --yes skips the safety confirm

- GIVEN `--yes` is passed
- WHEN the script runs
- THEN no `gum confirm` is shown and every item in the plan is
  processed without interactive prompts

#### Scenario: --dry-run simulates every removal

- GIVEN `--dry-run` is passed
- WHEN the script runs
- THEN every removal command is printed, the audit log receives a
  `dry-run` result line per item, and no system mutation occurs

### REQ-CLEANUP-002: Plan construction

The script MUST build the plan from inline bash arrays at the top
of the file, one array per category (`stubs`, `packages`,
`web apps`, `tuis`), grouped by category, with item names quoted
so names containing spaces stay one argument when the command is
generated.

#### Scenario: plan groups items by category

- GIVEN the inline arrays define 6 stubs, 9 packages, 14 web apps, 0 TUIs
- WHEN the plan is built
- THEN three non-empty category groups exist (stubs, packages, web
  apps), and the TUIs group is omitted from the rendered plan

### REQ-CLEANUP-003: Safety confirm

The script MUST show a single `gum confirm` with a category-grouped
summary showing the full command for every plan item, unless
`--yes` is given. On `No`, the script MUST exit 0, MUST NOT write
the audit log, and MUST print `aborted by user` to stdout.

#### Scenario: confirm accepted runs the full plan

- GIVEN default mode and 29 items in the plan
- WHEN the user accepts the confirm
- THEN all 29 removals execute and the audit log captures 29
  result lines

#### Scenario: confirm declined aborts cleanly

- GIVEN default mode
- WHEN the user declines the confirm
- THEN the script prints `aborted by user`, exits 0, and no file
  is created under `backup/`

### REQ-CLEANUP-004: Execution loop

For each item, the script MUST invoke the right Omarchy command:

| Category | Command |
| --- | --- |
| stubs | `rm -f "$HOME/.local/bin/<name>"` |
| packages | `omarchy-pkg-drop <name>` |
| web apps | `omarchy-webapp-remove <name...>` (array form) |
| TUIs | `omarchy-tui-remove <name...>` (array form) |

The user MUST invoke the script with `sudo` if not running as
root, matching the `scripts/setup-omarchy` pattern; the script
itself does not elevate.

#### Scenario: web app name with spaces is preserved

- GIVEN the plan contains `Xbox Cloud Gaming`
- WHEN the script reaches that item
- THEN it invokes `omarchy-webapp-remove "Xbox Cloud Gaming"` with
  one quoted argument

### REQ-CLEANUP-005: Audit log format

The script MUST append a tab-separated line per item to a single
log file at `backup/cleanup-omarchy.<utc-ts>.log`. The line format
MUST be `ts<TAB>category<TAB>name<TAB>command<TAB>result`, where
`ts` is `$(date -u +%FT%TZ)`. The `result` field MUST be one of
`ok`, `fail`, `dry-run`, or `skipped`. The log path MUST be
printed to stdout at the end of a successful run.

#### Scenario: per-item log lines

- GIVEN a run that processes 29 items
- WHEN the run finishes
- THEN the log contains exactly 29 result lines in the prescribed
  format, and the log path is printed to stdout

### REQ-CLEANUP-006: Failure handling

On the first item whose command exits non-zero, the script MUST
print the partial log path to stderr, MUST skip all subsequent
items, and MUST exit non-zero.

#### Scenario: failure mid-run stops the loop

- GIVEN item 12 of 29 fails
- WHEN the loop reaches it
- THEN the script writes the partial log path to stderr, exits
  non-zero, and items 13-29 are not invoked

### REQ-CLEANUP-007: Idempotency

The script MUST detect items already gone (stub missing, package
not installed, webapp/TUI files gone) and log them as `skipped`
instead of `ok` or `fail`. A re-run on a fully cleaned system
MUST perform zero removal calls and MUST exit 0.

#### Scenario: re-run on a clean system is a no-op

- GIVEN the script has already been run successfully
- WHEN it runs again
- THEN 29 `skipped` lines are appended to a new timestamped log
  and no `omarchy-pkg-drop` / `omarchy-webapp-remove` /
  `omarchy-tui-remove` / `rm` call is made; the process exits 0

### REQ-CLEANUP-008: Drift behavior

The script MUST operate on the hardcoded inline list and MUST NOT
re-detect the preinstall set at runtime. After `omarchy update`
adds new preinstalls, the script MUST leave them intact. This
behavior is documented in the script preamble; it is not enforced
at runtime.

#### Scenario: drift leaves new preinstalls alone

- GIVEN `omarchy update` has added a new preinstall not in the
  inline list
- WHEN the script runs
- THEN the new preinstall is not removed and is not mentioned in
  the audit log

### REQ-CLEANUP-009: Interactive picker

In `--interactive` mode on a TTY, the script MUST feed the plan
to `gum choose --no-limit` with all `[R]` items pre-selected, MUST
allow deselection, and MUST rebuild the plan from the user's
selection before running the safety confirm. Categories with zero
items MUST be omitted from the picker. The `--list` output MUST
also omit empty categories.

#### Scenario: interactive picker allows deselection

- GIVEN a TTY and a plan of 29 items across three non-empty
  categories
- WHEN the user deselects 2 items and accepts
- THEN the rebuilt plan has 27 items, the safety confirm runs
  over those 27, and only 27 result lines are logged

### REQ-CLEANUP-010: Non-TTY guard

When `--interactive` is passed and stdin is not a TTY
(`[[ ! -t 0 ]]`), the script MUST print a clear error to stderr,
MUST exit non-zero, and MUST NOT run the picker or write the
audit log.

#### Scenario: --interactive without a TTY fails

- GIVEN stdin is not a TTY and `--interactive` is passed
- WHEN the script runs
- THEN it prints a TTY-required error to stderr and exits non-zero

### REQ-CLEANUP-011: Forbidden paths

The script MUST NOT create, modify, or read any file under
`~/.local/share/omarchy/`. The script preamble MUST include a
comment naming this constraint. Enforcement is by code review.

#### Scenario: no path under ~/.local/share/omarchy is touched

- GIVEN the script runs in any mode
- WHEN the run completes
- THEN no removal, write, or read of any path under
  `~/.local/share/omarchy/` appears in the audit log, in any
  `backup/` file, or in the script's stdout/stderr

## Out of scope

- Wiring the script into root `./setup` (it stays standalone; the
  `setup-orchestration` capability is untouched).
- Parsing `docs/ideas/scripts/cleanup.md` as a list source.
- An `omarchy/README.md` entry in v1.
- A YAML/TOML config file (bash arrays are the source of truth).
- An automated rollback feature (the audit log is the trail).
- Edits to `bindings.conf` (Omarchy-managed).
- Re-detection of the preinstall list at runtime.
- A `--force-keep` override for `[K]` items.
- `omarchy update` integration.
- Automatic rollback beyond the audit log trail.
- CI integration.

## Dependencies

- `gum`, `awk`, `date`, `mkdir`, `tee`, `sudo` (POSIX + Omarchy
  defaults).
- `omarchy-pkg-drop`, `omarchy-webapp-remove`, `omarchy-tui-remove`
  (Omarchy public binaries; call, do not re-implement).
- `pacman` (transitive via `omarchy-pkg-drop`).

No new packages; all already in stock Omarchy.

## Risks

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| `omarchy-pkg-drop` drags deps the user wants to keep | Med | `gum confirm` lists every command; `--yes` is opt-in |
| Web app names with spaces break quoting | Med | Bash arrays; `"${name[@]}"` preserves quoting |
| `omarchy update` adds new preinstalls | Low | Script operates on the hardcoded list; re-run if intent changes |
| `~/.local/share/omarchy/` is read-only on the user | n/a | Script never touches it; uses public APIs only |
| Audit log grows unbounded across many runs | Low | One log per run with timestamped name; manual prune |
| `--interactive` blocks CI / non-TTY callers | Med | Default is non-interactive; `--interactive` guarded by `[[ -t 0 ]]` |
| Confirm feels like friction on a trusted rerun | Low | `--yes` is the escape hatch |
