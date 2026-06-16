# Archive Report: cleanup-omarchy

> **Change**: `cleanup-omarchy`
> **Capability**: `omarchy-preinstall-cleanup`
> **Archiver**: `sdd-archive` sub-agent
> **Mode**: `openspec` (file-based)
> **Strict TDD**: `false` (per `openspec/config.yaml`)
> **Commit policy**: NO COMMIT (per orchestrator preflight; user explicitly opted out)
> **Date archived (UTC)**: 2026-06-16
> **Branch at archive time**: `main`
> **Commit at archive time**: `a0b4fe6c70169f6a46e7fa96dedb9e060e5948c1` (`chore(nvim): use yamlls as preferred YAML formatter`)

## 1. Verdict from verify

`archive-ready` (per `verify-report.md` § 12).

- **CRITICAL**: 0
- **WARNING**: 1 — REQ-CLEANUP-007 / "re-run on a clean system is a no-op" requires a destructive first run; the verifier confirmed the code path is correct and the probe is stable across two `--dry-run` invocations, but the literal "29 `skipped` lines on a clean re-run" cannot be observed without performing the destructive first run on a real Omarchy host. **This is the only known follow-up.**
- **SUGGESTION**: 2 — `require_command tee` at line 444 is a no-op guard (the log is written via `printf ... >> "$log_path"`, not `tee`); the 5-field TSV shape is confirmed by inspection but not auto-asserted by a test.

## 2. Task completion gate

The `sdd-archive` Task Completion Gate was checked against `tasks.md`,
`apply-progress.md`, and `verify-report.md` before syncing specs and
moving the change folder.

| # | Status | Evidence |
| - | --- | --- |
| T-001 | done | `apply-progress.md` table; `verify-report.md` REQ-CLEANUP-001 + REQ-CLEANUP-011 evidence |
| T-002 | done | `apply-progress.md` table; inline arrays 6+9+14+0=29 verbatim from `docs/ideas/scripts/cleanup.md` |
| T-003 | done | `apply-progress.md` table; helpers present and type-checked |
| T-004 | done | `apply-progress.md` table; per-category probe; tolerates missing `pacman` |
| T-005 | done | `apply-progress.md` table; `build_plan` emits 29 rows in 3 categories |
| T-006 | done | `apply-progress.md` table; `interactive_pick` wired |
| T-007 | done | `apply-progress.md` table; `confirm_safety` wired |
| T-008 | done | `apply-progress.md` table; `execute_plan` per-row logging + fail-fast |
| T-009 | done | `apply-progress.md` table; main dispatcher + guards |
| T-010 | done | `apply-progress.md` table; `--list` branch verified (V6, V7, V8) |
| T-011 | done | `apply-progress.md` table; `--dry-run` branch verified (V13) |
| T-012 | **deferred (out of scope)** | Per orchestrator preflight + `strict_tdd: false`. Documented in `apply-progress.md` and `verify-report.md` § 11.6 as a low-risk v1.x follow-up, not a v1 gap. **No stale checkbox; this was never an unchecked task — it was an explicit optional task the orchestrator opted out of before apply.** |
| T-013 | **deferred (out of scope)** | Per design D4 / decision 4 (defer `omarchy/README.md` entry to v2). Documented in `apply-progress.md` and `verify-report.md` § 11.7. **A deliberate no-op, not a missed task.** |

**Gate verdict**: PASS. The two deferred tasks (T-012, T-013) are
intentional deferrals, not stale checkboxes. No exceptional
mechanical reconciliation was performed; the persisted tasks
artifact accurately reflects the final state of the change.

## 3. Final state of the working tree

```
?? scripts/cleanup-omarchy                                  ← implementation (491 lines, executable)
?? openspec/specs/omarchy-preinstall-cleanup/                ← canonical spec (synced from delta)
?? openspec/changes/archive/2026-06-16-cleanup-omarchy/      ← archived change folder
```

(`git status --short` at archive time; user opted out of commits.)

