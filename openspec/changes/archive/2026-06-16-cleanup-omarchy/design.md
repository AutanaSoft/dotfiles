# Design: Cleanup Omarchy Preinstalls Selectively

> **Change**: `cleanup-omarchy` · **Capability**: `omarchy-preinstall-cleanup`
> **Inputs**: [`proposal.md`](./proposal.md) (9 locked decisions),
> [`specs/omarchy-preinstall-cleanup/spec.md`](./specs/omarchy-preinstall-cleanup/spec.md)
> (REQ-CLEANUP-001..011, 14 scenarios).
> **Targets**: `scripts/cleanup-omarchy` (new, ~170 lines bash),
> `tests/cleanup-omarchy.bash` (new, optional, ~50 lines TAP).

## Technical Approach

A standalone bash script in `scripts/` that mirrors the
`scripts/setup-omarchy` template (header comment, `set -euo pipefail`,
`IFS=$'\n\t'`, `usage`, `log`/`warn`/`fail`, `require_command`). The
script holds the 29 `[R]` items in four inline arrays at the top of
the file, builds a category-grouped plan at runtime, runs a single
`gum confirm` safety gate (showing the full command per item), and
iterates the plan invoking the right Omarchy public binary per
category. Each result is appended as a tab-separated line to a
timestamped audit log under `backup/`. Idempotency is enforced by a
per-category `is_installed` probe that emits a `skipped` line for
items already gone. The script is **not** wired to root `./setup` and
is **not** entered in `omarchy/README.md` (per decisions 4 and 5).

## Architecture Decisions

| # | Decision | Choice | Rationale |
| - | --- | --- | --- |
| D1 | List source | Inline bash arrays at top of file | Decision 1; matches `setup-deps` pattern (`OMARCHY_PACKAGES=()`); grep-able and diff-friendly; no parser needed |
| D2 | Safety gate | `gum confirm` with full command per item, always on by default; `--yes` skips | Decision 2 + 7; gum is preinstalled on Omarchy; one prompt keeps the UX simple; full command lets the user see exactly what will run |
| D3 | Audit log path | `$REPO_ROOT/backup/cleanup-omarchy.<utc-ts>.log`, one per run, TSV | Decision 3; `backup/` is already gitignored; one file per run keeps each run traceable and trimmable |
| D4 | Dry-run vs list | Separate flags: `--list` is pure discovery (no log), `--dry-run` simulates and logs | Decision 8; `--list` is read-only so it must not write a log; `--dry-run` is a simulation of the real run, so it must leave the same audit trail shape |
| D5 | Empty category rendering | `build_plan` skips empty categories entirely; `--list` and the picker omit them | Decision 9 + REQ-CLEANUP-002; no "(none)" sentinel avoids lying about the user's intent on a `grep` |
| D6 | Drift after `omarchy update` | Hardcoded list, no runtime re-detection; documented in preamble | Decision 6; re-detection is out of scope for v1; the user re-runs when intent changes |
| D7 | Skip probe | Per-category `is_installed(category, name)` runs **before** the call; on miss, log `skipped: not present` and skip the call | REQ-CLEANUP-007 demands `skipped` lines for items already gone; the binaries themselves are idempotent (rm -f / pacman-Q filter) but do not emit a "skipped" line we can audit |
| D8 | Picker grouping | `gum choose --no-limit` with one row per item formatted as `category  name  command`; omit empty categories | REQ-CLEANUP-009; the command column lets the user see what they're selecting without opening a second prompt |
| D9 | Plan failure | First non-zero item → log partial path to stderr, exit 1, skip rest | REQ-CLEANUP-006; the audit log is the trail, so the partial log is preserved for the user to inspect |
| D10 | Non-TTY guard | `--interactive` requires `[[ -t 0 ]]`; otherwise fail fast to stderr, exit 1 | REQ-CLEANUP-010; `gum choose` errors on a non-TTY anyway, but the explicit guard gives a clear, script-controlled error message |

## Data Flow

