# Apply Progress: setup-deps-batch-install

## Goal

Refactor `scripts/setup-deps` from a per-package install loop into a
single-pass batch install per environment, with an all-present early-exit
and a consolidated `installed / present / missing` summary.

## Mode

Standard (not Strict TDD). Repo has no test runner, and `openspec/config.yaml`
does not pin `strict_tdd: true`.

## Completed Tasks

### Phase 1: Test fixture (T8)

- [x] 1.1 Bumped `TEST_PLAN=7` → `TEST_PLAN=8` in `tests/setup-deps.bash`.
- [x] 1.2 Added `test_setup_deps_single_pass_batch_install` with sub-cases
  A, B, C, D, F (no E — AUR flag set was removed in rev 2). Reuses
  `make_pm_stubs` and `make_minimal_utils_dir` from T7. Each sub-case
  uses `env -i PATH="$stubs:$utils_dir"` to strip host PMs.
  - T8-A all-present: pacman/rpm stub overridden to exit 0. Asserts the
    "all present" log line, no install call in stub log, no `Summary:`
    line in output, exit 0.
  - T8-B single missing (Omarchy): pacman exits 1, yay exits 0. Asserts
    exactly one `yay -S --needed` line in the script output (dry-run
    preview), per-pkg `[miss]` lines, no PM invocation in stub log.
  - T8-C >= 2 missing (Omarchy): same stub shape as B. The single
    `yay -S --needed` line's args contain all six Omarchy package
    names as substrings (order-agnostic).
  - T8-D >= 2 missing (Fedora): rpm exits 1, dnf exits 0. Exactly one
    `sudo dnf install -y` line in the output, no `sudo -v` in stub log
    (Fedora contract: one sudo per run), every Fedora package in args.
  - T8-F install failure: pacman exits 1, yay exits 7 in real mode
    (no --dry-run). Asserts exit 7, exactly one `yay` invocation in
    stub log, no `Summary:`, no `Setup complete.`.
- [x] 1.3 Verified T8 passes; T1–T7 stay green.

### Phase 2: Script refactor

- [x] 2.1 Added `MISSING=()` and counters `installed=0`, `present=0`,
  `missing=0` near the top of `main`.
- [x] 2.2 Added `collect_missing()`: iterates the env package list,
  calls `pkg_installed`, logs `[ok]` / `[miss]`, appends misses to
  `MISSING=()`, increments `present` (for ok) and `missing` (for miss).
- [x] 2.3 Added `install_batch()`: builds the env command as an array
  — Omarchy: `yay -S --needed "${MISSING[@]}"`; Fedora:
  `sudo dnf install -y "${MISSING[@]}"`. Dry-run logs and returns 0;
  real mode requires the PM on PATH then execs `"${cmd[@]}"`.
- [x] 2.4 All-present early-exit: if `MISSING` is empty, logs
  `All ${#packages[@]} packages present; nothing to install.` and
  exits 0 BEFORE the install call. No `Summary:` on this path.
- [x] 2.5 Else path: logs
  `Installing ${#MISSING[@]} missing: ${MISSING[*]}` (locked wording),
  runs `install_batch`, then logs
  `Summary: $installed installed, $present present, $missing missing.`.
- [x] 2.6 Commented out `pm_install_cmd` and `install_package` with
  `# Reason: replaced by install_batch in change setup-deps-batch-install`.
- [x] 2.7 Preserved: auto-detect, `--omarchy`/`--fedora` overrides,
  `--help`, env-var passthrough, dry-run, `set -euo pipefail`, 4-space
  indent, Fedora "no `sudo -v` upfront" contract. Updated the
  top-of-file comment to reflect the new single-batch install command.
- [x] 2.8 Verified T1–T7 still pass; T8 is green.

### Phase 3: Documentation

