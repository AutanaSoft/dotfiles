# Verify Report: setup-deps-batch-install

**Change**: `setup-deps-batch-install`
**Mode**: Standard (not Strict TDD; `openspec/config.yaml` has `strict_tdd: false`)
**Verified at**: 2026-06-17

## Completeness

| Metric | Value |
| --- | --- |
| Tasks total | 14 (Phases 1–5; Phase 4 is owned by `sdd-archive`) |
| Tasks complete | 13 |
| Tasks incomplete | 1 (Phase 4.1: spec archive — explicitly deferred to `sdd-archive`) |
| Implementation tasks incomplete | 0 |

All implementation tasks (Phases 1–3, 5) are checked in `tasks.md`. Phase 4
is `sdd-archive`-owned and out of scope for verify per the locked decisions.

## Build & Tests Execution

**Build**: N/A (no build step; bash TAP harness only)

**Tests**: 8/8 passed
```text
$ bash tests/setup-deps.bash
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

**Coverage**: not available (bash TAP harness; `coverage_threshold: 0` in
`openspec/config.yaml`).

**Syntax**: `bash -n scripts/setup-deps` and `bash -n tests/setup-deps.bash`
both return 0.

## Spec Compliance Matrix

| Requirement | Scenario | Test | Result |
| --- | --- | --- | --- |
| `setup-deps single-pass batch install` | all packages present logs "all present" and skips the install command | `tests/setup-deps.bash > T8-A` | ✅ COMPLIANT |
| `setup-deps single-pass batch install` | missing packages trigger exactly one install call | `tests/setup-deps.bash > T8-B`, `T8-C`, `T8-D` | ✅ COMPLIANT |
| `setup-deps single-pass batch install` | install failure aborts with non-zero exit | `tests/setup-deps.bash > T8-F` | ✅ COMPLIANT |
| `setup-deps single-pass batch install` | final summary reports installed/present/missing | `tests/setup-deps.bash > T8-C` (success path emits summary with `missing=0`); `T8-A` (all-present does NOT emit summary) | ✅ COMPLIANT |
| `Fedora single-pass install coalesces sudo` | fedora invokes `sudo dnf install -y` once with all missing packages; no `sudo` invocation appears before that line | `tests/setup-deps.bash > T8-D` | ✅ COMPLIANT |
| `Documentation and test coverage` (MODIFIED) | docs describe single-pass install; `TEST_PLAN=8`; T8 sub-cases A–D, F present; T1–T7 still pass | `docs/setup.md` lines 48–50; `tests/setup-deps.bash` line 75 (`TEST_PLAN=8`); sub-cases A, B, C, D, F at lines 1045, 1103, 1154, 1205, 1260; T1–T7 still pass | ✅ COMPLIANT |

**Compliance summary**: 6/6 scenarios compliant. 8/8 covering tests pass.

## Correctness (Static Evidence)

| Requirement | Status | Notes |
| --- | --- | --- |
| `set -euo pipefail` preserved | ✅ | `scripts/setup-deps:37` |
| All-present early-exit: log `All N packages present; nothing to install.` and exit 0 BEFORE install call | ✅ | `scripts/setup-deps:406–409`; locked wording at line 407 |
| Consolidated log line: `Installing ${#MISSING[@]} missing: ${MISSING[*]}` | ✅ | `scripts/setup-deps:411`; locked wording |
| Final summary: `Summary: $installed installed, $present present, $missing missing.` | ✅ | `scripts/setup-deps:420`; locked wording |
| Old `pm_install_cmd` and `install_package` commented out with `# Reason: ...` | ✅ | `scripts/setup-deps:228` and `275`; removal comment marker present |
| Omarchy install command is plain `yay -S --needed` (no AUR flags) | ✅ | `scripts/setup-deps:343` `cmd=(yay -S --needed "${MISSING[@]}")`. Grep for `--cleanmenu`/`--diffmenu`/`--editmenu`/`--noremovemake`/`--batchinstall`/`--useask`/`--sudoloop` returns 0 matches. |
| Fedora install command is plain `sudo dnf install -y` | ✅ | `scripts/setup-deps:346` `cmd=(sudo dnf install -y "${MISSING[@]}"`) |
| Install command invoked exactly once per run, with all missing pkgs as positional args | ✅ | Single `cmd` array built in `install_batch()`; `MISSING` populated in `collect_missing()`; `"${MISSING[@]}"` is the exec target at line 369 |
| `install_batch` does NOT call `sudo -v` upfront | ✅ | Grep for `sudo -v` returns 0 matches; the only hit is a comment at line 338 ("There is no upfront `sudo -v` validation.") |
| 4-space shell indent in new code | ✅ | No tabs in `scripts/setup-deps`; all new function bodies (`collect_missing`, `install_batch`, `main`) use 4-space indent |
| `--dry-run` mode still works (logs install line, exits 0 without executing) | ✅ | `install_batch` at lines 350–353 logs `[dry-run] would run: ...` and returns 0; smoke confirms stub log has no PM invocation |
| `--yes` / `-y` opt-in: out of scope | ✅ | Argument parser (lines 123–147) only accepts `--omarchy`, `--fedora`, `--dry-run`, `--help`, `-h` |
| AUR PKGBUILD prompts: NOT suppressed | ✅ | `yay` invocation is plain `yay -S --needed`; no `--cleanmenu`/`--diffmenu`/etc. flags |
| Mid-batch failure: abort on first error | ✅ | `set -euo pipefail` at line 37; failure smoke (yay exit 7) shows script exits 7 with no `Summary:` and no `Setup complete.` |