```
        ┌──────────────────────────────────────┐
        │  Inline arrays (4 categories, 29)    │
        │  STUBS, PKGS, WEBAPPS, TUIS          │
        └────────────────┬─────────────────────┘
                         │
                         ▼
                build_plan() ─────────► (skips empty categories)
                         │
            ┌────────────┼────────────┐
            │            │            │
            ▼            ▼            ▼
        --list       --interactive  default / --yes / --dry-run
        print        gum choose     (--yes skips)
        exit 0       refine plan    gum confirm
                     (--yes skips)  exit 0 on No
                         │            │
                         └─────┬──────┘
                               ▼
                       confirm_safety
                       (gum confirm, full cmd)
                               │
                               ▼
                       execute_plan
                       per row:
                         is_installed? ──► no  → log "skipped"
                                  │
                                  ▼
                                 yes
                                  │
                                  ▼
                       run removal command
                                  │
                       ┌──────────┼──────────┐
                       ▼          ▼          ▼
                     ok         fail       dry-run
                  log row    log row     log row (no mutation)
                              stderr+1
```

## File Structure of `scripts/cleanup-omarchy`

Approximate line budgets per section. Mirrors `setup-omarchy` /
`setup-deps` skeletons so a reader who knows those files can navigate
this one without re-learning the layout.

| Lines | Section | Notes |
| --- | --- | --- |
| ~25 | Shebang + header comment | Mirrors `setup-omarchy` tone; documents decision 6 (drift) and REQ-CLEANUP-011 (`~/.local/share/omarchy/` read-only); documents audit log path and exit-code contract |
| 1 | `set -euo pipefail` + `IFS=$'\n\t'` | Same as siblings |
| ~20 | Constants | `REPO_ROOT` resolution (BASH_SOURCE-based; script is not invoked by root so `DOTFILES_ROOT` is informational only), `BACKUP_DIR`, `LOG_TEMPLATE`, `STUB_BIN_DIR="$HOME/.local/bin"`, `DESKTOP_DIR="$HOME/.local/share/applications"`, default flags (all 0) |
| ~30 | Inline arrays | `STUBS=(...)`, `PKGS=(...)`, `WEBAPPS=(...)`, `TUIS=(...)`; each entry is a quoted string so names with spaces stay one item (see lists below) |
| ~25 | Helpers | `usage()`, `log`, `warn`, `fail`, `require_command`, `now_utc`, `confirm_safety`, `list_plan` |
| ~25 | `is_installed(category, name) -> bool` | Per-category probe dispatch (see Idempotency table) |
| ~20 | `build_plan() -> array of "category<TAB>name<TAB>command"` | Iterates the 4 arrays; for each entry, generates the literal command string with the name pre-quoted; skips categories with zero entries |
| ~30 | `interactive_pick(plan) -> plan` | Builds `gum choose` rows from plan, pre-selects all, deselection rebuilds plan; empty categories absent |
| ~30 | `execute_plan(plan, log_path, mode)` | `mode` ∈ `run`/`dry-run`; per row: probe → log `skipped` or call → log `ok`/`fail`/`dry-run`; first failure → log path to stderr, exit 1 |
| ~10 | `main()` | Parse flags → validate combinations → route to `--help` / `--list` / `--interactive` / `--dry-run` / default + `--yes`; build log path; confirm → execute |
| ~170 | **Total** | Executable, `chmod +x`, `set -euo pipefail` at top |

### Inline arrays (4 categories, 29 items)

Names and categories taken verbatim from
[`docs/ideas/scripts/cleanup.md`](../../docs/ideas/scripts/cleanup.md)
and re-locked by the proposal. All `[K]` items are intentionally
omitted from the arrays; the script never references them.