| Path | Action | Notes |
| --- | --- | --- |
| `scripts/cleanup-omarchy` | Untracked (was untracked after apply; left dirty) | 491 lines, `chmod 755` (`-rwxr-xr-x`), lint-clean |
| `openspec/specs/omarchy-preinstall-cleanup/spec.md` | Created (new canonical spec) | Byte-identical to the delta spec; 242 lines |
| `openspec/changes/archive/2026-06-16-cleanup-omarchy/` | Created (change folder moved here) | Date prefix `2026-06-16` matches today's UTC date; name suffix `cleanup-omarchy` matches the change name; mirrors the existing `2026-06-14-ideas-implementation/` convention |
| `openspec/changes/cleanup-omarchy/` | Removed (empty after moves) | `rmdir` succeeded; no leftover empty folder |
| `backup/` | Untouched | Already gitignored; runtime audit-log artifacts from apply + verify remain on disk for inspection |

## 4. Archive operations performed

### 4.1 Sync delta spec to canonical

| Source | Target | Action |
| --- | --- | --- |
| `openspec/changes/cleanup-omarchy/specs/omarchy-preinstall-cleanup/spec.md` | `openspec/specs/omarchy-preinstall-cleanup/spec.md` | Created. Canonical target did not exist, so the delta IS the full spec — copied directly (no merge needed). Verified byte-identical via `diff -q`. |

Per the sibling-spec layout convention
(`openspec/specs/setup-orchestration/spec.md`), canonical specs
live at `openspec/specs/<domain>/spec.md`. The new canonical
domain is `omarchy-preinstall-cleanup`.

### 4.2 Move change folder to archive

| From | To | Notes |
| --- | --- | --- |
| `openspec/changes/cleanup-omarchy/proposal.md` | `openspec/changes/archive/2026-06-16-cleanup-omarchy/proposal.md` | 9.8 KB; 9 locked decisions |
| `openspec/changes/cleanup-omarchy/design.md` | `openspec/changes/archive/2026-06-16-cleanup-omarchy/design.md` | 22.3 KB; 10 architecture decisions |
| `openspec/changes/cleanup-omarchy/tasks.md` | `openspec/changes/archive/2026-06-16-cleanup-omarchy/tasks.md` | 31.9 KB; 13 tasks (T-001..T-013) |
| `openspec/changes/cleanup-omarchy/apply-progress.md` | `openspec/changes/archive/2026-06-16-cleanup-omarchy/apply-progress.md` | 7.9 KB; 17 smoke checks |
| `openspec/changes/cleanup-omarchy/verify-report.md` | `openspec/changes/archive/2026-06-16-cleanup-omarchy/verify-report.md` | 22.1 KB; verdict `archive-ready` |
| `openspec/changes/cleanup-omarchy/specs/` | `openspec/changes/archive/2026-06-16-cleanup-omarchy/specs/` | Whole subtree (1 file: `omarchy-preinstall-cleanup/spec.md`, 9.1 KB) |

`git mv` was rejected because the source files are untracked
(`openspec/` is versioned in git per `openspec/config.yaml`, but
these specific files were created in the apply phase and the
user opted out of commits — they were never staged). Plain
filesystem `mv` was used; this is the correct move for
untracked artifacts. Final state shows them as
`?? openspec/changes/archive/2026-06-16-cleanup-omarchy/` (the
entire archive subtree is untracked at archive time; the user
will commit the change as a single unit later if they choose).

## 5. Summary of the change

`scripts/cleanup-omarchy` is a new standalone bash script that
selectively removes 29 Omarchy preinstalls (6 npx stubs, 9
packages, 14 web apps) while keeping the 12 the user actually
uses. It uses Omarchy's public APIs only (`omarchy-pkg-drop`,
`omarchy-webapp-remove`, `omarchy-tui-remove`, plus `rm` on
`~/.local/bin/<stub>`) — never touches `~/.local/share/omarchy/`.
It is idempotent (per-category skip probes), audited (one TSV
log per run under `backup/`), and gated by a single `gum
confirm` showing the full command for every item. Five flags
(`--interactive`, `--dry-run`, `--list`, `--yes`, `--help`); the
script is not wired to root `./setup` (deliberate per decision
5) and has no `omarchy/README.md` entry in v1 (deferred to v2
per decision 4).

