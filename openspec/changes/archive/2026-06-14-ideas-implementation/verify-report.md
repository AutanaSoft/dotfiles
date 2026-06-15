# Verification Report — ideas-implementation (r2)

Status: PASS
Verdict: PASS

**Change**: `ideas-implementation`
**Version**: N/A (delta spec; no `openspec/specs/` baseline)
**Mode**: Strict TDD
**Verify session**: dotfiles-ideas-impl-verify-2026-06-14-r2
**Date**: 2026-06-14
**Reason for rerun**: Prior verify ended with non-blocking notes because the spec
required `docs/setup.md` to enumerate the 5 exported variables and document
the dispatcher-vs-env-script boundary in detail. The spec was narrowly
adjusted so `docs/setup.md` is now expected to be functional user
documentation; the detailed contract lives in OpenSpec and the scripts
themselves. Behavior requirements did not change.

## Completeness

| Metric | Value |
|--------|-------|
| Tasks total | 7 (WU-1 … WU-7) |
| Tasks complete | 7 / 7 |
| Tasks incomplete | 0 |
| Spec scenarios | 26 (per `specs/setup-orchestration/spec.md`) |
| Tests run | 7 / 7 pass (TEST_PLAN=7) |
| Effective assertions (incl. sub-cases) | 11 (T1=1, T2=2, T3=2, T4=4, T5=2, T6=2, T7=5) |

Apply state (per Engram observation #1374, topic
`sdd/ideas-implementation/apply-progress`): `all_done`. All 14 acceptance
criteria from the design checklist are met at the source level
(verified by inspection + tests below).

## Build & Tests Execution

**Build**: N/A — bash scripts; no compile step.

**Test runner**: `bash tests/setup-deps.bash`

```text
$ bash tests/setup-deps.bash
1..7
ok 1 - root --omarchy invokes setup-omarchy exactly once
ok 2 - --omarchy --fonts and --omarchy --deps are absorbed by root
ok 3 - --fedora (any combo) short-circuits to not-implemented and exits 0
ok 4 - --fonts runs only setup-fonts; --deps runs only setup-deps
ok 5 - env-script pre-flight handles missing/overridden $DOTFILES_FONTS_DIR
ok 6 - DOTFILES_* (5 vars) cleanup under env -i + trap source grep
ok 7 - scripts/setup-deps auto-detects env (yay/dnf/none) and respects override
# 7/7 passed
```

Exit code: 0.

**Coverage**: ➖ Not available — no coverage tool detected for repo-native
bash. The test file's stub-based harness covers all dispatch + auto-detect
paths explicitly.

### Manual smoke checks (additional runtime evidence)

| Invocation | Exit | Result |
|---|---|---|
| `./setup --help` | 0 | Prints full usage; lists `--omarchy`, `--fedora`, `--fonts`, `--deps`, `--dry-run`, `--help`, `-h`; documents 5 exported vars in usage text; describes dispatcher contract. |
| `./setup --fedora` | 0 | `[setup] WARN: Fedora env executor is not implemented yet. See fedora/README.md for manual setup.` then `[setup] Setup complete (no changes).` No sub-scripts invoked. |
| `./setup --omarchy --fedora` | 2 | `ERROR: --omarchy and --fedora are mutually exclusive.` + usage. |
| `./setup` (no args) | 2 | `ERROR: choose --omarchy, --fedora, --fonts, --deps, or any combination.` + usage. |
| `./setup --unknown-flag` | 2 | `Unknown argument: --unknown-flag` to stderr + usage. |
| `./setup --dry-run --deps` | 0 | `[setup] Dispatching to: setup-deps` → setup-deps auto-detects omarchy (yay is on host PATH), all 5 packages reported installed. |
| `grep -nE 'run_deps\|run_fonts\|run_env\|TOTAL_STEPS' setup` | n/a | Only matches the doc-comment at lines 18-19 explaining what root MUST NOT do. No active references. |
| `grep -nE 'trap .*unset DOTFILES_' setup` | n/a | Single trap line at `setup:222` listing all 5 vars. |
| `grep -nE '\$HOME/\.local/share/fonts/autanasoft' setup scripts/*` | n/a | Single canonical literal in `setup:69`; other matches are help text or fallback defaults (defense-in-depth for direct invocation when env var is unset). |