```bash
STUBS=(
    codex
    copilot
    gemini
    opencode
    playwright-cli
    pi
)                                                       # 6 items

PKGS=(
    1password-beta
    1password-cli
    claude-code
    kdenlive
    obs-studio
    opencode
    pinta
    signal-desktop
    typora
)                                                       # 9 items

WEBAPPS=(
    Basecamp
    ChatGPT
    Discord
    Figma
    Fizzy
    GitHub
    Google Contacts
    Google Maps
    Google Messages
    HEY
    Tailscale
    X
    "Xbox Cloud Gaming"
    Zoom
)                                                       # 14 items

TUIS=(
)                                                       # 0 items
```

`build_plan` produces a row per non-empty category. Each row is
`<category>\t<name>\t<command>` where `<command>` is the literal
shell line that `execute_plan` will echo to the log and (in
non-dry-run) invoke. Names with spaces are emitted quoted:

```
stubs    codex                         rm -f /home/user/.local/bin/codex
stubs    playwright-cli                rm -f /home/user/.local/bin/playwright-cli
packages 1password-cli                 omarchy-pkg-drop 1password-cli
webapps  Google Contacts               omarchy-webapp-remove "Google Contacts"
webapps  Xbox Cloud Gaming             omarchy-webapp-remove "Xbox Cloud Gaming"
```

## Idempotency Strategy

`is_installed(category, name)` runs **before** the removal call.
Probes are read-only; they never modify the system.

| Category | Probe | Skip line on miss | Rationale |
| --- | --- | --- | --- |
| `stubs` | `[ -e "$STUB_BIN_DIR/$name" ]` | `skipped: stub missing` | REQ-CLEANUP-007; npx shims are files in `~/.local/bin/` |
| `packages` | `pacman -Qq "$name" >/dev/null 2>&1` | `skipped: package not installed` | `omarchy-pkg-drop` already filters via `pacman -Q`, but does not emit a "skipped" trail line; the probe gives us the audit row |
| `webapps` | `[ -e "$DESKTOP_DIR/$name.desktop" ]` | `skipped: webapp not installed` | `omarchy-webapp-remove` does `rm -f $DESKTOP_DIR/$name.desktop`; presence of the `.desktop` is the canonical "is this a webapp" signal |
| `tuis` | `[ -e "$DESKTOP_DIR/$name.desktop" ]` | `skipped: tui not installed` | Same contract as webapps (no icon probe needed; `rm -f` is idempotent) |

A re-run on a fully cleaned system produces 29 `skipped` lines
across the 3 non-empty categories, zero removal calls, exit 0.
A first run on a clean system with all 29 items present produces
29 `ok` lines. A mixed run (e.g. `1password-cli` already gone)
produces 28 `ok` + 1 `skipped`.

## Flag Interaction Matrix

| Flags | Confirm? | TTY? | Log written? | Exit |
| --- | --- | --- | --- | --- |
| *(none)* | Yes | any | Yes (`ok`/`fail`) | 0 / 1 |
| `--yes` | No | any | Yes (`ok`/`fail`) | 0 / 1 |
| `--dry-run` | No | any | Yes (`dry-run`) | 0 |
| `--list` | No | any | **No** | 0 |
| `--interactive` | Yes | required | Yes (`ok`/`fail`) | 0 / 1 |
| `--interactive --yes` | No | required | Yes (`ok`/`fail`) | 0 / 1 |
| `--interactive --dry-run` | No | required | Yes (`dry-run`) | 0 |
| `--list --dry-run` (and any `--list` + execution flag) | — | — | — | **2** (error to stderr) |
| `--list --yes` | — | — | — | **2** (error to stderr) |
| `--interactive` on non-TTY | — | — | — | **1** (TTY-required error to stderr) |
| `--help` / `-h` | No | any | No | 0 (prints usage) |
| Unknown arg | — | — | — | **2** (`usage >&2`) |

The mutually-exclusive check is a small set of guards at the top of
`main()`. Conflict cases print a single-line diagnostic to stderr
(`--list is mutually exclusive with --dry-run / --yes / --interactive`)
and `exit 2`, mirroring `setup-omarchy`'s unknown-arg handling.

## Audit Log Format

