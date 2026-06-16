# Tasks: Cleanup Omarchy Preinstalls Selectively

> **Change**: `cleanup-omarchy` · **Capability**: `omarchy-preinstall-cleanup`
> **Inputs**: [`proposal.md`](./proposal.md) (9 locked decisions),
> [`specs/omarchy-preinstall-cleanup/spec.md`](./specs/omarchy-preinstall-cleanup/spec.md)
> (REQ-CLEANUP-001..011, 14 scenarios),
> [`design.md`](./design.md) (10 architecture decisions, file structure,
> flag matrix, mapping table).

The script mirrors `scripts/setup-omarchy` (header, `set -euo pipefail`,
`IFS=$'\n\t'`, `usage`, `log`/`warn`/`fail`, `require_command`).
Inline arrays at the top, category-grouped plan, single `gum confirm`
gate, per-item audit log, idempotent skip probes.

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Total estimated changed lines | ~300 |
| Total new files | 2 (`scripts/cleanup-omarchy`, `tests/cleanup-omarchy.bash`) |
| Total modified files | 0 (per design § "Files Affected"; `backup/` is gitignored runtime artifact) |
| Chained PRs recommended | No |
| 400-line budget risk | Low |
| Decision needed before apply | No |
| Delivery strategy | ask-always |
| Chain strategy | n/a (single PR) |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

### Risk callouts

- **T-013 README defer is intentional** (per design D4 / decision 4). v1 stays discoverable via `--help`; an `omarchy/README.md` entry is a v2 ask, not an oversight.
- **T-012 TAP harness is optional** (per `openspec/config.yaml` `strict_tdd: false`). Marked as "optional / nice-to-have" so apply can defer without breaking the contract.
- **T-006 (interactive_pick) is a refinement of the suggested ordering** — the suggested list omitted a dedicated task for the `gum choose` picker function even though the design calls for it as a ~30-line sibling of `build_plan`. Folding it into the dispatcher (T-009) would make that task too large for a single reviewable unit.

## Task ordering

| # | Task | Section | Lines |
|---|------|---------|-------|
| T-001 | Skeleton + shebang + header + flags + usage | top-of-file | ~30 |
| T-002 | Constants + inline arrays (STUBS, PKGS, WEBAPPS, TUIS) | top-of-file | ~35 |
| T-003 | Helpers — `log`, `warn`, `fail`, `require_command`, `now_utc` | helpers | ~20 |
| T-004 | `is_installed(category, name)` per-category probe | helpers | ~25 |
| T-005 | `build_plan()` — assembles plan from 4 arrays, skips empty | core | ~20 |
| T-006 | `interactive_pick(plan)` — gum choose with deselection | core | ~30 |
| T-007 | `confirm_safety(plan)` — gum confirm with full commands | core | ~25 |
| T-008 | `execute_plan(plan, log_path, mode)` — runs + logs + fails fast | core | ~30 |
| T-009 | Main dispatcher — flags → modes → plan → confirm/execute | main | ~25 |
| T-010 | `--list` mode (verification branch) | main | ~5 |
| T-011 | `--dry-run` mode (verification branch) | main | ~5 |
| T-012 | `tests/cleanup-omarchy.bash` TAP harness (optional) | tests | ~50 |
| T-013 | `omarchy/README.md` entry — DEFER to v2 | docs | 0 |

---

### T-001: Script skeleton + shebang + header + flags + usage

**Files**:
- `scripts/cleanup-omarchy` (new) — empty executable that handles `--help` and exits 0; no business logic yet

**Satisfies**: REQ-CLEANUP-001, REQ-CLEANUP-011
**Scenarios**: #14
**Estimate**: ~30 lines

**Description**:
Create the file as a stub executable with the shebang, header comment block (~25 lines mirroring `scripts/setup-omarchy` tone), `set -euo pipefail`, `IFS=$'\n\t'`, default flag variables (all 0), the `usage()` heredoc listing every flag, category, and audit log path, and the flag-parsing `while [[ $# -gt 0 ]]` loop that currently only handles `--help` / `-h` and rejects unknown args with `usage >&2; exit 2`. The header MUST document (a) drift behavior — the script operates on a hardcoded 29-item list; re-run after `omarchy update` if intent changes (decision 6); (b) the forbidden-paths contract — never touch `~/.local/share/omarchy/` (REQ-CLEANUP-011); and (c) the audit log path `backup/cleanup-omarchy.<utc-ts>.log`. No constants, no arrays, no helpers yet — those come in T-002 / T-003. The dispatch loop is in place so T-002..T-008 can be layered on without restructuring. The `--help` output must list the four categories (`stubs`, `packages`, `web apps`, `tuis`) and the audit log path explicitly so `--help` doubles as the discovery surface for v1 (per design D4 / decision 4: no `omarchy/README.md` entry until v2).