## Spec Compliance Matrix

| # | Requirement | Scenario | Test | Result |
|---|---|---|---|---|
| R-01 | Root is a thin dispatcher | root invokes exactly one env script | `T1` | ✅ COMPLIANT |
| R-02 | Root is a thin dispatcher | root does not drive a pipeline | `T1` (no other `[setup] Dispatching to: …` breadcrumb) + source grep (no `run_deps`/`run_fonts`/`run_env`/`TOTAL_STEPS` in active code) | ✅ COMPLIANT |
| R-03 | Flag contract | `--help` lists every flag | `./setup --help` output (manual) | ✅ COMPLIANT |
| R-04 | Flag contract | mutual exclusion of env flags | `./setup --omarchy --fedora` exits 2 with usage (manual) | ✅ COMPLIANT |
| R-05 | Flag contract | unknown flag fails | `./setup --unknown-flag` exits 2 with usage to stderr (manual) | ✅ COMPLIANT |
| R-06 | Flag contract | no arguments fails | `./setup` exits 2 with usage to stderr (manual) | ✅ COMPLIANT |
| R-07 | Exported vars | vars are exported before dispatch | `T6` sub-case B (trap-line grep in source confirms all 5 names) + manual dispatch run shows `[setup-deps] Detected env: omarchy` and downstream logs | ✅ COMPLIANT |
| R-08 | Exported vars | `DOTFILES_FONTS_DIR` default is computed once | `T5` sub-case A (default location, pre-flight warns) + `setup:69` single literal `$HOME/.local/share/fonts/autanasoft` (verified by grep — only one production occurrence) | ✅ COMPLIANT |
| R-09 | Cleanup | vars are unset after a successful run | `T6` sub-case A (env -i run pattern; trap-line presence) | ⚠️ PARTIAL — see Issues |
| R-10 | Cleanup | vars are unset after a child-script failure | Trap line presence (`T6` sub-case B) covers the mechanism; behavior not exercised by a child-failure test | ⚠️ PARTIAL — see Issues |
| R-11 | `--omarchy` dispatch | `--omarchy` invokes setup-omarchy once | `T1` | ✅ COMPLIANT |
| R-12 | `--omarchy` dispatch | `--omarchy --fonts` is absorbed | `T2` sub-case A | ✅ COMPLIANT |
| R-13 | `--omarchy` dispatch | pre-flight blocks env config on missing fonts | `T5` sub-case A (dry-run: pre-flight warns, no symlink created) — non-dry-run failure path is documented in `setup-omarchy:474` (`fail "Nerd Fonts not installed…"`) | ✅ COMPLIANT |
| R-14 | `--omarchy` dispatch | pre-flight is non-mutating | `T5` sub-case A: no `curl`/`unzip`/`fc-cache` invoked in stub log; pre-flight only checks `-d` + non-empty via `ls -A` | ✅ COMPLIANT |
| R-15 | `--fedora` short-circuit | `--fedora` exits 0 and skips work | `T3` sub-cases A + B (skip warning present, no `[setup-deps]`/`[setup-fonts]`/`[setup-omarchy]` tags, no PM stubs invoked) | ✅ COMPLIANT |
| R-16 | `--fonts` / `--deps` direct dispatch | `--fonts` runs only setup-fonts | `T4` sub-case A | ✅ COMPLIANT |
| R-17 | `--fonts` / `--deps` direct dispatch | `--deps` runs only setup-deps | `T4` sub-case B (asserts `[setup]` dispatch breadcrumb + `[setup-deps]` tag + absence of other dispatch tags) | ✅ COMPLIANT |
| R-18 | `--dry-run` propagation | dry-run does not mutate | All tests use `--dry-run`; T5 sub-case A explicitly runs dry-run with missing fonts and observes no install/symlink in stub log; pre-flight still runs (correct per spec) | ✅ COMPLIANT |
| R-19 | setup-deps auto-detect | yay present resolves to omarchy | `T7` sub-case A | ✅ COMPLIANT |
| R-20 | setup-deps auto-detect | dnf present resolves to fedora | `T7` sub-case B | ✅ COMPLIANT |
| R-21 | setup-deps auto-detect | pacman without yay resolves to omarchy with warning | `T7` sub-case E | ✅ COMPLIANT |
| R-22 | setup-deps auto-detect | no package manager fails clearly | `T7` sub-case C | ✅ COMPLIANT |
| R-23 | setup-deps explicit override | `--omarchy` overrides detection | `T7` sub-case D | ✅ COMPLIANT |
| R-24 | setup-deps explicit override | `--fedora` overrides detection | **No direct test** — override mechanism is symmetric to `--omarchy` (same code path) but the `--fedora` branch is not exercised by a runtime test | ⚠️ COVERAGE GAP — see Notes |
| R-25 | setup-fonts honors override | `DOTFILES_FONTS_DIR` overrides default | `T5` sub-case B (asserts custom path appears in pre-flight/setup-fonts output) | ✅ COMPLIANT |
| R-26 | setup-fonts honors override | unset `DOTFILES_FONTS_DIR` uses default | All other tests use the default path; `setup-fonts:45-49` falls back to `$HOME/.local/share/fonts/autanasoft` when unset | ✅ COMPLIANT |

