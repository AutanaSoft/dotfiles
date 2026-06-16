# Proposal: Cleanup Omarchy Preinstalls Selectively

## Why

Omarchy's `*Preinstalls*` menu nukes every bundled preinstall at once.
There is no way to keep the apps the user actually uses (Spotify,
Obsidian, WhatsApp, lazydocker, etc.) and discard the rest. The
41-item list in `docs/ideas/scripts/cleanup.md` is the user's resolved
intent: 29 `[R]` items to remove, 12 `[K]` items to keep. Today the
user has to remove them one-by-one by hand, or accept the all-or-
nothing wipe.

## What changes

| Kind | Path | Notes |
| --- | --- | --- |
| New | `scripts/cleanup-omarchy` | Bash, executable, ~150 lines, mirrors `scripts/setup-omarchy` |
| New | `backup/cleanup-omarchy.<utc-ts>.log` | Audit log; path is gitignored, content is per-item trace |
| New (optional) | `tests/cleanup-omarchy.bash` | TAP harness, same shape as `tests/setup-deps.bash` |

No changes to `setup-orchestration` spec, root `./setup`,
`omarchy/README.md`, or `shared/`. The `omarchy update` interaction
is documented in the new script's preamble, not enforced anywhere.

## Scope (in)

- Bash script with five flags: **default non-interactive**, `--interactive` (`gum choose` picker), `--dry-run` (print, don't execute), `--list` (print categorized plan and exit 0; pure discovery, no log writes), `--yes` (skip the safety confirm).
- Safety gate: a single `gum confirm` with category-grouped summary showing the **full command** to be run for every item (not just names); the gate always runs by default and `--yes` skips it.
- `--interactive` mode: feed the plan to `gum choose --no-limit`, pre-select every `[R]` item, allow deselect, rebuild the plan from selection, then run the safety gate. **Categories with zero `[R]` items are omitted from the picker entirely.**
- Audit log appended per item: `ts\tcategory\tname\tcommand\tresult`.
- Inline list of 29 `[R]` items as bash arrays; the `docs/ideas/scripts/cleanup.md` doc is rationale, not a binding source.
- Omarchy public APIs only: `omarchy-pkg-drop`, `omarchy-webapp-remove <name...>`, `omarchy-tui-remove <name...>`, `rm` on `~/.local/bin/<stub>` for the six npx stubs.
- Idempotent: re-runnable, skips items already gone, never reinstalls.
- A TAP smoke test under `tests/` is nice-to-have; not a gate (config has `strict_tdd: false`).

## Scope (out)

- **Wired to root `./setup`**: violates `setup-orchestration` "thin dispatcher" + "MUST NOT execute a multi-step pipeline" rules.
- **Parsing `docs/ideas/scripts/cleanup.md`** to extract the list: the doc is a rationale artifact, not data.
- **`omarchy/README.md` entry** for v1: discoverable via `scripts/cleanup-omarchy --help`.
- **YAML/TOML config file**: YAGNI for 30 hardcoded items; bash array is grep-able and diff-friendly.
- **Rollback feature**: the audit log is the trail; restoring a removed preinstall is a one-liner.
- **`bindings.conf` edits**: not touched; Omarchy-managed.
- **Re-detection of the preinstall list at runtime**: the script operates on the hardcoded list. New preinstalls added by `omarchy update` are left untouched (the user re-runs the script if intent changes).
- **`--force-keep` override for `[K]` items**: not provided in v1. If the user wants to remove a `[K]` item, they call the underlying Omarchy command directly.

## Approach

Mirror `scripts/setup-omarchy` template: `set -euo pipefail`, `usage()`,
`log/warn/fail`, `require_command`, `--dry-run` honored everywhere.
Hold the 29 `[R]` items in four top-of-file bash arrays keyed by
category (`STUBS`, `PKGS`, `WEBAPPS`, `TUIS`). At runtime, build a
`plan` array of `<category>:<name>:<command>` rows, run the safety
gate (unless `--yes`), iterate the plan logging to
`backup/cleanup-omarchy.<ts>.log`, and exit non-zero on first
failure with the partial log path printed. In `--interactive` mode,
feed the plan to `gum choose --no-limit` and rebuild the plan from
the user's selection. In `--dry-run`, print the plan and exit 0.

## Capabilities

> Contract with the sdd-spec phase. Research `openspec/specs/` first.

### New Capabilities

- `omarchy-preinstall-cleanup`: selective removal of the 29
  preinstalls marked `[R]` in `docs/ideas/scripts/cleanup.md`,
  using Omarchy's public package/webapp/TUI removal APIs and
  direct `rm` for the npx stubs. Idempotent, audited, gated by
  a safety confirm.

### Modified Capabilities

- None. `setup-orchestration` is untouched (this script is not
  dispatched by the root `./setup`).

## Affected Areas

| Area | Impact | Description |
| --- | --- | --- |
| `scripts/cleanup-omarchy` | New | The script itself; executable, lint-clean, template-aligned |
| `backup/cleanup-omarchy.<ts>.log` | New (runtime) | Per-run audit log; `backup/` already gitignored |
| `tests/cleanup-omarchy.bash` | New (optional) | TAP harness — only if spec phase decides to add it |

## Dependencies

None new. All already in stock Omarchy:

- `gum` (picker + confirm — preinstalled by Omarchy)
- `awk`, `date`, `mkdir`, `tee` (POSIX)
- `sudo` (for `omarchy-pkg-drop`, which calls `pacman -Rns`)
- `omarchy-pkg-drop`, `omarchy-webapp-remove`, `omarchy-tui-remove`
  (Omarchy public binaries; read source for behavior)

## Risks

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| `omarchy-pkg-drop` drags dependencies the user wants to keep | Med | `gum confirm` gate lists every command before any removal; `--yes` is opt-in |
| Web app names contain spaces (e.g. "Xbox Cloud Gaming") | Med | Bash arrays are quoted; `omarchy-webapp-remove` is invoked with `"${name[@]}"` |
| Omarchy's preinstall list drifts after an `omarchy update` | Low | The script operates on the hardcoded list; re-running after a refresh re-applies intent. Drift does not break the script — it just leaves new preinstalls alone (acceptable; see Open Q1) |
| `~/.local/share/omarchy/` is read-only on the user | n/a | This script never touches it; it only calls Omarchy public APIs |
| Audit log grows unbounded across many runs | Low | Single log per run with timestamped name; user can prune `backup/cleanup-omarchy.*.log` manually (no `logrotate` wiring in v1) |
| `--interactive` blocks CI / non-TTY callers | Med | Default is non-interactive; `--interactive` requires a TTY (`gum choose` errors out) — guard with `[[ -t 0 ]]` check |
| Safety confirm in default mode feels like friction on a trusted rerun | Low | `--yes` is the documented escape hatch |

## Rollback Plan

The audit log is the trail. A removed preinstall is restored by
reinstalling it:

- **Stubs**: `npx <name>` (the stubs are `npx`-launched shims).
- **Packages**: `omarchy-pkg-add <pkg>` or `yay -S <pkg>`.
- **Web apps**: `omarchy-webapp-install <name>`.
- **TUIs**: `omarchy-tui-install <name>`.

No automated rollback in v1; the audit log is the source of truth
for "what was removed, when, and with which command".

## Decisions already made

These are locked in by the user; the next phase MUST NOT re-litigate:

1. **List source**: inline bash arrays in `scripts/cleanup-omarchy`. The `docs/ideas/scripts/cleanup.md` doc is rationale, not a parser input.
2. **Safety gate**: `gum confirm` with category-grouped summary, always on by default; `--yes` to skip.
3. **Audit log**: appended per item to `backup/cleanup-omarchy.<utc-ts>.log`.
4. **No `omarchy/README.md` entry** in v1.
5. **Not wired to root `./setup`**: cleanup is destructive and stays standalone; `setup-orchestration` spec is untouched.
6. **Drift after `omarchy update`**: the script operates on the hardcoded list. New preinstalls added by an update are left intact; the user re-runs if intent changes. The script does NOT re-detect preinstalls at runtime.
7. **Safety confirm content**: the `gum confirm` shows the **full command** to be run for each item (not just names), so the user sees exactly what will be executed.
8. **`--list` mode**: separate flag from `--dry-run`. `--list` is pure discovery (prints the categorized plan, exits 0, does not write to the audit log). `--dry-run` simulates execution and DOES write a `dry-run` result line to the log.
9. **Empty categories in `--interactive`**: categories with zero `[R]` items are omitted from the `gum choose` picker. No `--force-keep` override is provided.

## Success Criteria

- [ ] `scripts/cleanup-omarchy --help` exits 0 and lists every flag, category, and the audit log path.
- [ ] `scripts/cleanup-omarchy --list` prints the categorized plan (only the 4 categories with at least one `[R]` item) and exits 0; no audit log is written.
- [ ] `scripts/cleanup-omarchy --dry-run` prints every removal command, writes a `dry-run` result line per item to the audit log, and exits 0 without mutating the system.
- [ ] Running the script in `--interactive` mode on a TTY opens a `gum choose` picker populated with the 29 `[R]` items; the user can deselect any, and the resulting plan is the one executed. Categories with zero `[R]` items (TUIs in the current list) are omitted from the picker.
- [ ] The default non-interactive mode runs the safety confirm first showing **the full command** for every item, grouped by category. On `No`, the script exits 0 with "aborted by user" and writes nothing to the audit log.
- [ ] On first removal failure, the script writes the partial log path to stderr and exits non-zero; subsequent items are skipped.
- [ ] Re-running the script on an already-cleaned system exits 0 with zero `omarchy-pkg-drop` / `omarchy-webapp-remove` / `omarchy-tui-remove` calls in the audit log (idempotency proven).
- [ ] No file under `~/.local/share/omarchy/` is created, modified, or referenced by the script.

## Open questions for the user (blocking)

None. The 4 proposal-shaping UX questions (drift handling, confirm
verbosity, `--list` flag, empty-category behavior) were answered
by the user with the recommended defaults — see decisions 6-9
above. The spec phase can proceed.