**Verification**:
- [ ] `bash -n scripts/cleanup-omarchy` parses clean
- [ ] `chmod +x scripts/cleanup-omarchy`; `scripts/cleanup-omarchy --help` exits 0
- [ ] `scripts/cleanup-omarchy -h` exits 0 (same output as `--help`)
- [ ] `scripts/cleanup-omarchy --bogus` exits 2, stderr contains "Unknown argument"
- [ ] `scripts/cleanup-omarchy --help` output contains every flag (`--interactive`, `--dry-run`, `--list`, `--yes`, `--help`, `-h`) and the four category names

---

### T-002: Constants + inline arrays (STUBS, PKGS, WEBAPPS, TUIS) with the 29 names

**Files**:
- `scripts/cleanup-omarchy` (modify) — append constants block and 4 inline arrays below the flag parsing loop

**Satisfies**: REQ-CLEANUP-002
**Scenarios**: #4
**Estimate**: ~35 lines

**Description**:
Add a `Constants` block (no logic) holding `REPO_ROOT` resolution (BASH_SOURCE-based since the script is invoked directly, not by root — `DOTFILES_ROOT` is informational only), `BACKUP_DIR="$REPO_ROOT/backup"`, `LOG_TEMPLATE="$BACKUP_DIR/cleanup-omarchy.<ts>.log"`, `STUB_BIN_DIR="$HOME/.local/bin"`, `DESKTOP_DIR="$HOME/.local/share/applications"`, and the four inline arrays. The arrays are populated **verbatim** from [`docs/ideas/scripts/cleanup.md`](../../docs/ideas/scripts/cleanup.md) — only the `[R]` items, never the `[K]` ones. `STUBS` holds 6 names (`codex`, `copilot`, `gemini`, `opencode`, `playwright-cli`, `pi`). `PKGS` holds 9 names (`1password-beta`, `1password-cli`, `claude-code`, `kdenlive`, `obs-studio`, `opencode`, `pinta`, `signal-desktop`, `typora`). `WEBAPPS` holds 14 names including `"Google Contacts"` and `"Xbox Cloud Gaming"` as quoted strings to preserve spaces. `TUIS=()` is intentionally empty. Each array has a `# N items` comment so a future maintainer can see counts at a glance. Names with spaces in `WEBAPPS` MUST be double-quoted so `WEBAPPS+=(Google Contacts)` would be a bug; the quoted form is the contract. Per decision 1, this file is the source of truth — `docs/ideas/scripts/cleanup.md` is rationale, not a parser input.

**Verification**:
- [ ] `bash -n scripts/cleanup-omarchy` still parses clean after the addition
- [ ] `bash -c 'source <(awk "/^STUBS=/,/)/" scripts/cleanup-omarchy); echo "${#STUBS[@]}"'` prints `6`
- [ ] Same probe for `PKGS` prints `9`; `WEBAPPS` prints `14`; `TUIS` prints `0`
- [ ] `bash -c 'source <(awk "/^WEBAPPS=/,/)/" scripts/cleanup-omarchy); for n in "${WEBAPPS[@]}"; do [[ "$n" == "Google Contacts" || "$n" == "Xbox Cloud Gaming" ]] || continue; echo "OK: $n"; done'` prints `OK:` twice (names with spaces preserved as one item each)
- [ ] `git diff scripts/cleanup-omarchy` shows no `[K]` names from `cleanup.md` (sanity check: `WhatsApp`, `Spotify`, `lazydocker`, `Docker`, `obsidian`, etc. absent)

---

### T-003: Helpers — `log`, `warn`, `fail`, `require_command`, `now_utc`

**Files**:
- `scripts/cleanup-omarchy` (modify) — append helpers section

**Satisfies**: (foundation; no direct scenario)
**Scenarios**: (none — used by every later task)
**Estimate**: ~20 lines

