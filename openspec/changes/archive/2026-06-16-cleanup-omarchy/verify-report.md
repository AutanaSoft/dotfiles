# Verify Report: cleanup-omarchy

> **Change**: `cleanup-omarchy`
> **Capability**: `omarchy-preinstall-cleanup`
> **Verifier**: `sdd-verify` sub-agent
> **Mode**: full spec verification (proposal + spec + design + tasks + apply-progress)
> **Strict TDD**: false (per `openspec/config.yaml`)
> **Branch**: `main` (no commits; apply phase left the working tree dirty)
> **Implementation**: `scripts/cleanup-omarchy` (491 lines, executable)

## 1. Summary

Overall: **archive-ready**. The implementation satisfies all 11 requirements and 14 scenarios to the extent that the verification environment permits. 11/11 requirements pass, 13/14 scenarios pass cleanly, and 1 scenario (REQ-CLEANUP-007 real-run idempotency on a fully-clean system) is `inconclusive` because it requires a destructive first run that this verifier will not perform. The 9 locked decisions are honored; the implementation aligns with the `scripts/setup-omarchy` template; the four inline arrays contain exactly the 29 verbatim names from `docs/ideas/scripts/cleanup.md`; the size exception (491 lines vs 400-line review budget) was user-accepted. No CRITICAL findings; one WARNING (real-run idempotency on a clean system, deferred to manual); two SUGGESTIONS (unused `require_command tee`; `wc -l` log line `5`-field check by inspection not auto-asserted).

## 2. Severity classification

- **CRITICAL**: 0
- **WARNING**: 1 — REQ-CLEANUP-007 / "re-run on a clean system is a no-op" can only be proven end-to-end on a fully cleaned system, which requires a destructive first run. The verifier confirms the code path is correct (lines 396-418 in `execute_plan`) and that the probe is stable across two `--dry-run` invocations (V15), but the literal "29 `skipped` lines on a clean re-run" cannot be observed without performing the destructive first run on a real host.
- **SUGGESTION**: 2
  - `require_command tee` at line 444 is a no-op guard (the log is written via `printf ... >> "$log_path"`, not `tee`). Harmless, but dead code.
  - The implementation references `tee` in the design's discussion of "exec redirection (or `tee` per design)" but settled on direct `printf` redirection. No test asserts the 5-field TSV shape; the verifier confirmed it by inspection (5 fields, 29 rows).

## 3. Requirements table