## 6. Linked artifacts (paths after archive)

| Artifact | Path | Status |
| --- | --- | --- |
| Implementation | `scripts/cleanup-omarchy` | Untracked; 491 lines; executable |
| Canonical spec | `openspec/specs/omarchy-preinstall-cleanup/spec.md` | Untracked; 242 lines; new |
| Archived proposal | `openspec/changes/archive/2026-06-16-cleanup-omarchy/proposal.md` | Untracked; 150 lines |
| Archived design | `openspec/changes/archive/2026-06-16-cleanup-omarchy/design.md` | Untracked; 383 lines |
| Archived tasks | `openspec/changes/archive/2026-06-16-cleanup-omarchy/tasks.md` | Untracked; 354 lines |
| Archived apply-progress | `openspec/changes/archive/2026-06-16-cleanup-omarchy/apply-progress.md` | Untracked; 134 lines |
| Archived verify-report | `openspec/changes/archive/2026-06-16-cleanup-omarchy/verify-report.md` | Untracked; 174 lines |
| Archived delta spec (now redundant, kept for audit) | `openspec/changes/archive/2026-06-16-cleanup-omarchy/specs/omarchy-preinstall-cleanup/spec.md` | Untracked; 242 lines; byte-identical to canonical |
| Runtime audit logs (apply + verify smoke runs) | `backup/cleanup-omarchy.20260616T*.log` | Gitignored; 6 files, 2170-2446 bytes each |

## 7. Known follow-ups (from verify-report § 11)

1. **Real-run idempotency on a real Omarchy host** (WARNING; **the one follow-up the user should action**).
   - The user should run `scripts/cleanup-omarchy --yes` once on a real Omarchy install to perform the destructive first run, then re-run it to confirm 29 `skipped: not present` lines and zero removal calls. The code path is correct (`is_installed` + `execute_plan` skipped branch) and the probe is stable across `--dry-run` invocations (V15 in `verify-report.md`), but the literal "29 `skipped` on a clean re-run" can only be observed end-to-end.
2. **Optional v1.x: add `tests/cleanup-omarchy.bash` TAP harness** (T-012). 7 asserts from the design's test strategy would catch regressions in the helper functions, the mutual-exclusion guards, and the non-TTY guard.
3. **Optional v2: add `omarchy/README.md` entry** (T-013). Should be coupled with v2 features (drift re-detection, rollback helper) so the README entry can point to a more complete workflow.
4. **Optional cleanup: remove the no-op `require_command tee` at line 444** (SUGGESTION). Either remove the line or switch the log write to a `tee` invocation that also echoes to stdout.

## 8. Things NOT done (per session constraints)

- **No commits**, **no pushes**, **no PRs** — the user opted out. The working tree is left dirty for the user to commit when ready.
- **No edits to** `shared/`, `omarchy/`, `fedora/`, `docs/`, `AGENTS.md`, `README.md`, `docs/conventions.md`, or any existing script under `scripts/`. Verified via `git status --short`: only the three new paths above appear.
- **No run of `scripts/cleanup-omarchy` in any mutating mode** — only `apply-progress.md` and `verify-report.md` exercised the script during prior phases (all in `--list` / `--dry-run --yes` / `--help` modes that do not mutate the system).
- **No touch of `~/.local/share/omarchy/`** — the script never references it; `stat` before/after `--dry-run` confirmed the mtime is unchanged.
- **No git config changes**, no `--no-verify`, no force-push, no tag operations.

## 9. SDD cycle

Complete. The change has been proposed (`proposal.md`), specified
(`specs/omarchy-preinstall-cleanup/spec.md`), designed
(`design.md`), task-planned (`tasks.md`), implemented
(`scripts/cleanup-omarchy`), verified (`verify-report.md`
verdict: `archive-ready`), and archived (this report). The
canonical spec `openspec/specs/omarchy-preinstall-cleanup/spec.md`
is now the source of truth; the archived delta is kept as
audit trail. The change is closed.

The next change may be initiated at the user's discretion.