**Description**:
Add the five standard helpers below the inline arrays. `log` prints `[cleanup-omarchy] $*` to stdout; `warn` prints `[cleanup-omarchy] WARN: $*` to stderr; `fail` prints `[cleanup-omarchy] ERROR: $*` to stderr and `exit 1`. `require_command "$cmd"` calls `command -v "$cmd" >/dev/null 2>&1` and `fail`s with a "Required command '$cmd' is not on PATH" message if missing. `now_utc` echoes `$(date -u +%FT%TZ)` — the ISO-8601 timestamp the audit log uses (REQ-CLEANUP-005). Mirrors the helpers in `scripts/setup-omarchy` so a reader familiar with that script can navigate this one. Tag prefix is `[cleanup-omarchy]` (not `[setup-omarchy]`) — distinct script, distinct prefix. None of these helpers takes a mode flag; dry-run handling happens in `execute_plan` (T-008), not here.

**Verification**:
- [ ] `bash -n scripts/cleanup-omarchy` parses clean
- [ ] `bash -c 'source <(sed -n "/^log()/,/^}/p; /^warn()/,/^}/p; /^fail()/,/^}/p; /^require_command()/,/^}/p; /^now_utc()/,/^}/p" scripts/cleanup-omarchy); type log warn fail require_command now_utc'` lists all five functions
- [ ] `bash -c 'source scripts/cleanup-omarchy 2>/dev/null; require_command bash && echo OK' 2>&1 || true` prints `OK` (bash is on PATH; the function is wired)
- [ ] `bash -c 'source scripts/cleanup-omarchy 2>/dev/null; require_command definitely-not-on-path-xyz 2>&1; echo "rc=$?"'` prints the "Required command" message and `rc=1`

---

### T-004: `is_installed(category, name)` idempotency probe

**Files**:
- `scripts/cleanup-omarchy` (modify) — append `is_installed` after the helpers

**Satisfies**: REQ-CLEANUP-007
**Scenarios**: #10
**Estimate**: ~25 lines

**Description**:
Implement `is_installed(category, name) -> bool` as a per-category dispatch (case statement on `$category`). Probes are read-only — they never modify the system, only test presence. For `stubs`, return success iff `[ -e "$STUB_BIN_DIR/$name" ]`. For `packages`, return success iff `pacman -Qq "$name" >/dev/null 2>&1` (matches the contract `omarchy-pkg-drop` itself checks internally, so the probe and the real call agree on what "installed" means). For `webapps` and `tuis`, return success iff `[ -e "$DESKTOP_DIR/$name.desktop" ]` (the canonical "is this a webapp/tui" signal in Omarchy — `omarchy-webapp-remove` and `omarchy-tui-remove` both `rm -f` that path). Unknown category → return 1 and log a warning. The function does NOT log the `skipped` line itself — that's `execute_plan`'s job (T-008). The probe returning 0/1 is the only contract here; the caller decides what to do with the verdict. Per the design's idempotency table, a re-run on a fully cleaned system produces 29 `skipped` lines across the 3 non-empty categories.

**Verification**:
- [ ] `bash -n scripts/cleanup-omarchy` parses clean
- [ ] `bash -c 'source scripts/cleanup-omarchy 2>/dev/null; HOME=/tmp; STUB_BIN_DIR=$HOME/.local/bin; touch $STUB_BIN_DIR/test-stub; is_installed stubs test-stub && echo "stubs-yes" || echo "stubs-no"; is_installed packages definitely-not-installed-xyz 2>/dev/null; echo "packages-rc=$?"' 2>&1 || true` prints `stubs-yes` and `packages-rc=1` (probe correctly distinguishes presence / absence for two categories)
- [ ] `bash -c 'source scripts/cleanup-omarchy 2>/dev/null; is_installed unknown-cat foo 2>&1; echo "rc=$?"'` returns non-zero and prints a warning mentioning `unknown-cat`
- [ ] `bash -c 'source scripts/cleanup-omarchy 2>/dev/null; is_installed webapps "Xbox Cloud Gaming"; echo rc=$?'` returns 1 (no `.desktop` file in test home) — proves the probe handles quoted names with spaces correctly

---

### T-005: `build_plan()` — assembles plan from 4 arrays, skips empty categories

**Files**:
- `scripts/cleanup-omarchy` (modify) — append `build_plan` after `is_installed`

**Satisfies**: REQ-CLEANUP-002
**Scenarios**: #4
**Estimate**: ~20 lines