Single TSV file: `backup/cleanup-omarchy.<utc-ts>.log` where
`<utc-ts>` = `$(date -u +%Y%m%dT%H%M%SZ)`. The path is printed to
stdout at the end of a successful run, and to stderr on partial
failure (REQ-CLEANUP-005 / -006).

One line per item, tab-separated, exact field order
`ts<TAB>category<TAB>name<TAB>command<TAB>result`:

```
2026-06-15T14:23:11Z	pkg	1password-cli	omarchy-pkg-drop 1password-cli	ok
2026-06-15T14:23:12Z	webapp	Xbox Cloud Gaming	omarchy-webapp-remove "Xbox Cloud Gaming"	fail: exit 1
2026-06-15T14:23:13Z	stub	codex	rm -f /home/user/.local/bin/codex	skipped: not present
2026-06-15T14:23:14Z	webapp	Basecamp	omarchy-webapp-remove Basecamp	dry-run
```

| Field | Source | Notes |
| --- | --- | --- |
| `ts` | `now_utc` = `date -u +%FT%TZ` (ISO-8601) | One timestamp per row, captured at write time |
| `category` | one of `stub` / `pkg` / `webapp` / `tui` | Singular, lowercase (the plan key is plural; logs singular) |
| `name` | item from inline array | Quoted in the `command` field if it contains spaces, but **raw** in the `name` field (no quotes) so `awk -F'\t' '$2=="webapp" && $3 ~ /Xbox/'` works |
| `command` | literal shell line | The full command that was (or would have been) run, with `$HOME` expanded |
| `result` | one of `ok`, `fail: exit N`, `dry-run`, `skipped: <reason>` | Set by `execute_plan`; on `set -e` propagation the fail row carries the exit code |

`backup/cleanup-omarchy.<ts>.log` is appended in the order
`STUBS → PKGS → WEBAPPS → TUIS` (TUIs section is omitted when empty
because the loop never iterates it). `mkdir -p` on `backup/` runs
once before the loop in non-list modes.

## Empty Category Handling

`build_plan` iterates only the categories that have at least one
entry in the corresponding inline array. The TUIs array is empty in
v1; the loop never touches it, so:

- `--list` prints `stubs:`, `packages:`, `webapps:` headers and
  nothing for TUIs (REQ-CLEANUP-002 scenario).
- `--interactive` `gum choose` rows are drawn from the plan, so the
  TUIs category is absent from the picker (REQ-CLEANUP-009).
- `confirm_safety` body is built from the plan; TUIs section is
  absent from the confirm message.
- `execute_plan` iterates the plan, so TUIs section is absent from
  the audit log.

A future maintainer who adds TUIs to the array will see them appear
everywhere automatically; no other code changes are required.

## Drift Handling

Per decision 6, the script does **not** re-detect the preinstall
set at runtime. The hardcoded list is the contract. After
`omarchy update` adds new preinstalls, the script leaves them
intact: it has no name for them, so it cannot plan a removal, and
its `is_installed` probe never runs for them. This is documented in
the script preamble (REQ-CLEANUP-008):

```
# Drift: this script operates on a hardcoded list of 29 [R] items.
# After `omarchy update` adds new preinstalls, they are left intact.
# Re-run the script if your intent changes. See
# docs/ideas/scripts/cleanup.md for the source list.
```

The probe-based idempotency (§ Idempotency Strategy) means a
post-update re-run is still safe: items already gone are logged
`skipped`, items still present are removed, new items are ignored.

## Error Handling Strategy

