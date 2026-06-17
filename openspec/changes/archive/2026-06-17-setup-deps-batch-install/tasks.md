# Tasks: setup-deps — single-pass batch install

## Review Workload Forecast

| Field | Value |
|---|---|
| Estimated changed lines | ~200 (script +60/−20, tests +130/0, docs +6/0) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | single-pr |
| Delivery strategy | single-pr |
| Chain strategy | size-exception |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: Low

## Phase 1: Test fixture (T8, red-first)

- [x] 1.1 In `tests/setup-deps.bash`, bump `TEST_PLAN=7` → `TEST_PLAN=8` and append one `run_test` line for T8 before the summary echo.
- [x] 1.2 Add `test_setup_deps_single_pass_batch_install` reusing `make_pm_stubs` and `make_minimal_utils_dir` from T7. Each sub-case uses `env -i PATH="$stubs:$utils_dir"` to strip host PMs.
  - T8-A all-present: `pacman`/`rpm` stub exit 0. Assert `all present` substring and no `yay -S` / `sudo dnf` line in stub log; exit 0.
  - T8-B single missing (Omarchy): `pacman` exits 1, `yay` exits 0. Assert exactly one `yay -S --needed <pkg>` line; per-pkg `[miss]` present; no `sudo` line; exit 0.
  - T8-C ≥2 missing (Omarchy): `pacman` exits 1. Assert exactly one `yay -S --needed` line whose args contain all missing pkgs (substring set, not order); exit 0.
  - T8-D ≥2 missing (Fedora): `rpm` exits 1. Assert exactly one `sudo dnf install -y` line with all missing pkgs; `sudo -v` never appears in stub log; exit 0.
  - T8-F install failure: `pacman` exits 1, `yay` exits 7. Assert exit 7; exactly one `yay` invocation; no `Summary:` line; no `Setup complete.`
- [x] 1.3 Run `bash tests/setup-deps.bash`. T8 must fail (red); T1–T7 stay green. Sub-cases: A, B, C, D, F (no E; AUR flag set removed in rev 2).

## Phase 2: Script refactor (green)

- [x] 2.1 In `scripts/setup-deps`, declare `MISSING=()` and counters `installed=0`, `present=0`, `missing=0` near the top of `main`.
- [x] 2.2 Add `collect_missing()`: iterate env package list, call `pkg_installed`, log `[ok]` / `[miss]`, append misses to `MISSING=()`, increment counters.
- [x] 2.3 Add `install_batch()`: build `cmd` per env (`yay -S --needed ${MISSING[*]}` / `sudo dnf install -y ${MISSING[*]}`), exec with `"${MISSING[@]}"` for quoting. Dry-run: log and return 0. Real mode: `command -v` check then `$cmd`.
- [x] 2.4 In `main`, after `collect_missing`: if `MISSING` is empty, log `All ${#packages[@]} packages present; nothing to install.` and `exit 0` BEFORE the install call. No `Summary:` in this path.
- [x] 2.5 Else: log `Installing ${#MISSING[@]} missing: ${MISSING[*]}` (locked wording), run `install_batch`, log `Summary: $installed installed, $present present, $missing missing.`
- [x] 2.6 Comment out `pm_install_cmd` and `install_package` with `# Reason: replaced by install_batch in change setup-deps-batch-install`.
- [x] 2.7 Preserve: auto-detect, `--omarchy`/`--fedora` overrides, `--help`, env-var passthrough, dry-run, `set -euo pipefail`, 4-space indent, Fedora "no `sudo -v` upfront" contract.
- [x] 2.8 Run `bash tests/setup-deps.bash`. Target 8/8 green. T1–T7 substring assertions on `yay -S --needed` / `sudo dnf install -y` must still pass.

## Phase 3: Documentation

- [x] 3.1 In `docs/setup.md` "Dependency Detection" section, append 1–2 sentences: "Dependencies are installed in a single batch per environment. On Fedora this coalesces to a single sudo password prompt; on Omarchy a single `yay` invocation produces one install confirmation for the whole batch." Do NOT mention AUR prompt suppression.
- [x] 3.2 Read the section back; confirm the new note flows naturally and the table above stays unchanged.

## Phase 4: Spec archive (deferred)

- [x] 4.1 At archive time, `sdd-archive` merges `openspec/changes/setup-deps-batch-install/specs/setup-orchestration/spec.md` into `openspec/specs/setup-orchestration/spec.md`, lifting the three delta requirements (single-pass batch install, Fedora sudo coalesce, MODIFIED "Documentation and test coverage" → `TEST_PLAN=8`) into the main spec. Owned by `sdd-archive`; do not perform now.

## Phase 5: Final verification

- [x] 5.1 `bash tests/setup-deps.bash` → 8/8 green.
- [x] 5.2 `bash scripts/setup-deps --help` → usage unchanged.
- [x] 5.3 `bash scripts/setup-deps --dry-run --omarchy` (with stub PMs) → one `yay -S --needed` line with all missing pkgs; no `yay` invocation; exit 0.
- [x] 5.4 `bash scripts/setup-deps --dry-run --fedora` (with stub PMs) → one `sudo dnf install -y` line with all missing pkgs; no `sudo` invocation; exit 0.

## Locked wording (do not change)

| Token | Value |
|---|---|
| Consolidated log line | `Installing ${#MISSING[@]} missing: ${MISSING[*]}` |
| All-present line | `All ${#packages[@]} packages present; nothing to install.` |
| Final summary | `Summary: $installed installed, $present present, $missing missing.` |
| Removal comment | `# Reason: replaced by install_batch in change setup-deps-batch-install` |
| T8 sub-cases | A, B, C, D, F (no E) |
| `TEST_PLAN` | 8 |
| Out of scope | `--sudoloop`, `--yes`/`-y`, AUR prompt suppression, `sudo -v` upfront on Fedora |