## Coherence (Design)

| Decision | Followed? | Notes |
| --- | --- | --- |
| T8 (new) instead of extending T7 | ✅ | `TEST_PLAN=8`; T8 added at line 1001–1316; T7 keeps its A–E sub-cases unchanged and still passes |
| New `collect_missing()` and `install_batch()` functions | ✅ | Defined at lines 317–329 and 339–370; `main()` is a linear sequence |
| `pm_install_cmd` / `install_package` commented out with `# Reason: ...` | ✅ | Lines 228 and 275 |
| All-present early-exit BEFORE the install call; no `Summary:` in that path | ✅ | Lines 406–409 exit before `install_batch`; T8-A asserts no `Summary:` in output |
| Consolidated log: `Installing N missing: ...` | ✅ | Line 411; locked wording |
| Final summary: `Summary: X installed, Y present, Z missing.` | ✅ | Line 420; locked wording |
| Reuse `make_pm_stubs` and `make_minimal_utils_dir` from T7 in T8 | ✅ | T8 calls `make_pm_stubs` (lines 1053, 1110, 1161, 1212, 1268) and `make_minimal_utils_dir` (line 1041) |
| `env -i PATH=...` to strip host PMs | ✅ | T8 sub-cases all use `env -i` with `PATH="$stubs:$utils_dir"` |

**Design deviation (documented in `apply-progress.md`)**:
The design's `collect_missing` code block snippet increments `installed` for
present packages; the implementation correctly increments `present` and
rolls `missing` into `installed` after `install_batch` returns 0. The
apply-progress calls this out explicitly as a "design typo" with the locked
summary wording as the canonical contract. The summary semantics match the
locked wording. Not a blocker.

## Smoke Evidence (manual)

### Smoke 1: `bash scripts/setup-deps --help`

Exit 0; usage unchanged. Confirms `--help` contract intact.

### Smoke 2: `bash scripts/setup-deps --dry-run --omarchy` (host PATH — all packages already installed)

Exits 0; logs `All 6 packages present; nothing to install.`; no install
command. The host already has all Omarchy packages installed (this is a
dev host running the same package list).

### Smoke 3: synthetic `bash scripts/setup-deps --dry-run --omarchy` with stubbed PMs (all packages "missing")

```text
[setup-deps]   [miss] lsof
[setup-deps]   [miss] hunspell
[setup-deps]   [miss] hunspell-en_us
[setup-deps]   [miss] hunspell-es_any
[setup-deps]   [miss] zellij
[setup-deps]   [miss] trash-cli
[setup-deps] Installing 6 missing: lsof hunspell hunspell-en_us hunspell-es_any zellij trash-cli
[setup-deps] [dry-run] would run: yay -S --needed lsof hunspell hunspell-en_us hunspell-es_any zellij trash-cli
[setup-deps] Summary: 6 installed, 0 present, 0 missing.
[setup-deps] Setup complete.
```

Stub log: only `pacman -Q` calls. No `yay` invocation in dry-run. Confirms
single install line, no AUR flags, summary emitted, no `sudo`.

### Smoke 4: synthetic `bash scripts/setup-deps --dry-run --fedora` with stubbed PMs (all packages "missing")

```text
[setup-deps]   [miss] lsof
[setup-deps]   [miss] hunspell
[setup-deps]   [miss] hunspell-en-US
[setup-deps]   [miss] hunspell-es
[setup-deps]   [miss] trash-cli
[setup-deps] Installing 5 missing: lsof hunspell hunspell-en-US hunspell-es trash-cli
[setup-deps] [dry-run] would run: sudo dnf install -y lsof hunspell hunspell-en-US hunspell-es trash-cli
[setup-deps] Summary: 5 installed, 0 present, 0 missing.
[setup-deps] Setup complete.
```

Stub log: only `rpm -q` calls. No `sudo`, no `dnf`, no `sudo -v` invocation.
Confirms single install line, single sudo touchpoint.

### Smoke 5: real-mode install failure (yay stub exits 7)

```text
[setup-deps] Installing 6 missing: lsof hunspell hunspell-en_us hunspell-es_any zellij trash-cli
[setup-deps] Running: yay -S --needed lsof hunspell hunspell-en_us hunspell-es_any zellij trash-cli
---EXIT: 7---
```

Stub log: one `yay -S --needed ...` line. No `Summary:`, no `Setup complete.`.
Confirms abort on first error, no second install attempt.

## Issues Found

**CRITICAL**: None.

**WARNING**: None.

**SUGGESTION**:

- The design's `collect_missing` code block snippet (in the Interfaces /
  Contracts section) increments `installed` for present packages, which
  contradicts the locked summary wording. The implementation follows the
  locked wording. The deviation is documented in `apply-progress.md`. This
  is a design-doc accuracy note for the next design author; not a blocker
  for archive. The sdd-archive phase could optionally fix the design
  snippet for accuracy, but the design file lives under
  `openspec/changes/setup-deps-batch-install/` and is not propagated.

## Verdict

**PASS** — 8/8 tests green; all spec scenarios covered by passing tests;
all locked product decisions honored; all implementation contracts
verified by source inspection and runtime smoke; no CRITICAL or WARNING
findings.

**Ready for archive**: YES (subject to `sdd-archive` running the
delta-to-main spec merge per Phase 4.1 of `tasks.md`).