| Condition | Behavior | Reference |
| --- | --- | --- |
| `set -euo pipefail` global | Any uncaught error aborts | Mirrors siblings |
| Missing required command | `require_command` calls `fail` | `gum`, `date`, `mkdir`, `tee` |
| Unknown flag | `usage >&2; exit 2` | Mirrors `setup-omarchy` |
| `--list` + execution flag | stderr diagnostic, `exit 2` | Decision 8 / REQ-CLEANUP-001 |
| `--interactive` on non-TTY | stderr TTY-required message, `exit 1` | REQ-CLEANUP-010 |
| Confirm declined | print `aborted by user`, `exit 0` | REQ-CLEANUP-003 |
| `--help` / `-h` | print usage, `exit 0` | REQ-CLEANUP-001 |
| Per-item removal failure | log row with `fail: exit N`, write partial log path to stderr, `exit 1`; subsequent items skipped | REQ-CLEANUP-006 |
| Re-run on clean system | 29 `skipped` rows, `exit 0` | REQ-CLEANUP-007 |
| Touching `~/.local/share/omarchy/` | Never (preamble + code review) | REQ-CLEANUP-011 |

`require_command` is called for `gum`, `date`, `mkdir`, and `tee`
up front. `pacman` and `omarchy-pkg-drop` are only required when the
plan contains a `packages` row, because `--list` and a TUIs-only
plan must not need `pacman` on PATH. The same lazy check applies
per category: webapps need `omarchy-webapp-remove` on PATH iff
`WEBAPPS` is non-empty in the plan.

## Test Strategy

Per `openspec/config.yaml` `strict_tdd: false` the TAP harness is
**nice-to-have**; the design recommends including it. The apply
phase may defer if the script's `--list` / `--help` / dry-run paths
are smoke-tested manually.

New file: `tests/cleanup-omarchy.bash` (~50 lines TAP, repo-native;
mirrors the `tests/setup-deps.bash` skeleton). Suggested asserts:

| # | Assert | Target |
| - | --- | --- |
| T1 | `--help` exits 0 and contains every flag string (`--interactive`, `--dry-run`, `--list`, `--yes`) | `usage()` |
| T2 | `--list` exits 0, stdout contains `stubs:`, `packages:`, `webapps:` headers, and does NOT contain `tuis:` | `list_plan` + `build_plan` |
| T3 | `--dry-run` exits 0, writes a file under `backup/` whose name matches `cleanup-omarchy.<ts>.log`, and the log contains 29 lines with `dry-run` as the result field | `execute_plan` in dry-run mode |
| T4 | Second `--dry-run` produces 29 lines with `skipped` as the result field (idempotency) | `is_installed` probe |
| T5 | `--list --dry-run` exits non-zero (mutually exclusive) | `main()` flag guards |
| T6 | `--interactive` on non-TTY (`< /dev/null`) exits non-zero and stderr mentions TTY | `main()` non-TTY guard |
| T7 | `omarchy-pkg-drop` is invoked with all 9 `[R]` package names in non-dry-run mode (proven via stub log) | `execute_plan` `packages` branch |

Stubs reuse the `make_stubs` / `make_pm_stubs` pattern from
`tests/setup-deps.bash` (command on PATH that logs to a file and
exits 0/1). The harness can be run as `bash tests/cleanup-omarchy.bash`
and exits 0 only when all asserts pass.

## Mapping Table: Requirement → Section → Scenario

| Requirement | Section / function | Scenarios exercised |
| --- | --- | --- |
| REQ-CLEANUP-001 Mode resolution | `main()` flag parsing + dispatch | #1 default confirm, #2 `--yes` skips, #3 `--dry-run` simulates |
| REQ-CLEANUP-002 Plan construction | `build_plan()` + inline arrays | "plan groups items by category" |
| REQ-CLEANUP-003 Safety confirm | `confirm_safety()` + `main()` | "confirm accepted runs the full plan", "confirm declined aborts cleanly" |
| REQ-CLEANUP-004 Execution loop | `execute_plan()` per-category branches | "web app name with spaces is preserved" |
| REQ-CLEANUP-005 Audit log format | `execute_plan()` row format + `now_utc` | "per-item log lines" |
| REQ-CLEANUP-006 Failure handling | `execute_plan()` `set -e` + stderr-on-fail | "failure mid-run stops the loop" |
| REQ-CLEANUP-007 Idempotency | `is_installed()` + `execute_plan()` skipped branch | "re-run on a clean system is a no-op" |
| REQ-CLEANUP-008 Drift behavior | preamble comment; no runtime check | "drift leaves new preinstalls alone" |
| REQ-CLEANUP-009 Interactive picker | `interactive_pick()` + `build_plan()` empty-category skip | "interactive picker allows deselection" |
| REQ-CLEANUP-010 Non-TTY guard | `main()` `[[ -t 0 ]]` check | "`--interactive` without a TTY fails" |
| REQ-CLEANUP-011 Forbidden paths | preamble comment; review contract | "no path under `~/.local/share/omarchy/` is touched" |