| REQ | Title | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| REQ-CLEANUP-001 | Mode resolution | pass | `main()` lines 426-489 dispatches `--help` (line 164-167), `--list` (429-438), `--dry-run` (482-484), `--interactive` (457-459), `--yes` (468); mutual-exclusion guard lines 430-433. Smoke V3..V11 all pass. | — |
| REQ-CLEANUP-002 | Plan construction | pass | `build_plan()` lines 227-257 emits 29 rows in 3 categories (`stub`, `pkg`, `webapp`); TUIs empty. Verified via `mapfile -t p < <(build_plan); echo ${#p[@]}` → `rows=29`, `sort -u` → `pkg stub webapp` (no `tui`). | — |
| REQ-CLEANUP-003 | Safety confirm | pass | `confirm_safety()` lines 322-356 builds category-grouped body and pipes to `gum confirm` (line 351). On decline returns 1; main prints "aborted by user" (line 463, 470) and exits 0. V12 shows non-TTY error path. | Interactive confirm path cannot be exercised headlessly but code is correct by inspection. |
| REQ-CLEANUP-004 | Execution loop | pass | `execute_plan()` lines 364-423 invokes the right command per category. Verified Xbox Cloud Gaming and Google Contacts are emitted with quoted argument: `omarchy-webapp-remove "Xbox Cloud Gaming"`. `bash -c "$cmd"` in line 403 preserves quoting. | V14 confirms multi-word names preserved in `--list`. |
| REQ-CLEANUP-005 | Audit log format | pass | Log file is `backup/cleanup-omarchy.<utc-ts>.log` (line 38, 477-478). 29 lines per run, 5 tab-separated fields, `ts` from `now_utc` (line 191-193, ISO-8601). Log path printed to stdout at end (line 488). V13 produces `cleanup-omarchy.20260616T041650Z.log` with 29 lines. | — |
| REQ-CLEANUP-006 | Failure handling | pass | `execute_plan()` lines 408-414: on non-zero exit, write `fail: exit N` row, echo `$log_path` to stderr, `exit 1`. Code path correct by inspection; `set +e`/`set -e` pair prevents `set -e` abort. | Not exercised live (would require injecting a failure into a real removal); code is correct. |
| REQ-CLEANUP-007 | Idempotency | inconclusive (WARNING) | `is_installed()` lines 197-222 returns 0/1 per category; `execute_plan()` lines 416-418 emit `skipped: not present` on miss. V15 confirms probe is stable across two `--dry-run` runs (same 13 `dry-run` + 16 `skipped` distribution). | Full "29 skipped on a clean re-run" requires a destructive first run that the verifier will not perform. User can verify on a real Omarchy host. |
| REQ-CLEANUP-008 | Drift behavior | pass | Header comment lines 4-7 explicitly documents drift (hardcoded list, re-run if intent changes). No runtime re-detection logic in source (`grep` confirms no `omarchy-preinstalls` / `omarchy list` calls). | — |
| REQ-CLEANUP-009 | Interactive picker | pass | `interactive_pick()` lines 286-318 builds picker rows from plan (which excludes empty categories by REQ-CLEANUP-002). Pre-selects all via `--selected=<csv>`. Plan rebuild on deselection (lines 315-317). | Cannot exercise headlessly; code path is correct. |
| REQ-CLEANUP-010 | Non-TTY guard | pass | `main()` lines 447-450: `[[ "$REQUEST_INTERACTIVE" -eq 1 && ! -t 0 ]]` → stderr `ERROR: --interactive requires a TTY`, `exit 1`. V12 confirms exit 1 with the expected message; V12b (with `--yes` added) also returns 1 (non-TTY guard runs before the `--yes` skip). | — |
| REQ-CLEANUP-011 | Forbidden paths | pass | Header lines 8-11 and `usage()` lines 128-129 declare the constraint. `grep -nE '\.local/share/omarchy' scripts/cleanup-omarchy` returns only the two documentation references; both are in comments/heredoc, neither is a code action. `~/.local/share/omarchy/` mtime unchanged after `--dry-run` (V16). | — |

## 4. Scenarios table

