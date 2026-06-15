# Tasks — ideas-implementation (regenerated)

## Review Workload Forecast

Estimated changed lines: **~400-500 net** (previous apply hit 550 net on a smaller scope). Single-PR threshold 400 (skill) / 800 (config). Above 400-line low-risk threshold → **chained PRs recommended**, forecast class **high risk** (architectural rewrite, not additive). 3 chain slices, stacked-to-main. `delivery_strategy=ask-on-risk`; `chained_pr_strategy=ask-always`. Acceptance gate: 7/7 tests green + docs no-contradiction + archived verify-report.

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: High

## Work units (TDD strict: RED → GREEN → REFACTOR)

### WU-1. Tests RED — rewrite `tests/setup-deps.bash`
- [x] Bump `TEST_PLAN=7`; replace 6 old cases with new contract. **(PR-1: `TEST_PLAN=5`; T5 + T7 deferred to PR-2 and PR-3 per stacked-to-main.)**
- [x] T1 `./setup --omarchy` invokes `scripts/setup-omarchy` exactly once.
- [x] T2 `--omarchy --fonts` and `--omarchy --deps` are absorbed (root skips sub-scripts).
- [x] T3 `--fedora` (any combo) exits 0, no sub-script invocations.
- [x] T4 `--fonts` runs only `setup-fonts`; `--deps` runs only `setup-deps`. **(PR-1: `--deps` sub-case asserted dispatch breadcrumb only; PR-3 replaces the "choose an environment" transitional assertion with auto-detect success — T4 sub-case B now asserts `[setup-deps]` ran, which is the PR-3-aligned contract.)**
- [x] T5 env-script pre-flight blocks on missing `$DOTFILES_FONTS_DIR` (no symlink under `$HOME/.config/`). **(PR-2: also triangulates DOTFILES_FONTS_DIR override honoring the env var.)**
- [x] T6 `DOTFILES_*` (5 vars) cleanup under `env -i` + trap source grep. **(PR-1: strengthened to verify all 5 names appear in the trap line.)**
- [x] T7 `scripts/setup-deps` auto-detects (yay→omarchy, dnf→fedora, none→fail). **(PR-3: 5 sub-cases — A yay, B dnf, C none, D --omarchy override, E pacman-without-yay warns.)**
- Acceptance: 7/7 GREEN. Verify: `bash tests/setup-deps.bash` returns `# 7/7 passed` and exit 0.

### WU-2. GREEN — shrink root `setup` to thin dispatcher
- [x] Delete `run_deps`, `run_fonts`, `run_env`, `TOTAL_STEPS`, fedora short-circuit block.
- [x] Export `DOTFILES_FONTS_DIR="$HOME/.local/share/fonts/autanasoft"`; include in `trap`.
- [x] Refactor main into single `case` dispatch (omarchy / fedora / fonts / deps).
- [x] Trim `usage()` precedence prose to match new model.
- Acceptance: T1, T2, T3, T4, T6 GREEN.

### WU-3. GREEN — expand `scripts/setup-omarchy` to own full flow
- [x] Add `invoke_setup_deps` / `invoke_setup_fonts` helpers (subprocess, pass `--omarchy` to deps for PR-2, plus `$DRY_RUN`).
- [x] Add own `TOTAL_STEPS` / `current_step` for `Step X/N` labels (4 steps: deps, fonts, symlinks, validate; pre-flight non-mutating between fonts and symlinks).
- [x] Pre-flight reads `$DOTFILES_FONTS_DIR` (not hardcoded path); defaults to `$HOME/.local/share/fonts/autanasoft` when unset.
- [x] Preserve `apply_symlinks`, `seed_ssh_config`, `validate_system`.
- Acceptance: T5 GREEN.

### WU-4. GREEN — add `detect_env()` to `scripts/setup-deps`
- [x] Probe table: yay→omarchy, pacman→omarchy+warn, dnf→fedora, rpm→fedora+warn, none→fail.
- [x] `--omarchy` / `--fedora` become optional overrides (skip probe).
- [x] Replace "choose an environment" error with "Could not detect a supported package manager".
- [x] Update `usage()` to document auto-detection.
- Acceptance: T7 GREEN. Full run 7/7.

### WU-5. GREEN — read `DOTFILES_FONTS_DIR` in `scripts/setup-fonts`
- [x] Use `DOTFILES_FONTS_DIR` if set, else current default.
- Acceptance: behavior preserved when unset; honors override.

### WU-6. REFACTOR + docs rewrite `docs/setup.md`
- [x] Rewrite Quick Path, dispatch matrix, Scripts table; add env-detection section.
- [x] Cleanup subsection lists 5 vars.
- Acceptance: doc matches code, no contradictions.

### WU-7. Archive stale verify-report
- [x] `git mv verify-report.md verify-report.deprecated-20260614.md`. (renamed with `mv` because the report was untracked; the same archive intent.)
- Acceptance: archived; new report produced after re-verify.

## Commit plan (chained PRs, stacked-to-main)

- PR-1 — Tests + root shrink (WU-1, WU-2): `setup`, `tests/setup-deps.bash`.
- PR-2 — Env script + fonts override (WU-3, WU-5): `scripts/setup-omarchy`, `scripts/setup-fonts`.
- PR-3 — Auto-detect + docs + archive (WU-4, WU-6, WU-7): `scripts/setup-deps`, `docs/setup.md`, verify-report rename.

## Out of scope

No `scripts/setup-fedora`; no symlink, backup, or SSH-seeding changes; no test framework changes.