Each scenario in
[`spec.md`](./specs/omarchy-preinstall-cleanup/spec.md) maps to one
or more rows above; this is the reviewer's audit trail for
"scenario → which code proves it".

## Files Affected

| Path | Action | Description |
| --- | --- | --- |
| `scripts/cleanup-omarchy` | Create | Bash, executable, `set -euo pipefail`, ~170 lines. Mirrors `setup-omarchy` template. |
| `backup/` | Create (runtime) | Already gitignored; the script `mkdir -p`s it on first run. No committed file. |
| `tests/cleanup-omarchy.bash` | Create (optional) | TAP harness, ~50 lines, nice-to-have per `strict_tdd: false`. |

No changes to `setup-orchestration` spec, root `./setup`,
`omarchy/README.md`, `shared/`, `docs/conventions.md`, or
`AGENTS.md` (per decision 4 / 5).

## Risks

| Risk | Likelihood | Mitigation in design |
| --- | --- | --- |
| `omarchy-pkg-drop` drags dependencies the user wants to keep | Med | `confirm_safety` shows the full command per item; the user reviews before approval; `--yes` is opt-in |
| Web app names with spaces break quoting | Med | Bash arrays hold one item per name; `build_plan` emits `"$name"` in the command field; execution uses `"$name"` |
| `omarchy update` adds new preinstalls | Low | Hardcoded list; documented in preamble; the user re-runs when intent changes (decision 6) |
| `~/.local/share/omarchy/` is read-only | n/a | Script never touches it; preamble + REQ-CLEANUP-011 enforce by review |
| Audit log grows unbounded | Low | One log per run with timestamped name; manual prune (no `logrotate` wiring in v1) |
| `--interactive` blocks CI / non-TTY callers | Med | Default is non-interactive; `--interactive` guarded by `[[ -t 0 ]]`; non-TTY error is clear and exits 1 |
| Confirm feels like friction on a trusted rerun | Low | `--yes` is the documented escape hatch |
| `is_installed` probe is wrong for a category | Med | Probes derived from reading `omarchy-pkg-drop`, `omarchy-webapp-remove`, `omarchy-tui-remove` source; T3 + T4 in the TAP harness cover the first-run and re-run cases |

## Open Questions

None. The 9 decisions in `proposal.md` cover the design space; the
spec is locked; the omarchy public APIs are confirmed; the script
template is in `scripts/setup-omarchy`. The apply phase can proceed
without further clarification.

## References

- [`proposal.md`](./proposal.md) — 9 locked decisions
- [`specs/omarchy-preinstall-cleanup/spec.md`](./specs/omarchy-preinstall-cleanup/spec.md) — 11 requirements, 14 scenarios
- [`docs/ideas/scripts/cleanup.md`](../../docs/ideas/scripts/cleanup.md) — rationale for the 29-item list (parser NOT used)
- `scripts/setup-omarchy`, `scripts/setup-deps`, `scripts/setup-fonts` — template, helpers, dry-run handling
- `~/.local/share/omarchy/bin/omarchy-pkg-drop` (16 lines) — package removal
- `~/.local/share/omarchy/bin/omarchy-webapp-remove` (48 lines) — webapp removal
- `~/.local/share/omarchy/bin/omarchy-tui-remove` (46 lines) — TUI removal
- `tests/setup-deps.bash` — TAP harness template (stub pattern)
- `openspec/config.yaml` — `strict_tdd: false`, `bash tests/setup-deps.bash` test command