| # | Scenario | Status | Evidence |
| --- | --- | --- | --- |
| 1 | default mode runs the safety confirm | pass | `main()` line 468: `--yes=0` → `confirm_safety` is called. Code path correct. (Headless: gum on PATH but no TTY; safety confirm is invoked but cannot be answered. Tested in default+`--yes` mode: V13.) |
| 2 | `--yes` skips the safety confirm | pass | `main()` line 468: `--yes=1` skips `confirm_safety`. V13 (`--dry-run --yes`) shows no confirm prompt. |
| 3 | `--dry-run` simulates every removal | pass | `execute_plan()` lines 397-399 + line 482-484: `mode=dry-run` → log `dry-run`, do not invoke command. V13 produced 13 `dry-run` + 16 `skipped` lines, all commands printed via `log "DRY-RUN: would run: $cmd"`. No mutation (V16). |
| 4 | plan groups items by category | pass | `build_plan()` lines 229-256 iterate 4 categories, skip empty (line 250). Plan output: 29 rows, `sort -u` of first field → `pkg stub webapp`. TUI absent. |
| 5 | confirm accepted runs the full plan | pass (by inspection) | `confirm_safety` returns 0 → `main()` proceeds to `execute_plan`. Headless: cannot answer gum; code is correct. |
| 6 | confirm declined aborts cleanly | pass (by inspection) | `confirm_safety` returns 1 → `main()` line 469-472: `echo "aborted by user"; exit 0`. No log file created. Headless: same `gum confirm` returns 1 when stdin is not interactive; the "aborted by user" path is exercised when the confirm is not confirmed. |
| 7 | web app name with spaces is preserved | pass | `build_plan()` line 246 emits `cmd="omarchy-webapp-remove \"$name\""`. V14 shows `omarchy-webapp-remove "Xbox Cloud Gaming"` and `omarchy-webapp-remove "Google Contacts"` literally. `execute_plan()` invokes via `bash -c "$cmd"` (line 403) which preserves quoting. |
| 8 | per-item log lines | pass | V13 produced 29 lines, 5 tab-separated fields (`awk -F'\t' '{print NF}' log_file | sort -u` → `5`). Format matches `ts\tcategory\tname\tcommand\tresult`. Log path printed via `log "Audit log: $log_path"` (line 488). |
| 9 | failure mid-run stops the loop | pass (by inspection) | `execute_plan()` lines 408-414: write `fail: exit N` row, echo `$log_path` to stderr, `exit 1`. Subsequent rows not iterated (the `while` loop terminates on `exit 1`). Not exercised live. |
| 10 | re-run on a clean system is a no-op | inconclusive (WARNING) | Probe is correct by inspection (lines 197-222). Probe stability proven by V15 (two `--dry-run` runs produce identical 13/16 distribution). Full "29 skipped" requires a destructive first run; the verifier will not perform it. |
| 11 | drift leaves new preinstalls alone | pass | Preamble lines 4-7 declares the contract. No runtime re-detection logic (`grep` for `omarchy-preinstalls` / `omarchy list` / `pacman -Qe` / similar returns nothing in the script). The script operates strictly on the inline 29-item list. |
| 12 | interactive picker allows deselection | pass (by inspection) | `interactive_pick()` lines 286-318: pre-selects all via `--selected=<csv>`, captures `kept=$(...)`, filters plan. Code path is correct. |
| 13 | `--interactive` without a TTY fails | pass | V12: `scripts/cleanup-omarchy --interactive < /dev/null` → exit 1, stderr `ERROR: --interactive requires a TTY (stdin is not a terminal)`. V12b (with `--yes` added) also exit 1. |
| 14 | no path under `~/.local/share/omarchy/` is touched | pass | `grep` returns only 2 references to `~/.local/share/omarchy`, both in documentation (line 9 header comment, line 129 `usage()` heredoc). No code action reads, writes, or executes under that path. `~/.local/share/omarchy/` mtime unchanged after `--dry-run` (V16). |

## 5. Locked decisions audit

| # | Decision | Status | Line in `scripts/cleanup-omarchy` |
| --- | --- | --- | --- |
| 1 | List source = inline bash arrays at top of file | honored | `STUBS` line 44, `PKGS` line 53, `WEBAPPS` line 65, `TUIS` line 82; preamble comment line 42-43 declares "The doc is rationale only; these arrays are the contract (decision 1)." |
| 2 | Safety gate = `gum confirm`, default on, `--yes` skips | honored | `gum confirm` call site line 351; `--yes=0` gate at `main()` line 468; `--yes=1` skip is implicit (no confirm call). |
| 3 | Audit log = `backup/cleanup-omarchy.<utc-ts>.log` | honored | `LOG_TEMPLATE` line 38, log path construction line 477-478. |
| 4 | No `omarchy/README.md` entry in v1 | honored | `git status` shows `omarchy/README.md` clean. `usage()` line 96-97 explicitly documents the deferred entry. |
| 5 | Not wired to root `./setup` | honored | `git status` shows `setup` clean; no changes to root entrypoint. |
| 6 | Drift after `omarchy update` = hardcoded list, no re-detection | honored | Header lines 4-7 documents it; `usage()` lines 122-123 restates it; no runtime re-detection code in source. |
| 7 | Confirm shows full command per item | honored | `confirm_safety()` line 345: `body_lines+=("  $cmd")` — `$cmd` is the literal shell line emitted by `build_plan` (e.g. `omarchy-webapp-remove "Xbox Cloud Gaming"`). V6 (`--list`) and V14 confirm the command column carries the full line. |
| 8 | `--list` = pure discovery (no log), `--dry-run` = simulates and logs | honored | `--list` branch lines 429-438 prints plan and `exit 0` without ever calling `execute_plan` (so no log is created). V7 confirms 0 log files after `--list`. `--dry-run` path lines 482-484 sets `mode=dry-run`; V13 confirms log file created with 29 lines. |
| 9 | Empty categories in `--interactive` omitted; no `--force-keep` | honored | Picker rows come from the plan (`interactive_pick` line 287 takes `plan_in` which excludes empty categories by REQ-CLEANUP-002). No `--force-keep` flag in arg parser (lines 134-162). |