**Compliance summary**: 22 ✅ COMPLIANT, 2 ⚠️ PARTIAL, 1 ⚠️ COVERAGE GAP.

### Documentation coverage matrix (revised spec)

The spec's "Documentation and test coverage" requirement
(`specs/setup-orchestration/spec.md:327-347`) was narrowly adjusted so
that `docs/setup.md` is expected to be **functional** user documentation
that summarizes what the script does, how to invoke it, the accepted
flags, what it does NOT do, and how to verify — NOT a strict technical
duplicate of OpenSpec. The detailed contract (exported variables,
dispatcher-vs-env-script boundary, flag precedence table,
auto-detection behavior, override flag) now lives in OpenSpec and the
scripts themselves; the user-facing doc MUST NOT contradict the code or
omit documented flags.

| Spec requirement for `docs/setup.md` | Status | Notes |
|---|---|---|
| Summarize what the script does | ✅ COMPLIANT | Intro paragraph + Quick Path lead with the answer. |
| How to invoke it | ✅ COMPLIANT | Quick Path shows `./setup --omarchy`. |
| Accepted flags listed (and not omitting documented flags) | ✅ COMPLIANT | Accepted Flags table covers `--omarchy`, `--fedora`, `--fonts`, `--deps`, `--dry-run`, `--help`. |
| What the script does NOT do (`--fedora` is not implemented) | ✅ COMPLIANT | Accepted Flags row for `--fedora` says "Prints a not-implemented message and exits successfully." |
| How to verify behavior (including the test command) | ✅ COMPLIANT | Verification section with `bash tests/setup-deps.bash` and a clear note that the tests use stubs and temp dirs. |
| No contradiction to the code | ✅ COMPLIANT | Grep over `docs/setup.md` vs. actual scripts: no factual contradictions found. |

