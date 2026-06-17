# Archive Report: setup-deps-batch-install

**Change**: `setup-deps-batch-install`
**Archived at**: 2026-06-17
**Archived by**: `sdd-archive`
**Artifact store**: `openspec`
**Verification reference**: `openspec/changes/archive/2026-06-17-setup-deps-batch-install/verify-report.md`

---

## Change Summary

Refactored `scripts/setup-deps` from a per-package install loop into a
single-pass batch install per environment. Missing packages are collected
into `MISSING=()` first; the env's package manager is then invoked exactly
once with all of them as positional arguments. The change preserves per-package
`[ok]` / `[miss]` log lines, adds an all-present early-exit, and emits a
final `installed / present / missing` summary. Symmetric for both Omarchy
and Fedora environments.

---

## Spec Merge Summary

**Delta spec**: `openspec/changes/setup-deps-batch-install/specs/setup-orchestration/spec.md`
**Main spec**: `openspec/specs/setup-orchestration/spec.md`

| Action | Requirement | New location in main spec |
|--------|-------------|---------------------------|
| ADDED | `setup-deps single-pass batch install` (4 scenarios) | After `setup-deps explicit override` requirement; lines 307–343 |
| ADDED | `Fedora single-pass install coalesces sudo` (1 scenario) | After the above; lines 345–358 |
| MODIFIED | `Documentation and test coverage` (`TEST_PLAN=7` → `TEST_PLAN=8`; single-pass contract added) | Replaced in-place; lines 380–389 |

The `(Previously: ...)` note from the delta was dropped. All other existing
requirements are preserved unchanged. The main spec now reads as if the
requirements had always been there.

---

## Verification Result

- **Tests**: 8/8 passed (`bash tests/setup-deps.bash`)
- **CRITICAL findings**: None
- **WARNING findings**: None
- **SUGGESTION**: 1 (doc-only, non-blocker — see Follow-ups below)
- **Verification verdict**: PASS

---

## Change Directory

**Original location**: `openspec/changes/setup-deps-batch-install/`
**Archived location**: `openspec/changes/archive/2026-06-17-setup-deps-batch-install/`

Archived contents:
- `proposal.md` ✅
- `specs/setup-orchestration/spec.md` ✅ (delta spec — merged into main spec)
- `design.md` ✅
- `tasks.md` ✅ (all tasks checked)
- `apply-progress.md` ✅
- `verify-report.md` ✅
- `archive-report.md` ✅ (this file)

---

## Tasks Reconciliation

Phase 4.1 (spec archive) was deferred to `sdd-archive` and is checked above.
Phase 5 final-verification tasks (5.1–5.4) were unchecked in `tasks.md` at
apply time but confirmed complete by `verify-report` (8/8 tests green, all
smoke evidence present). Checkboxes updated at archive time per the skill's
exceptional reconciliation clause, with proof from `verify-report`.

---

## Follow-ups

### SUGGESTION (non-blocker, doc-only)

The design's `collect_missing` code block snippet (Interfaces / Contracts
section) increments `installed` for present packages. The implementation
correctly increments `present` for ok packages and rolls `missing` into
`installed` after `install_batch` returns 0. The locked summary wording
(`Summary: $installed installed, $present present, $missing missing.`)
and the `verify-report` are the canonical contract. The design snippet was
a typo; it does not affect the main spec.

**Action**: Optionally fix `design.md` to show `present=$((present + 1))`
instead of `installed=$((installed + 1))` in the `collect_missing` snippet.
No other specs are affected.

---

## Lessons Learned

- **Design-impl divergence on counters**: The design's `collect_missing`
  snippet used `installed` for present packages; the locked summary wording
  uses `installed` only for post-batch success. The implementation followed
  the locked wording. When a design snippet and a locked summary contract
  disagree, the summary wins — design authors should align snippets with
  locked wording to avoid confusion.
- **Test fixture flexibility**: T8 sub-case A required overriding the
  hardcoded `make_pm_stubs` exit values (pacman/rpm stubs normally exit 1).
  Pre-existing test helpers that encode assumptions may need overrides in
  new test scenarios.
- **Locked product decisions stayed stable**: All 4 locked decisions
  (symmetric envs, no AUR suppression, abort-on-first-error, no `-y` flag)
  remained unchanged through design → spec → apply → verify. No revision
  needed.

---

## SDD Cycle Status

**Complete**: YES. All phases (propose, spec, design, tasks, apply, verify,
archive) are done. No CRITICAL or WARNING findings block this archive.