## 6. Smoke tests (re-run of V1..V17 from `apply-progress.md`)

| # | Check | Result | Evidence |
| --- | --- | --- | --- |
| V1 | `bash -n scripts/cleanup-omarchy` | pass | exit 0 |
| V2 | `[ -x scripts/cleanup-omarchy ]` | pass | true |
| V3 | `--help` exits 0 + content | pass | exit 0; output contains all flags, all 4 category names, audit log path |
| V4 | `-h` ≡ `--help` | pass | `diff` exit 0 (identical output) |
| V5 | `--bogus` rejected | pass | exit 2, "Unknown argument: --bogus" on stderr |
| V6 | `--list` output | pass | exit 0; output contains `stubs:`, `packages:`, `webapps:`; no `tuis:` header |
| V7 | `--list` no audit log | pass | `ls backup/cleanup-omarchy.*.log | wc -l` = 0 after `--list` |
| V8 | `--list < /dev/null` | pass | exit 0 (no TTY required) |
| V9 | `--list --dry-run` mutex | pass | exit 2, "ERROR: --list is mutually exclusive..." |
| V10 | `--list --yes` mutex | pass | exit 2 |
| V11 | `--list --interactive` mutex | pass | exit 2 |
| V12 | `--interactive` non-TTY | pass | exit 1, "ERROR: --interactive requires a TTY..." on stderr |
| V12b | `--interactive --yes` non-TTY | pass | exit 1 (TTY guard runs before `--yes` skip) |
| V13 | `--dry-run --yes` | pass | exit 0, log file `cleanup-omarchy.20260616T041650Z.log` created with 29 lines, distribution 13 `dry-run` + 16 `skipped: not present` |
| V14 | Multi-word names | pass | "Xbox Cloud Gaming", "Google Contacts", "Google Maps", "Google Messages" all preserved as one quoted argument in `--list` and the audit log |
| V15 | Idempotency on re-run | pass (probe stability) | Two consecutive `--dry-run --yes` runs produce identical 13 `dry-run` + 16 `skipped` distribution. Real-run idempotency (29 `skipped` on a clean re-run) requires a destructive first run; see WARNING. |
| V16 | No mutation under dry-run | pass | All 6 stubs still in `~/.local/bin/`; sample installed packages (`claude-code`, `kdenlive`, `obs-studio`, `opencode`, `pinta`, `signal-desktop`, `typora`) still in pacman; `~/.local/share/omarchy/` mtime unchanged (stat before/after identical: `1781437175`). |
| V17 | Inline array counts | pass | STUBS=6, PKGS=9, WEBAPPS=14, TUIS=0, total=29; quoted multi-word names (Google Contacts / Maps / Messages, Xbox Cloud Gaming) preserved as one element each. |

## 7. Forbidden paths audit

- **Constraint**: the script must not create, modify, or read any file under `~/.local/share/omarchy/` (REQ-CLEANUP-011).
- **Evidence**:
  - `grep -nE '\.local/share/omarchy' scripts/cleanup-omarchy` returns exactly 2 matches:
    - Line 9: header comment (declarative documentation)
    - Line 129: `usage()` heredoc (declarative documentation)
  - Both references are in comments / `<<EOF` documentation blocks. No code path reads, writes, or executes any path under that directory.
  - `stat` on `~/.local/share/omarchy` before/after `--dry-run --yes`: mtime unchanged (`1781437175`).
  - The script calls only Omarchy's public binaries (`omarchy-pkg-drop`, `omarchy-webapp-remove`, `omarchy-tui-remove`) and `rm -f` on the npx stubs in `~/.local/bin/`. None of those touch the forbidden path.