The previous spec-vs-docs tension (item 3 in the r1 report's SUGGESTIONs)
is now explicitly resolved by the revised spec: the detailed
implementation contract (5 exported vars, dispatcher-vs-env boundary,
flag precedence, auto-detection probe table, override flag) belongs in
OpenSpec and the scripts, and the user-facing doc may legitimately
omit it. The current `docs/setup.md` is consistent with the revised
spec — concise, leads with the answer, no contradictions, and does not
omit any documented flag.

## Correctness (Static Evidence)

| Requirement | Status | Notes |
|---|---|---|
| Root is a thin dispatcher | ✅ Implemented | `setup` is 280 lines; no `run_deps`/`run_fonts`/`run_env`/`TOTAL_STEPS`/`current_step` outside the explicit "MUST NOT" doc comment at lines 18-19. Single `case` dispatch in `setup:241-258`. |
| Exported variable contract (5 vars) | ✅ Implemented | `setup:202-214` exports `DOTFILES_ROOT`, `DOTFILES_ENV`, `DOTFILES_FONTS_DIR`, `DOTFILES_BACKUP_DIR`, and conditionally `DOTFILES_DRY_RUN`. `DOTFILES_FONTS_DIR` is centralized at `setup:69` (single production literal; other matches are help text or direct-invocation fallback). |
| Cleanup trap on EXIT | ✅ Implemented | `setup:222` registers `trap 'unset DOTFILES_ROOT DOTFILES_ENV DOTFILES_DRY_RUN DOTFILES_BACKUP_DIR DOTFILES_FONTS_DIR' EXIT` covering all 5 vars. |
| Env script owns full flow | ✅ Implemented | `scripts/setup-omarchy` has its own `TOTAL_STEPS=4` counter (`setup-omarchy:426`), `step()` helper (line 429-432), `invoke_setup_deps`/`invoke_setup_fonts` (lines 147-179) that call sub-scripts as subprocesses. |
| Pre-flight is non-mutating | ✅ Implemented | `setup-omarchy:468-476` checks `$DOTFILES_FONTS_DIR` (or fallback default) for existence and non-empty; only fails in non-dry-run (`fail` at line 474), warns in dry-run. |
| `setup-deps` auto-detect with probe table | ✅ Implemented | `setup-deps:181-201` `detect_env()` probes `yay`→omarchy, `pacman`→omarchy+warn, `dnf`→fedora, `rpm`→fedora+warn, else return 1. `setup-deps:209-220` runs the probe when no flag/env is set; failure path is the "Could not detect" message + usage + exit 2. |
| `--omarchy` / `--fedora` remain valid overrides | ✅ Implemented | `setup-deps:120-129` accepts both flags; `DOTFILES_ENV_LOCAL` is set; the auto-detect block at line 209 only runs when `DOTFILES_ENV_LOCAL` is empty. |
| `setup-fonts` honors `DOTFILES_FONTS_DIR` | ✅ Implemented | `setup-fonts:45-49` reads `DOTFILES_FONTS_DIR` when set, falls back to `$HOME/.local/share/fonts/autanasoft` when unset. |
| Symlink map and SSH seed preserved | ✅ Implemented | `setup-omarchy:319-382` symlink map and `seed_ssh_config` unchanged in shape; backup strategy with collision suffix preserved (`backup_target` at lines 188-222). |
| `validate_system` preserved | ✅ Implemented | `setup-omarchy:387-414` dry-run preview + live `omarchy theme set` / `hyprctl reload` / `hyprctl configerrors` / `zellij --version`. |
| `--fedora` short-circuit | ✅ Implemented | `setup:234-238` prints `[setup] WARN: Fedora env executor is not implemented yet. See fedora/README.md for manual setup.` then `Setup complete (no changes).` and `exit 0`; never reaches the dispatch case. |

## Coherence (Design)

| Decision | Followed? | Notes |
|---|---|---|
| Root is a thin dispatcher (no pipeline, no helpers, no counter) | ✅ Yes | `setup` has no `run_deps` / `run_fonts` / `run_env` / `TOTAL_STEPS` / `current_step` in active code. The only matches in `setup` are the explicit "MUST NOT" doc comment at lines 18-19. |
| Env script owns the full flow | ✅ Yes | `setup-omarchy` runs `invoke_setup_deps` (Step 1/4), `invoke_setup_fonts` (Step 2/4), pre-flight (non-mutating, not counted), `apply_symlinks` (Step 3/4), `validate_system` (Step 4/4). Counter is local to the env script. |
| Subprocess invocation (not `source`) for `setup-deps` / `setup-fonts` | ✅ Yes | `setup-omarchy:159, 178` use `"$deps_script" "${args[@]}"` and `"$fonts_script" "${args[@]}"` (no `source`). |
| Auto-detect probe order: yay → pacman → dnf → rpm | ✅ Yes | `setup-deps:182-200` matches the design table exactly. |
| Override flag still valid | ✅ Yes | `setup-deps:120-129` accepts `--omarchy` and `--fedora`; auto-detect block at line 209 only runs when `DOTFILES_ENV_LOCAL` is empty. |
| `DOTFILES_FONTS_DIR` centralized in root | ✅ Yes | `setup:69` is the single production literal; `setup-fonts:45-49` and `setup-omarchy:468` read it. |
| Cleanup trap on EXIT for all 5 vars | ✅ Yes | `setup:222` lists all 5 var names. |
| 7-test plan minimum | ✅ Yes | `TEST_PLAN=7` (T7 has 5 sub-cases for full triangulation). |
| Documentation is functional, not verbose | ✅ Yes | `docs/setup.md` (65 lines) is concise, leads with the answer, and does not contradict the code. Compliant with the revised spec. |
| Stale verify-report archived | ✅ Yes | `verify-report.md` is renamed `verify-report.deprecated-20260614.md` (file was untracked in git, so plain `mv` per WU-7). The new report is this one. |
| Per-PT cost limits | ✅ Yes | Root `setup` 280 lines; `setup-omarchy` 489 lines; `setup-deps` 355 lines; `setup-fonts` 233 lines; `tests/setup-deps.bash` 1042 lines (well-triangulated with 5 sub-cases for T7 alone). |

## TDD Compliance (Strict TDD Mode)

| Check | Result | Details |
|---|---|---|
| TDD Evidence reported | ✅ | Found in apply-progress observation #1374 — full "TDD Cycle Evidence" table with PR-1, PR-2, and PR-3 sections. |
| All tasks have tests | ✅ | 7/7 work units have test coverage; WU-1 establishes the test plan, WU-2 through WU-5 are GREEN against WU-1's tests, WU-6 is REFACTOR + docs, WU-7 is archive. |
| RED confirmed (tests exist) | ✅ | `tests/setup-deps.bash` exists at 1042 lines with 7 test functions, 5 of which contain 2-5 sub-cases for triangulation. |
| GREEN confirmed (tests pass) | ✅ | `bash tests/setup-deps.bash` exits 0 with `1..7` and `ok 1` through `ok 7` (re-run 2026-06-14 r2). |
| Triangulation adequate | ✅ | T2: 2 sub-cases; T3: 2 sub-cases; T4: 4 sub-cases (A: fonts-only, B: deps-only with auto-detect, C: validation reject fonts+deps, D: child-failure propagation); T5: 2 sub-cases (default missing, env-var override); T6: 2 sub-cases (env -i run, trap-source grep); T7: 5 sub-cases (A: yay→omarchy, B: dnf→fedora, C: none→fail, D: --omarchy override, E: pacman-without-yay warn). |
| Safety Net for modified files | ✅ | Apply-progress reports safety net 6/6 (PR-1), 5/5 (PR-2), 6/6 (PR-3) before each touch. |
| Refactor pass after GREEN | ⚠️ Partial | Apply-progress reports no separate refactor commits, but the code went through TDD-aligned tightenings per the deviations list. T1, T2, T6 have explicit refactor steps. Acceptable for shell scripts where the tests are behavioral. |

**TDD Compliance**: 6/7 checks passed, 1 partial (refactor pass).

### Test Layer Distribution

| Layer | Tests | Files | Tools |
|---|---|---|---|
| Unit | 7 | 1 (`tests/setup-deps.bash`) | Repo-native bash TAP-ish runner |
| Integration | 0 | 0 | N/A (bash scripts; no integration framework in repo) |
| E2E | 0 | 0 | N/A |
| **Total** | **7** | **1** | |

Tests are all unit-level (subprocess isolation via `env -i` + stubs + temp `HOME`). The unit layer is appropriate for shell scripts that test dispatch and auto-detect — there's no UI, no IPC boundary, and the "system" is the file system and process environment, both of which the harness already isolates. Integration/E2E layers would add noise without proving additional behavior.

### Changed File Coverage

➖ Not available — no coverage tool detected for shell scripts in the repo. The test harness covers every branch of the dispatch table and the auto-detect probe table; uncovered line ranges would have to be derived by reading the source against the test assertions.

### Quality Metrics

**Linter**: ➖ Not available — no `shellcheck` invocation in the test suite. Visual inspection: `setup:52` uses `set -euo pipefail`; all scripts have it. Quoting is consistent (e.g. `setup:131` and `setup-fonts:91` use `[[ $# -gt 0 ]]`). No obvious red flags.

**Type Checker**: ➖ Not available — bash has no static type checker in this repo.

### Assertion Quality

| File | Line | Assertion | Issue | Severity |
|---|---|---|---|---|
| `tests/setup-deps.bash` | 685 (T6 sub-case A) | `bash -c '… printenv | grep "^DOTFILES_" || true; …'` inside a subshell that exits immediately | The test name implies "leak to calling shell", but the env check runs inside a subshell that exits before the assertion can affect the parent. Comment at line 663-665 acknowledges this. The behavior is still verifiable via sub-case B (trap-line grep). | SUGGESTION — preserved from r1; the comment in the test file is honest about the limitation. |
| `tests/setup-deps.bash` | 705 (T6 sub-case B) | `grep -E "trap '?unset DOTFILES_" "$REPO_ROOT/setup"` | Real assertion — the trap line is grepped, then each of the 5 var names is checked. Pattern is strong (rejects weak alternation). | ✅ Real assertion |
| `tests/setup-deps.bash` | 752-994 (T7) | Stub-log regexes on `^pacman -Q `, `^rpm -q `, `^yay -S --needed ` | Real assertions — each sub-case checks exact PM commands were/were not invoked, with start-of-line anchors. Triangulates well (5 sub-cases with DIFFERENT expectations). | ✅ Real assertion |

**Assertion quality**: no blocking findings, 1 suggestion. The suggestion is for T6 sub-case A, which is honestly documented in its own comment.

## Notes

These are non-blocking follow-ups only:
1. **`--fedora` override path in `setup-deps` does not yet have a dedicated runtime test.** The spec scenario "GIVEN `yay` is on `PATH` and `scripts/setup-deps --fedora` runs … THEN it skips detection, uses the Fedora package list, and does not consult `pacman`" is not in `T7`. Only the `--omarchy` override (sub-case D) is tested. The override mechanism is symmetric in code (`setup-deps:120-129`), so this is a coverage gap, not a behavior gap. Recommend adding `T7` sub-case F: stub `yay` on PATH, run `setup-deps --fedora --dry-run`, assert `Env: fedora`, `rpm -q` (with `rpm` stub), no `Detected env:`, no `pacman -Q`.
2. **T6 sub-case A ("vars unset after a successful run") is a documentation-style check, not a behavioral leak check.** The assertion runs inside a subshell that exits before the env can leak, so the "leaked" branch is never exercised in a way that distinguishes a working trap from a broken one. Sub-case B (trap-line source grep) is the real enforcement. The test name can be renamed for clarity or rewritten to use a subshell that survives the call.
3. **Pre-flight failure path in non-dry-run is not directly tested.** `T5` sub-case A exercises the dry-run path (pre-flight warns, continues). The non-dry-run path (`setup-omarchy:474` exits 1) is verifiable in the source but does not yet have a dedicated runtime test.

## Resolved since r1

The r1 report's SUGGESTION #3 ("Spec vs. `docs/setup.md` tension") is
now **resolved** by the user's narrow spec adjustment: the revised spec
(`specs/setup-orchestration/spec.md:327-340`) explicitly moves the
detailed implementation contract (5 exported vars, dispatcher-vs-env
boundary, flag precedence, auto-detection probe table, override flag)
to OpenSpec and the scripts themselves, and requires `docs/setup.md`
only to summarize at minimum what the script does, how to invoke it,
the accepted flags, what it does NOT do, and how to verify — without
contradicting the code or omitting documented flags. The current
`docs/setup.md` is compliant with the revised spec: concise (65
lines), leads with the answer, no contradictions, and does not omit
any documented flag.

## Verdict

**PASS**

All 7/7 tests pass on runtime execution. All 14 design acceptance
criteria are met at the source level. Spec compliance is 22 ✅
COMPLIANT, 2 ⚠️ PARTIAL (T6 cleanup sub-cases are documentation checks,
not behavioral — same observation as r1), 1 ⚠️ COVERAGE GAP (`--fedora`
override — same observation as r1; symmetric in code). The
implementation is structurally correct, the dispatcher is genuinely
thin, the env script owns the full flow, the auto-detect probe table
matches the spec, the 5-var cleanup trap is in place, and `docs/setup.md`
is compliant with the revised functional-doc expectation.

The remaining notes are coverage gaps, not correctness gaps.
The change is ready to archive.

## Test Output (preserved)

```text
$ bash tests/setup-deps.bash
1..7
ok 1 - root --omarchy invokes setup-omarchy exactly once
ok 2 - --omarchy --fonts and --omarchy --deps are absorbed by root
ok 3 - --fedora (any combo) short-circuits to not-implemented and exits 0
ok 4 - --fonts runs only setup-fonts; --deps runs only setup-deps
ok 5 - env-script pre-flight handles missing/overridden $DOTFILES_FONTS_DIR
ok 6 - DOTFILES_* (5 vars) cleanup under env -i + trap source grep
ok 7 - scripts/setup-deps auto-detects env (yay/dnf/none) and respects override
# 7/7 passed
```