**Description**:
Implement `build_plan() -> array`. Iterate the four category pairs in fixed order: `stubs` → `packages` → `webapps` → `tuis`. For each, iterate the corresponding array. For each name, emit a row of the form `<category-singular>\t<name>\t<command>` where `<command>` is the literal shell line that will be logged and (in non-dry-run) executed. Command construction is a per-category mapping: `stubs` → `rm -f "$STUB_BIN_DIR/$name"`; `packages` → `omarchy-pkg-drop $name` (unquoted in the log so it's greppable; the name is passed unquoted because Omarchy package names cannot contain spaces); `webapps` → `omarchy-webapp-remove "$name"`; `tuis` → `omarchy-tui-remove "$name"`. The category-singular in the audit log is `stub` / `pkg` / `webapp` / `tui` (REQ-CLEANUP-005 specifies singular lowercase in the log). **Skip empty categories entirely** — when the `TUIS` array is empty, the tui branch never iterates and the category never appears in the plan. This is the D5 / REQ-CLEANUP-002 contract: no "(none)" sentinel, no false advertising in `grep` output. The function appends to a local `plan_array` and echoes nothing — caller reads it via `mapfile -t plan < <(build_plan)` or by capturing `$(build_plan)` and splitting.

**Verification**:
- [ ] `bash -n scripts/cleanup-omarchy` parses clean
- [ ] `bash -c 'source scripts/cleanup-omarchy 2>/dev/null; mapfile -t p < <(build_plan); echo "rows=${#p[@]}"'` prints `rows=29` (6 + 9 + 14 + 0)
- [ ] `bash -c 'source scripts/cleanup-omarchy 2>/dev/null; mapfile -t p < <(build_plan); printf "%s\n" "${p[@]}" | grep -c "^tui\t"'` prints `0` (TUIs section absent from plan)
- [ ] `bash -c 'source scripts/cleanup-omarchy 2>/dev/null; mapfile -t p < <(build_plan); printf "%s\n" "${p[@]}" | grep "Xbox Cloud Gaming"'` shows a row with the name quoted in the command column (e.g. `omarchy-webapp-remove "Xbox Cloud Gaming"`)
- [ ] `bash -c 'source scripts/cleanup-omarchy 2>/dev/null; mapfile -t p < <(build_plan); printf "%s\n" "${p[@]}" | awk -F"\t" "{print \$1}" | sort -u'` prints exactly `pkg`, `stub`, `webapp` (three category names; tui absent because TUIS is empty)

---

### T-006: `interactive_pick(plan)` — `gum choose --no-limit` with deselection

**Files**:
- `scripts/cleanup-omarchy` (modify) — append `interactive_pick` after `build_plan`

**Satisfies**: REQ-CLEANUP-009
**Scenarios**: #12
**Estimate**: ~30 lines

**Description**:
Implement `interactive_pick(plan_in) -> plan_out`. Build the picker rows from `$plan_in`: one row per item, formatted as `<category>\t<name>\t<command>` (the same shape `build_plan` produces — no transformation). Pass the rows to `gum choose --no-limit --selected=<comma-list-of-everything>` so all 29 items are pre-selected. Capture the user's deselection via `gum choose`'s stdout (newline-separated rows). The user can deselect any number of items; an empty selection means "remove nothing" (still proceeds to confirm_safety, which the user can decline). The function then filters `$plan_in` to only the rows the user kept and echoes the filtered plan. **Empty categories never appear in the picker** — they are absent from `$plan_in` to begin with (D5 / T-005), so this is automatic. The TTY guard (`[[ -t 0 ]]`) is NOT this function's responsibility — it lives in `main` (T-009) so the error message is a single, dispatcher-owned diagnostic, not scattered across helpers. If `gum` is missing on PATH, `require_command gum` at the top of the function fails fast with a clear message.

**Verification**:
- [ ] `bash -n scripts/cleanup-omarchy` parses clean
- [ ] `type interactive_pick` shows the function is defined
- [ ] `scripts/cleanup-omarchy --help` still exits 0 (no regression in the dispatcher)
- [ ] `bash -c 'source scripts/cleanup-omarchy 2>/dev/null; require_command gum 2>&1; echo rc=$?'` returns non-zero with "Required command 'gum'" when gum is absent (proves the `require_command` guard wires up correctly — full picker test requires gum, which is host-dependent)
- [ ] `bash -c 'source scripts/cleanup-omarchy 2>/dev/null; mapfile -t p < <(build_plan); printf "%s\n" "${p[@]}" | grep -c "^-"` prints `0` (no plan rows start with `-` — proves `gum choose` won't misinterpret a row as a flag; this is a unit-level guard for the row format)

---

### T-007: `confirm_safety(plan)` — `gum confirm` with category-grouped full commands

**Files**:
- `scripts/cleanup-omarchy` (modify) — append `confirm_safety` after `interactive_pick`

**Satisfies**: REQ-CLEANUP-003, REQ-CLEANUP-004
**Scenarios**: #5, #6, #7
**Estimate**: ~25 lines

**Description**:
Implement `confirm_safety(plan) -> 0 | 1`. Build the confirm message body from `$plan`: group rows by category (the leading tab-field) and render each group as a header (`stubs:`, `packages:`, `webapps:`, `tuis:` — though `tuis:` only appears if the plan has any tui rows, which v1 does not) followed by indented lines showing the **full command** for each item (the third tab-field). Empty categories are absent (they were absent from `$plan` to begin with). The whole body is piped to `gum confirm --affirmative="Proceed" --negative="Abort" --prompt.bold="..."` and the prompt returns the user's choice on stdout / exit code. The function returns 0 if the user accepted, 1 if the user declined. On decline, `main` (T-009) prints `aborted by user` to stdout and exits 0 — **do NOT** print the message here; the contract is one canonical abort message owned by the dispatcher. Per decision 7 / REQ-CLEANUP-003, the confirm must show the full command per item, not just names — the user is approving a specific shell line, not a category-level "yes I'll remove things". Names with spaces are pre-quoted in the third tab-field by `build_plan`, so the confirm text shows the correct `omarchy-webapp-remove "Xbox Cloud Gaming"` line.

**Verification**:
- [ ] `bash -n scripts/cleanup-omarchy` parses clean
- [ ] `type confirm_safety` shows the function is defined
- [ ] `scripts/cleanup-omarchy --help` still exits 0
- [ ] `bash -c 'source scripts/cleanup-omarchy 2>/dev/null; mapfile -t p < <(build_plan); confirm_safety <(printf "%s\n" "${p[@]}") 2>&1; echo rc=$?'` (interactive test requires gum + TTY; this is a contract check that the function exists and accepts the plan)
- [ ] `grep -c "gum confirm" scripts/cleanup-omarchy` prints `1` (single confirm call site, no duplicate prompts)

---

### T-008: `execute_plan(plan, log_path, mode)` — runs each command, logs result, fails fast

**Files**:
- `scripts/cleanup-omarchy` (modify) — append `execute_plan` after `confirm_safety`

**Satisfies**: REQ-CLEANUP-004, REQ-CLEANUP-005, REQ-CLEANUP-006, REQ-CLEANUP-007
**Scenarios**: #7, #8, #9, #10
**Estimate**: ~30 lines

**Description**:
Implement `execute_plan(plan, log_path, mode)` where `mode` is one of `run` or `dry-run`. Open the log file with `exec` redirection (or `tee` per design) so each row is appended as it is written. For each row in `$plan` (TSV: `category\tnames\tcommand`): (1) parse the three tab fields into local variables; (2) call `is_installed "$category" "$name"`; (3) if the probe says "not installed", write a row with result `skipped: not present` and continue (REQ-CLEANUP-007); (4) if `mode == dry-run`, write a row with result `dry-run` and **do not invoke the command** (REQ-CLEANUP-001 scenario #3); (5) otherwise, invoke the command (`rm -f` for stubs, `omarchy-pkg-drop` for packages, etc.) and capture the exit code. On exit 0, write a row with result `ok`. On non-zero exit, write a row with result `fail: exit N`, echo `$log_path` to stderr, and `exit 1` — **fail fast, skip subsequent items** (REQ-CLEANUP-006). The audit log format is `ts\tcategory\tnames\tcommand\tresult` where `ts` is `now_utc` and `category` is singular lowercase (`stub` / `pkg` / `webapp` / `tui`) per the design. `name` is raw (no quotes) so `awk -F'\t' '$2=="webapp" && $3 ~ /Xbox/'` works; `command` carries the pre-quoted form. `mkdir -p "$BACKUP_DIR"` runs once before the loop.

**Verification**:
- [ ] `bash -n scripts/cleanup-omarchy` parses clean
- [ ] `type execute_plan` shows the function is defined
- [ ] `scripts/cleanup-omarchy --help` still exits 0
- [ ] `bash -c 'source scripts/cleanup-omarchy 2>/dev/null; mapfile -t p < <(build_plan); mkdir -p /tmp/cleanup-test; log_path=/tmp/cleanup-test/out.log; execute_plan <(printf "%s\n" "${p[@]}") "$log_path" dry-run 2>&1; echo "rc=$?"; wc -l < "$log_path"'` — in a sandbox with no items actually installed, this should exit 0 and the log should have 29 lines (all `skipped` since the probe finds nothing)
- [ ] `bash -c 'source scripts/cleanup-omarchy 2>/dev/null; mapfile -t p < <(build_plan); mkdir -p /tmp/cleanup-test2; log_path=/tmp/cleanup-test2/out.log; execute_plan <(printf "%s\n" "${p[@]}") "$log_path" dry-run; awk -F"\t" "{print \$NF}" "$log_path" | sort | uniq -c'` — all 29 rows show `skipped: not present` (no `ok` / `fail` / `dry-run` in dry-run-of-empty-system, because the probe catches everything first)
- [ ] A second `--dry-run` invocation on the same empty system produces the same 29 `skipped` lines (idempotency proven)

---

### T-009: Main dispatcher — flags → modes → plan → confirm/execute

**Files**:
- `scripts/cleanup-omarchy` (modify) — replace the empty `main()` placeholder with the full dispatcher

**Satisfies**: REQ-CLEANUP-001, REQ-CLEANUP-010, REQ-CLEANUP-008
**Scenarios**: #1, #2, #3, #11, #13
**Estimate**: ~25 lines

**Description**:
Implement `main "$@"` as the orchestrator. The current `main()` from T-001 is a placeholder; this task replaces it. Sequence: (1) pre-parse flag variables set in T-001 (no parsing change; T-001 already handles `--help`); (2) require `gum` and `date` and `mkdir` and `tee` up front with `require_command`; (3) for `--list` and `--dry-run`, `set +e` is unnecessary — `set -e` is correct because both branches either exit 0 cleanly or `fail`; (4) if `--list` (alone; not combined with `--dry-run` / `--yes` / `--interactive`), call `build_plan`, print category-grouped plan, exit 0 — this is the early branch T-010 covers; (5) if `--dry-run` (alone), set the mode flag, then fall through to build + confirm-skip + execute-plan with `mode=dry-run`; (6) for any other case, build the plan, run `interactive_pick` if `--interactive` is set, run `confirm_safety` unless `--yes` is set, then `execute_plan` with `mode=run`. **Non-TTY guard** (REQ-CLEANUP-010): if `--interactive` is set and `[[ ! -t 0 ]]`, print a clear `--interactive requires a TTY` message to stderr and `exit 1`. **Mutually-exclusive guard** (REQ-CLEANUP-001 / decision 8): if `--list` is set with `--yes` / `--dry-run` / `--interactive`, print a single-line `--list is mutually exclusive with --yes / --dry-run / --interactive` to stderr and `exit 2`. On successful execution, print the log path to stdout (REQ-CLEANUP-005). On failure, the log path is already printed to stderr by `execute_plan`; main does not duplicate it.

**Verification**:
- [ ] `bash -n scripts/cleanup-omarchy` parses clean
- [ ] `scripts/cleanup-omarchy --help` exits 0
- [ ] `scripts/cleanup-omarchy --list --yes 2>&1; echo "rc=$?"` — stderr contains "mutually exclusive", `rc=2`
- [ ] `scripts/cleanup-omarchy --list --dry-run 2>&1; echo "rc=$?"` — same error, `rc=2`
- [ ] `scripts/cleanup-omarchy --list --interactive 2>&1; echo "rc=$?"` — same error, `rc=2`
- [ ] `scripts/cleanup-omarchy --interactive < /dev/null 2>&1; echo "rc=$?"` — stderr contains "TTY", `rc=1` (REQ-CLEANUP-010)
- [ ] `scripts/cleanup-omarchy --bogus 2>&1; echo "rc=$?"` — `rc=2` (unknown arg still rejected)

---

### T-010: `--list` mode (verification branch)

**Files**:
- `scripts/cleanup-omarchy` (verify) — the `--list` branch added in T-009

**Satisfies**: REQ-CLEANUP-001, REQ-CLEANUP-009, REQ-CLEANUP-008
**Scenarios**: #1 (partial), #11
**Estimate**: ~5 lines (mostly verification)

**Description**:
The `--list` branch in `main` (T-009) prints the categorized plan to stdout and exits 0. This task is a **verification** task: confirm that `scripts/cleanup-omarchy --list` matches the design's behavior exactly. It MUST print the three non-empty category groups (`stubs:`, `packages:`, `webapps:`) with one line per item showing the full command. It MUST NOT print a `tuis:` header (TUIs array is empty — REQ-CLEANUP-002 / D5). It MUST NOT create any file under `backup/` (decision 8: pure discovery, no log writes). It MUST NOT require a TTY (REQ-CLEANUP-001: `--list` works in CI). It MUST exit 0 on every system state (no probing — the hardcoded list is the answer, period). It MUST NOT mention `omarchy update` drift in its output (the preamble comment is enough; `--list` is the plan, not the rationale). After the change, `find backup -name 'cleanup-omarchy.*.log' -newer /tmp/marker 2>/dev/null` MUST print nothing — `--list` is read-only.

**Verification**:
- [ ] `scripts/cleanup-omarchy --list` exits 0
- [ ] `scripts/cleanup-omarchy --list` stdout contains `stubs:`, `packages:`, `webapps:`
- [ ] `scripts/cleanup-omarchy --list` stdout does NOT contain `tuis:` (TUIs array is empty)
- [ ] `scripts/cleanup-omarchy --list < /dev/null` exits 0 (no TTY required)
- [ ] Before/after: `ls backup/cleanup-omarchy.*.log 2>/dev/null | wc -l` is unchanged after `--list` runs (no audit log written)

---

### T-011: `--dry-run` mode (verification branch)

**Files**:
- `scripts/cleanup-omarchy` (verify) — the `--dry-run` branch added in T-009

**Satisfies**: REQ-CLEANUP-001, REQ-CLEANUP-005
**Scenarios**: #3, #8
**Estimate**: ~5 lines (mostly verification)

**Description**:
The `--dry-run` branch in `main` (T-009) sets the mode and falls through to `execute_plan(..., mode=dry-run)`. This task is a **verification** task: confirm the branch matches the design's contract. It MUST print every removal command to stdout (via `execute_plan`); it MUST write a `dry-run` result line per item to a timestamped audit log under `backup/`; it MUST NOT mutate the system (no `rm`, no `omarchy-pkg-drop`, no `omarchy-webapp-remove`, no `omarchy-tui-remove` is actually invoked — only the probe + log write). It MUST skip the safety confirm (decision 2 / REQ-CLEANUP-001 scenario #3: `--dry-run` is a simulation, not a destructive run, so prompting is friction). It MUST exit 0 even if all probes report "not installed" (that's the empty-system case, log lines are `skipped` not `dry-run` — the probe runs first and short-circuits; the user's expected audit shape is 29 rows of `skipped` or `dry-run`, both legal). It MUST NOT require a TTY. After the run, the audit log file is timestamped with `$(date -u +%Y%m%dT%H%M%SZ)` per REQ-CLEANUP-005.

**Verification**:
- [ ] `scripts/cleanup-omarchy --dry-run` exits 0
- [ ] `scripts/cleanup-omarchy --dry-run` does NOT show a `gum confirm` prompt (auto-skip; gum is not invoked)
- [ ] `scripts/cleanup-omarchy --dry-run` creates exactly one new file matching `backup/cleanup-omarchy.*.log`
- [ ] `awk -F'\t' '{print $NF}' "$(ls -t backup/cleanup-omarchy.*.log | head -1)" | sort | uniq -c` — the dry-run log contains rows with result `dry-run` for items the probe says are installed; on a clean system the log is all `skipped`
- [ ] `scripts/cleanup-omarchy --dry-run < /dev/null` exits 0 (no TTY required)
- [ ] `find ~/.local/share/omarchy -newer /tmp/before-marker 2>/dev/null` is empty after `--dry-run` (REQ-CLEANUP-011: forbidden path never touched, even read-only)

---

### T-012: `tests/cleanup-omarchy.bash` TAP harness (optional)

**Files**:
- `tests/cleanup-omarchy.bash` (new) — TAP harness, mirrors `tests/setup-deps.bash`

**Satisfies**: REQ-CLEANUP-001, REQ-CLEANUP-002, REQ-CLEANUP-007, REQ-CLEANUP-009, REQ-CLEANUP-010
**Scenarios**: #1, #2, #3, #4, #5, #8, #10, #13
**Estimate**: ~50 lines

**Description**:
OPTIONAL — per `openspec/config.yaml` `strict_tdd: false`, this task may be deferred by the apply phase if the script's manual smoke tests are sufficient. The harness mirrors `tests/setup-deps.bash` (TAP-ish, `ok N - <name>` / `not ok N - <name>`, no external framework, stubs for `gum` / `omarchy-pkg-drop` / `omarchy-webapp-remove` / `omarchy-tui-remove` on a sandbox PATH). Seven asserts from the design's test strategy: T1 `--help` exits 0 and lists every flag; T2 `--list` exits 0, contains `stubs:` / `packages:` / `webapps:` headers, does NOT contain `tuis:`; T3 `--dry-run` exits 0, writes a `backup/cleanup-omarchy.*.log` with 29 lines containing `dry-run`; T4 a second `--dry-run` produces 29 `skipped` lines (idempotency); T5 `--list --dry-run` exits non-zero (mutually exclusive); T6 `--interactive` on non-TTY (`< /dev/null`) exits non-zero with TTY-required message; T7 `omarchy-pkg-drop` is invoked with all 9 `[R]` package names in non-dry-run mode (proven via stub log on a sandbox with stub `pacman` returning installed for those names). The harness is `bash tests/cleanup-omarchy.bash` and exits 0 only on full pass. If skipped, document the deferral in the apply report and rely on the manual smoke checks from T-010 / T-011.

**Verification**:
- [ ] `bash -n tests/cleanup-omarchy.bash` parses clean
- [ ] `bash tests/cleanup-omarchy.bash` exits 0 with all 7 asserts passing
- [ ] T1: `--help` output contains every flag string (`--interactive`, `--dry-run`, `--list`, `--yes`, `--help`)
- [ ] T2: `--list` stdout contains `stubs:`, `packages:`, `webapps:`, does NOT contain `tuis:`
- [ ] T3 / T4: two consecutive `--dry-run` invocations produce the same log shape, first mostly `dry-run`, second mostly `skipped`
- [ ] T5 / T6: mutual-exclusion + non-TTY guards return non-zero with the documented error
- [ ] T7: stub `omarchy-pkg-drop` log contains all 9 package names from the `[R]` list

---

### T-013: `omarchy/README.md` entry — DEFER to v2

**Files**:
- (none in v1)

**Satisfies**: (out of scope; design D4 / decision 4)
**Scenarios**: (none)
**Estimate**: 0 lines

**Description**:
Per design D4 and proposal decision 4, v1 of `cleanup-omarchy` does NOT add an entry to `omarchy/README.md`. The script is discoverable via `scripts/cleanup-omarchy --help`, which lists every flag, every category, and the audit log path. Adding a `omarchy/README.md` entry is a v2 ask — likely coupled with v2 features (drift re-detection, rollback helper, etc.) so the README entry can point to a more complete workflow. This task exists in the breakdown so the deferral is **explicit** in the change folder, not a silent omission. The apply phase MUST NOT add the README entry in v1; doing so would violate decision 4 and force a re-decide.

**Verification**:
- [ ] `git diff --stat omarchy/README.md` after the apply shows zero changes
- [ ] `scripts/cleanup-omarchy --help` exits 0 and the output is the only discovery surface for v1
- [ ] A code-review comment or commit message notes the v2 follow-up so the deferral is traceable

---

## Acceptance for the apply phase

The apply phase can mark this change done when:

1. All twelve implementation tasks (T-001..T-011) pass their verification checklists, plus T-013 is confirmed as a deliberate no-op.
2. The T-012 TAP harness either passes all 7 asserts OR the apply report documents the deferral with a manual-smoke-test substitute.
3. `scripts/cleanup-omarchy --help` exits 0, `--list` exits 0 with the right output, and `--dry-run` exits 0 with a correctly-shaped audit log.
4. The diff is under the 400-line budget (current estimate: ~300 lines, well under).
5. No file outside `scripts/cleanup-omarchy`, `tests/cleanup-omarchy.bash`, and runtime `backup/cleanup-omarchy.*.log` is touched. In particular: `omarchy/README.md`, root `./setup`, `shared/`, `docs/conventions.md`, and `AGENTS.md` are all untouched (per design D4 / D5 / decision 4 / decision 5).

## Relevant files (for the next phase)

- `openspec/changes/cleanup-omarchy/tasks.md` — this file
- `openspec/changes/cleanup-omarchy/proposal.md` — 9 locked decisions
- `openspec/changes/cleanup-omarchy/specs/omarchy-preinstall-cleanup/spec.md` — 11 requirements, 14 scenarios
- `openspec/changes/cleanup-omarchy/design.md` — 10 architecture decisions, file structure, flag matrix
- `scripts/setup-omarchy` — template the new script mirrors
- `tests/setup-deps.bash` — TAP harness template
- `docs/ideas/scripts/cleanup.md` — rationale for the 29-item list (NOT a parser input)
- `scripts/cleanup-omarchy` — new file created by T-001..T-009
- `tests/cleanup-omarchy.bash` — new optional file created by T-012