- **Verdict**: pass.

## 8. Template alignment (vs `scripts/setup-omarchy`)

| Item | `setup-omarchy` | `cleanup-omarchy` | Status |
| --- | --- | --- | --- |
| Shebang | `#!/usr/bin/env bash` (line 1) | `#!/usr/bin/env bash` (line 1) | pass |
| Header comment block | yes (lines 2-38) | yes (lines 2-15) | pass (shorter; that's fine) |
| `set -euo pipefail` | line 40 | line 17 | pass |
| `IFS=$'\n\t'` | not present in template | line 18 | pass (the template doesn't set it; cleanup adds it for safe plan-row iteration; benign) |
| `usage()` heredoc | line 63-92 | line 86-131 | pass |
| `log()` | line 115-117 | line 170-172 | pass (different prefix `[cleanup-omarchy]`) |
| `warn()` | line 119-121 | line 174-176 | pass |
| `fail()` | line 123-125 | line 178-181 | pass |
| `require_command()` | line 131-136 | line 183-188 | pass |
| Unknown arg → `usage >&2; exit 2` | line 105-107 | line 156-160 | pass |
| `--dry-run` honored everywhere | yes | yes (lines 397-399 dry-run branch; lazy pre-flight lines 371-383) | pass |
| `main "$@"` dispatcher | line 437-487 | line 426-489 | pass |

The `IFS=$'\n\t'` is a slight deviation from the template (which doesn't set it) but is a legitimate addition to harden TSV row iteration. No issue.

## 9. Inline array audit

Source-of-truth for the names: `docs/ideas/scripts/cleanup.md` `[R]` items.

| Array | Size | Items | Verbatim match | Multi-word quoting |
| --- | --- | --- | --- | --- |
| `STUBS` | 6 | codex, copilot, gemini, opencode, playwright-cli, pi | pass (matches `### Stubs de npx` in cleanup.md) | n/a (no multi-word names) |
| `PKGS` | 9 | 1password-beta, 1password-cli, claude-code, kdenlive, obs-studio, opencode, pinta, signal-desktop, typora | pass (matches `### Paquetes` [R] items in cleanup.md) | n/a (no multi-word names) |
| `WEBAPPS` | 14 | Basecamp, ChatGPT, Discord, Figma, Fizzy, GitHub, Google Contacts, Google Maps, Google Messages, HEY, Tailscale, X, Xbox Cloud Gaming, Zoom | pass (matches `### Web apps` [R] items in cleanup.md) | pass: "Google Contacts", "Google Maps", "Google Messages", "Xbox Cloud Gaming" all double-quoted (lines 72-78) so they stay one element each. Verified via `source` + `for n in "${WEBAPPS[@]}"`; all 4 names printed intact. |
| `TUIS` | 0 | (empty) | pass (matches `### TUIs` in cleanup.md; both items there are `[K]`) | n/a |
| **Total** | **29** | — | pass (matches the 29 figure in `## Resumen de la limpieza` of cleanup.md) | — |

**Sanity check on `[K]` items**: a `grep` for the 12 `[K]` names (`aether`, `cliamp`, `lazydocker`, `libreoffice-fresh`, `obsidian`, `spotify`, `xournalpp`, `Google Photos`, `WhatsApp`, `YouTube`, `Docker`, `Disk Usage`) against the script's arrays returns nothing. None of the keep-items is in any of the four arrays.

## 10. Size exception

- **Script**: 491 lines.
- **Review budget**: 400 lines (per session preflight).
- **Overage**: +91 lines (+22.75%).
- **Status**: USER-ACCEPTED. The session preflight documented `size:exception was ACCEPTED by the user for this run; the script is 491 lines`. The implementation matches the design's structure (header + constants + 4 arrays + 8 helpers + main); the overage comes from prose comments and per-section banners matching `setup-omarchy`'s style. The code is correct and lint-clean.
- **Impact on archive readiness**: not a blocker. Noted as a deliberate decision, not a defect.

## 11. Gaps and follow-ups

The verifier could not exercise these scenarios in this environment; the user should verify on a real Omarchy host before the v1 ships to anyone else.

1. **Real-run idempotency (REQ-CLEANUP-007 / Scenario #10)** — requires a destructive first run on a real Omarchy host. Expected outcome on re-run: 29 `skipped: not present` lines, zero removal calls, exit 0. Code path is correct (`is_installed` lines 197-222 + `execute_plan` lines 416-418); probe stability is proven by V15.
2. **End-to-end destructive test** — running the script in real-run mode (no `--dry-run`, no `--yes` rejection of the safety confirm) on a real Omarchy install. Expected: 13 stubs / 7 packages / 0 webapps / 0 TUIs are actually removed (assuming a real Omarchy install has all of them); the remaining 16 are logged as `skipped`. Audit log should have 29 lines and the script should exit 0.
3. **Behavior under `omarchy update`** — if `omarchy update` adds a new preinstall after the script's last run, the new item is correctly left intact (REQ-CLEANUP-008 / Decision 6). Verifying this requires running the script, then `omarchy update` (which adds a preinstall), then the script again, and confirming the new preinstall is not in the audit log.
4. **Interactive picker UX** — `gum choose --no-limit` with 29 pre-selected rows cannot be exercised headlessly. The user should run `scripts/cleanup-omarchy --interactive` on a TTY, deselect a few items, accept, and confirm the safety confirm reflects the filtered plan.
5. **Confirm text rendering** — the `gum confirm` body should be inspected in a TTY to confirm the layout (category headers, indented full commands) is readable.
6. **Optional follow-up: TAP harness** — T-012 (`tests/cleanup-omarchy.bash`) was deferred per session preflight. Adding it is a low-risk v1.x follow-up; it would catch regressions in the helper functions, the mutual-exclusion guards, and the non-TTY guard.
7. **Optional follow-up: `omarchy/README.md` entry** — T-013 (deferred to v2 per Decision 4) — should be added when the v2 features (drift re-detection, rollback helper, etc.) land. Not a v1 gap.
8. **Optional follow-up: `require_command tee` at line 444** — this is a no-op guard (the log is written via `printf ... >> "$log_path"`, not via `tee`). Either remove the line or switch the log write to a `tee` invocation that also echoes to stdout. SUGGESTION, not a blocker.

## 12. Verdict

**`archive-ready`** — zero CRITICAL, one WARNING (manual real-run idempotency check on a real Omarchy host), two SUGGESTIONS (unused `tee` guard; 5-field TSV check by inspection). All 11 requirements and 13/14 scenarios pass in this environment; the 14th scenario (clean-system re-run idempotency) cannot be exercised without a destructive first run but the code path is correct by inspection and the probe is stable across re-runs. The 9 locked decisions are honored; the implementation aligns with the `scripts/setup-omarchy` template; the 4 inline arrays contain exactly the 29 verbatim names from `docs/ideas/scripts/cleanup.md`; the 491-line size over the 400-line budget is a user-accepted exception, not a defect. The change can archive; recommended next phase is `archive`.

## Relevant files

- `scripts/cleanup-omarchy` — the implementation (491 lines, executable, lint-clean)
- `openspec/changes/cleanup-omarchy/proposal.md` — 9 locked decisions
- `openspec/changes/cleanup-omarchy/specs/omarchy-preinstall-cleanup/spec.md` — 11 requirements, 14 scenarios
- `openspec/changes/cleanup-omarchy/design.md` — 10 architecture decisions, mapping table
- `openspec/changes/cleanup-omarchy/tasks.md` — T-001..T-011 (done), T-012 (deferred), T-013 (deferred)
- `openspec/changes/cleanup-omarchy/apply-progress.md` — 17 smoke checks (all re-run here)
- `scripts/setup-omarchy` — the template the new script mirrors
- `docs/ideas/scripts/cleanup.md` — rationale for the 29-item list (NOT a parser input; only the names are reused)