- [x] 3.1 Appended a 1-2 sentence note to `docs/setup.md` "Dependency
  Detection": "Dependencies are installed in a single batch per
  environment. On Fedora this coalesces to a single sudo password
  prompt; on Omarchy a single `yay` invocation produces one install
  confirmation for the whole batch." No AUR prompt suppression
  mentioned.
- [x] 3.2 Re-read the section; the table above the note is unchanged,
  the new note flows naturally under the override examples.

## Files Changed

| File | Action | Description |
| --- | --- | --- |
| `scripts/setup-deps` | Modified | Added `MISSING=()`, `collect_missing()`, `install_batch()`. All-present early-exit. Consolidated `Installing N missing: ...` line. Final `installed / present / missing` summary. Commented out `pm_install_cmd` and `install_package` with `# Reason:`. |
| `tests/setup-deps.bash` | Modified | Bumped `TEST_PLAN=8`. Added `test_setup_deps_single_pass_batch_install` (sub-cases A, B, C, D, F) and a matching `run_test` line. |
| `docs/setup.md` | Modified | Appended single-batch install note to "Dependency Detection" section. |
| `openspec/changes/setup-deps-batch-install/apply-progress.md` | Created | This file. |

## Test Result

`bash tests/setup-deps.bash` → **8/8 passed**.

```
1..8
ok 1 - root --omarchy invokes setup-omarchy exactly once
ok 2 - --omarchy --fonts and --omarchy --deps are absorbed by root
ok 3 - --fedora (any combo) short-circuits to not-implemented and exits 0
ok 4 - --fonts runs only setup-fonts; --deps runs only setup-deps
ok 5 - env-script pre-flight handles missing/overridden $DOTFILES_FONTS_DIR
ok 6 - DOTFILES_* (5 vars) cleanup under env -i + trap source grep
ok 7 - scripts/setup-deps auto-detects env (yay/dnf/none) and respects override
ok 8 - scripts/setup-deps single-pass batch install per env (T8 A/B/C/D/F)
# 8/8 passed
```

## Manual Smoke Tests (verified during apply)

- `bash scripts/setup-deps --help` — usage unchanged.
- `bash scripts/setup-deps --dry-run --omarchy` (with stub PMs) — one
  `yay -S --needed` line with all 6 missing pkgs, per-pkg `[miss]`
  lines, exit 0, no actual PM invocation.
- `bash scripts/setup-deps --dry-run --fedora` (with stub PMs) — one
  `sudo dnf install -y` line with all 5 missing pkgs, no `sudo -v`,
  exit 0, no actual PM invocation.
- All-present path (pacman stub exits 0) — logs
  `All 6 packages present; nothing to install.`, exit 0, no `Summary:`
  line, no `Setup complete.`.
- Failure path (yay stub exits 7, real mode) — script exits 7, no
  `Summary:`, no `Setup complete.`, exactly one `yay` invocation in
  stub log.

## Deviations from Design

- In the design's `collect_missing` code block, `installed` is
  incremented for present packages. The locked summary wording
  (`Summary: $installed installed, $present present, $missing missing.`)
  and task 2.1 (`installed=0, present=0, missing=0`) are the canonical
  contract, so the implementation increments `present` for ok packages
  and `missing` for misses, then rolls the missing count into
  `installed` after `install_batch` returns 0. The design's snippet
  was a typo; the summary semantics are the source of truth.
- T8 sub-case A needed pacman/rpm to exit 0 (all present). The
  existing `make_pm_stubs` helper hardcodes those to exit 1, so the
  test overrides the two stubs after calling `make_pm_stubs`. This is
  a test-only deviation, not a script change.

## Issues Found

None. All 8/8 tests pass; manual smoke tests align with the design
contract.

## Next Step

`bash tests/setup-deps.bash` is green; the implementation matches
spec, design, and tasks. Ready for `sdd-verify` (to formally prove the
suite is green) or `sdd-archive` (to merge the delta spec into
`openspec/specs/setup-orchestration/spec.md`). Phase 4 (spec archive)
in `tasks.md` is explicitly owned by `sdd-archive` and is not done
here.
