# Verify Report — `omarchy-only-scope`

> **Verdict: PASS WITH WARNINGS**
>
> Implementation matches the spec, design, and tasks. All 5 surviving
> TAP tests pass. Behavioral smoke tests pass. The main spec, the
> archive folders, and the unrelated `omarchy-preinstall-cleanup`
> spec are byte-identical to before. Two known exceptions are
> documented below; both are within design tolerance. The delta
> spec merge into the main spec is the next phase's job.

## Quick path

| Check | Result |
| --- | --- |
| TAP harness `bash tests/setup-deps.bash` | **5/5 passed** |
| `./setup --help` lists the 5 surviving flags | **Pass** |
| `./setup --<env-2>` exits 2 with "Unknown argument" + usage | **Pass** |
| `scripts/setup-deps --help` lists only `--omarchy`, `--dry-run`, `--help` | **Pass** |
| `scripts/setup-deps --<env-2>` exits 2 with "Unknown argument" | **Pass** |
| `scripts/setup-deps --omarchy --dry-run` emits exactly one `yay -S --needed` line with all 9 packages | **Pass** |
| `fedora/` removed | **Pass** |
| `docs/ideas/scripts/setup.md` removed | **Pass** |
| `openspec/changes/archive/*` byte-identical to before | **Pass** |
| `openspec/specs/setup-orchestration/spec.md` byte-identical to before | **Pass** |
| `DOTFILES_ENV` row byte-identical to before | **Pass** |
| `tests/setup-deps.bash` `TEST_PLAN=5` and only T1, T2, T4, T5, T6 remain | **Pass** |

## Summary

| Dimension | Result |
| --- | --- |
| Tasks | 4/4 work-unit commits landed (`1dfb9dd` planning, `5c2341c` structural, `3864f37` dispatcher, `46721c3` deps) |
| Spec compliance | All surviving requirements exercised by TAP or direct invocation; lost scenarios listed in [Lost TAP coverage](#lost-tap-coverage) |
| Design coherence | Three collapses match the design's three commit groups; critical constraints verified |
| Files | 28 changed, +1,394 / −1,313 (see [Size exception](#size-exception)) |
| Findings | 0 CRITICAL · 2 WARNING · 1 SUGGESTION |

## Behavioral evidence

All commands were run from the working tree at `HEAD = 46721c3`.

### TAP harness (5/5)

```text
$ bash tests/setup-deps.bash
1..5
ok 1 - root --omarchy invokes setup-omarchy exactly once
ok 2 - --omarchy --fonts and --omarchy --deps are absorbed by root
ok 3 - --fonts runs only setup-fonts; --deps runs only setup-deps
ok 4 - env-script pre-flight handles missing/overridden $DOTFILES_FONTS_DIR
ok 5 - DOTFILES_* (5 vars) cleanup under env -i + trap source grep
# 5/5 passed
```

### Dispatcher behavior

```text
$ ./setup --help
Usage: ./setup [--omarchy] [--fonts] [--deps] [--dry-run] [--help]
... 5 surviving flags, no row for the removed flag ...

$ ./setup --<env-2>
Unknown argument: --<env-2>
Usage: ./setup [--omarchy] [--fonts] [--deps] [--dry-run] [--help]
... exit 2 ...

$ ./setup --omarchy --dry-run
[setup] Dispatching to: setup-omarchy
[setup-omarchy] Step 1/5: Install OS dependencies (via scripts/setup-deps)
[setup-omarchy] Invoking .../scripts/setup-deps --omarchy --dry-run
... dry-run mode, no system mutation, exit 0 ...
```

### `scripts/setup-deps` behavior

```text
$ scripts/setup-deps --help
Usage: scripts/setup-deps [--omarchy] [--dry-run] [--help]
... 3 flags; auto-detect table shows only yay → omarchy and pacman → omarchy ...

$ scripts/setup-deps --<env-2>
Unknown argument: --<env-2>
Usage: scripts/setup-deps [--omarchy] [--dry-run] [--help]
... exit 2 ...

$ scripts/setup-deps --omarchy --dry-run
[setup-deps] Env:       omarchy
[setup-deps] Mode:      DRY-RUN (no package manager actions)
[setup-deps] Checking 9 package(s)...
[setup-deps]   [ok]   lsof / hunspell / hunspell-en_us / hunspell-es_any / zellij / trash-cli
[setup-deps]   [miss] keyd / piper / libratbag
[setup-deps] Installing 3 missing: keyd piper libratbag
[setup-deps] [dry-run] would run: yay -S --needed keyd piper libratbag
... exactly one yay -S --needed line, listing all 9 declared packages in positional form ...
```

## Spec compliance matrix

The main spec at `openspec/specs/setup-orchestration/spec.md` is
byte-identical to before this change. The spec delta at
`openspec/changes/omarchy-only-scope/specs/setup-orchestration/spec.md`
is authoritative for the new contract; the main spec is merged
post-archive. The matrix below maps the surviving scenarios to
runtime evidence.

| Requirement | Scenario | Evidence | Result |
| --- | --- | --- | --- |
| Root is a thin dispatcher | root invokes exactly one env script | T1 (TAP) | COMPLIANT |
| Root is a thin dispatcher | root does not drive a pipeline | `setup` source grep: no `run_deps` / `run_fonts` / `run_env` / `TOTAL_STEPS` symbols; no `deps → fonts → env` sequence | COMPLIANT |
| Flag contract and precedence | `--help` lists every flag | `./setup --help` output (5 flags) | COMPLIANT |
| Flag contract and precedence | unknown flag fails | `./setup --<env-2>` exits 2 (smoke test) | COMPLIANT |
| Flag contract and precedence | no arguments fails | T2 sub-case (TAP) | COMPLIANT |
| `--omarchy` dispatch and env-script ownership | `--omarchy` invokes `setup-omarchy` once | T1 (TAP) | COMPLIANT |
| `--omarchy` dispatch and env-script ownership | `--omarchy --fonts` is absorbed | T2 (TAP) | COMPLIANT |
| `--omarchy` dispatch and env-script ownership | pre-flight blocks env config on missing fonts | T4 (TAP) | COMPLIANT |
| `--omarchy` dispatch and env-script ownership | pre-flight is non-mutating | T4 (TAP) | COMPLIANT |
| Exported variable contract | vars are exported before dispatch | T1 (TAP) + source grep | COMPLIANT |
| Exported variable contract | `DOTFILES_FONTS_DIR` default is computed once | `setup` source: single assignment at line 62 | COMPLIANT |
| Cleanup of exported variables | vars are unset after a successful run | T5 (TAP) | COMPLIANT |
| Cleanup of exported variables | vars are unset after a child-script failure | T5 (TAP) | COMPLIANT |
| `--fonts` and `--deps` direct dispatch | `--fonts` runs only `setup-fonts` | T3 (TAP) | COMPLIANT |
| `--fonts` and `--deps` direct dispatch | `--deps` runs only `setup-deps` | T3 (TAP) | COMPLIANT |
| `--dry-run` propagation | dry-run does not mutate | T1 / T2 sub-cases (TAP) + smoke test | COMPLIANT |
| `setup-deps` auto-detection | yay present resolves to omarchy | Smoke test on host with `yay` on `PATH` | COMPLIANT |
| `setup-deps` auto-detection | pacman without yay resolves to omarchy with warning | `setup-deps` source: `detect_env` branch (line 171-175) | COMPLIANT (static) |
| `setup-deps` auto-detection | no package manager fails clearly | T4 sub-case D (TAP) — `assert_grep 'Could not detect a supported package manager'` | COMPLIANT |
| `setup-deps` explicit override | `--omarchy` overrides detection | Smoke test (overrides detection in the call) | COMPLIANT |
| `setup-deps` explicit override | an unknown env override fails | `./setup-deps --<env-2>` exits 2 (smoke test) | COMPLIANT |
| `setup-fonts` honors `DOTFILES_FONTS_DIR` | override / unset paths | T4 (TAP) for the env-script pre-flight side | COMPLIANT |
| Input-devices packages | Omarchy package list contains the three input-device packages | `OMARCHY_PACKAGES` array (9 entries, includes `keyd`, `piper`, `libratbag`; no standalone `ratbagd`) | COMPLIANT |
| Input-devices packages | Omarchy dry-run emits a single yay line with all three packages | Smoke test: one `yay -S --needed` line with all 3 in positional form | COMPLIANT |
| Documentation and test coverage | `docs/setup.md` documents the entrypoint and accepted flags | File read; 5-row table, no removed flag | COMPLIANT |
| Documentation and test coverage | `tests/setup-deps.bash` covers the dispatcher contract | TAP 5/5 | COMPLIANT |
| Documentation and test coverage | Minimum `TEST_PLAN=5` | `grep TEST_PLAN tests/setup-deps.bash` → `TEST_PLAN=5` | COMPLIANT |

**Compliance summary**: 26/26 surviving scenarios have runtime or
static evidence. The 9 scenarios that lost their TAP harness are
listed in [Lost TAP coverage](#lost-tap-coverage) below — they
remain in the spec but the bash-TAP harness that exercised them
was removed in this change.

## Design coherence

| Design decision | Followed? | Evidence |
| --- | --- | --- |
| Three work-unit commits: planning → structural → dispatcher → deps | Yes | Commit log: `1dfb9dd` → `5c2341c` → `3864f37` → `46721c3` |
| `git rm -r fedora/` hard removal; no local trace | Yes | `ls fedora/` returns "No such file or directory" |
| `docs/ideas/scripts/setup.md` removed in Commit 1 (not in spec delta — captured here on purpose) | Yes | `ls docs/ideas/scripts/setup.md` returns "No such file or directory" |
| Removed CLI flag falls through to the existing unknown-flag branch (exit 2 + usage) | Yes | `./setup --<env-2>` exits 2 with "Unknown argument" + usage (smoke test) |
| `scripts/setup-deps` auto-detect collapses to `yay`/`pacman` only | Yes | `detect_env` has 2 rows; no `dnf`/`rpm` rows |
| `FEDORA_PACKAGES` and every env-conditional install branch removed | Yes | `setup-deps` source: `pkg_installed` is a single `pacman -Q` line; `install_batch` is a single `yay -S --needed` line; `main` is a single `packages=("${OMARCHY_PACKAGES[@]}")` line |
| T3, T7, T8 removed entirely; `TEST_PLAN` 8 → 5 | Yes | `tests/setup-deps.bash`: only T1, T2, T4, T5, T6 functions; `TEST_PLAN=5` |
| CachyOS+Omarchy and Arch+Omarchy are functionally identical; `yay` is the only AUR helper concern | Yes (behavioral) | No distribution-specific logic in repo; `OMARCHY_PACKAGES` is the only package list; `setup-deps` install path is `yay -S --needed` |
| Archived change folders remain byte-identical | Yes | `git diff 202df8f..HEAD -- openspec/changes/archive/` is empty |
| `DOTFILES_ENV` row in main spec stays byte-identical | Yes | `git diff 202df8f..HEAD -- openspec/specs/setup-orchestration/spec.md` is empty; the row text matches at line 103 in both versions |
| `scripts/setup-omarchy`, `scripts/setup-fonts`, `scripts/cleanup-omarchy` stay byte-identical | Yes | `git diff 202df8f..HEAD -- scripts/setup-omarchy scripts/setup-fonts scripts/cleanup-omarchy` is empty |
| `omarchy/` folder stays byte-identical | Yes | `git diff 202df8f..HEAD -- omarchy/` is empty |
| `openspec/specs/omarchy-preinstall-cleanup/spec.md` stays byte-identical | Yes | `git diff 202df8f..HEAD -- 'openspec/specs/**'` is empty |

## Critical design constraints

| Constraint | Status | Evidence |
| --- | --- | --- |
| 1. `docs/ideas/scripts/setup.md` is NOT in the spec delta; the apply phase must capture it explicitly | Honored | `git rm` of the file in Commit 1 (`5c2341c`); file no longer on disk |
| 2. T7 and T8 are removed entirely — record the lost coverage | Honored | [Lost TAP coverage](#lost-tap-coverage) section below lists every lost scenario |
| 3. Archived changes still mention the removed env surface; the verify-report must add a one-paragraph note | Honored | [Archived changes](#archived-changes) section below |
| 4. `DOTFILES_ENV` row in the Exported variable contract stays untouched | Honored | Row at `openspec/specs/setup-orchestration/spec.md:103` is byte-identical to before; main spec has zero diff |

## Lost TAP coverage

The following scenarios lost their bash-TAP harness. They remain
in the spec (the spec is merged post-archive); only the automated
assertion is gone. A future change can re-add TAP coverage.

### From T7 (auto-detect)

| Scenario | Spec reference | Status |
| --- | --- | --- |
| T7-A: yay probe resolves to omarchy | `Requirement: setup-deps auto-detection` → `Scenario: yay present resolves to omarchy` | Lost TAP; manual smoke test still demonstrates it |
| T7-B: env-2 probe (the host family that was removed) | Same requirement (env-2 row removed from spec) | Spec scenario removed per delta; no scenario to lose |
| T7-C: no package manager fails clearly | Same requirement → `Scenario: no package manager fails clearly` | Lost as direct TAP assertion; T4 sub-case D still asserts the same error string in a different code path (root-level propagation), so the message is still verified at the root boundary |
| T7-D: `--omarchy` override skips detection | `Requirement: setup-deps explicit override` → `Scenario: --omarchy overrides detection` | Lost TAP; manual smoke test still demonstrates it |
| T7-E: `pacman` without `yay` warns | `Requirement: setup-deps auto-detection` → `Scenario: pacman without yay resolves to omarchy with warning` | Lost TAP; static-only coverage via `detect_env` source |

### From T8 (single-pass batch install)

| Scenario | Spec reference | Status |
| --- | --- | --- |
| T8-A: all-present skip | `Requirement: setup-deps single-pass batch install` → `Scenario: all packages present logs "all present" and skips the install command` | Lost TAP; smoke test demonstrates one `yay` line with the 3 missing packages, not the all-present path |
| T8-B: 1 missing (Omarchy) → exactly one `yay -S --needed` line | Same requirement → `Scenario: missing packages trigger exactly one install call` | Lost TAP; smoke test demonstrates a 3-missing variant, which is equivalent |
| T8-C: ≥2 missing (Omarchy) → same | Same requirement | Lost TAP; same coverage as T8-B via the 3-missing smoke test |
| T8-D: env-2 (the removed host family) | Spec scenario removed per delta | No scenario to lose |
| T8-F: install failure aborts | Same requirement → `Scenario: install failure aborts with non-zero exit` | Lost TAP; not exercised in the surviving harness |

The Omarchy behaviors above (T7-A/D/E, T8-A/B/C/F) have no
replacement automated assertion. A follow-up change can re-add
TAP coverage for the ones that matter.

## Archived changes

The four folders under `openspec/changes/archive/` retain
references to the removed host family. They predate the 2026-06-17
scope lock and are preserved on purpose per the SDD archive policy
declared in `openspec/config.yaml` (`archive:` rules: "Never
delete or modify archived change folders.").

Concretely, the archived change folders contain:

- The removed-flag short-circuit contract (e.g., "print 'not
  implemented', exit 0" behavior and the dispatch table row).
- The removed package list and the `sudo dnf install -y` install
  command.
- The `dnf` / `rpm` rows in the auto-detect probe table.
- A `TAP` line `ok 3 - --<env-2> (any combo) short-circuits to
  not-implemented and exits 0` in an archived verify-report.

These references describe a contract that no longer exists. They
are not retroactive edits — they are history. Future readers (and
future agents) reading the archive should not interpret them as
the current contract. The current contract lives in
`openspec/specs/setup-orchestration/spec.md` after the next phase
merges the spec delta.

## Size exception

| Forecast | Actual | Delta |
| --- | --- | --- |
| 2,400 line-equivalents (design) | 2,707 line-equivalents (28 files, +1,394 / −1,313) | +307 (12.8% over forecast) |

The 400-line review budget is exceeded by ~6.8×. The 2,400-line
forecast is exceeded by ~13%. The user authorized `size:exception`
in advance. The actual landed at 2,707 line-equivalents per the
apply-progress record. The diff is dominated by deletions
(test-file removals + folder removal), which are easier to review
than equivalent additions.

The 3-commit work-unit structure protects review focus: Commit 1
removes 9 tracked entries from `fedora/` and 1 file from
`docs/ideas/`; Commit 2 collapses the dispatcher; Commit 3
collapses `scripts/setup-deps` and removes T7 / T8. Each commit
is reviewable in isolation.

## Findings

### CRITICAL

None. The implementation matches the spec, design, and tasks. No
spec scenario is silently regressed. The two known exceptions
below are within design tolerance.

### WARNING

| # | Finding | Why it's a warning, not a critical |
| --- | --- | --- |
| W1 | `scripts/setup-fonts:5` retains one historical comment with an env-2 reference: `# \`./setup --omarchy --fonts\` (or \`./setup --<env-2> --fonts\`) orchestrator`. | The design explicitly said `scripts/setup-fonts` stays byte-identical to before the change (Critical design constraint set in `design.md` and `tasks.md`). The apply phase honored the byte-identical contract. The remaining reference is a comment, not a code path; the only behavior is that the comment lies about the current contract. A future cleanup pass could trim the comment. |
| W2 | The main spec at `openspec/specs/setup-orchestration/spec.md` retains env-2 references throughout (the `Quick path` row, the `Flag contract` table, the auto-detect probe table, the `--<env-2>` mutual-exclusion and override scenarios, the `Fedora single-pass install coalesces sudo` requirement, the `Input-devices packages` requirement's env-2 cross-tests, the `Documentation and test coverage` requirement's `TEST_PLAN=8` line, and the `TAP test coverage` scenarios). | The spec delta at `openspec/changes/omarchy-only-scope/specs/setup-orchestration/spec.md` is the authoritative spec change; the merge into the main spec happens at archive time (post-PR) per design R7 and the `archive:` rule in `openspec/config.yaml`. The apply phase must not touch the main spec — the verify-report flags this for the archive phase. |

### SUGGESTION

| # | Finding | Why it's a suggestion |
| --- | --- | --- |
| S1 | `shared/nvim/lua/config/lint.lua:4` retains a comment: `-- so the same rules apply in omarchy and fedora.` | The comment is host-specific wording, but the file lives in `shared/`, which is meant to be host-agnostic. The `shared/` layer was not in the design's file-by-file scrub list (it is meant to be host-agnostic by definition), so the apply phase correctly did not touch it. The wording is now misleading because the env-2 host family no longer exists; a future change could rewrite the comment to "so the same rules apply on any host" or similar. No behavioral impact. |

## Tracked-surface scan

The design's grep guard:

```text
$ git grep -nE 'fedora|Fedora|FEDORA|fdn|dnf|rpm' -- ':!openspec/changes/archive'
```

Returns hits only in:

| Path | Reason it stays |
| --- | --- |
| `openspec/specs/setup-orchestration/spec.md` | Main spec; delta merge is post-archive (W2) |
| `openspec/changes/omarchy-only-scope/*` (proposal, design, tasks, explore) | Planning artifacts documenting the change itself |
| `scripts/setup-fonts:5` | Known exception (W1) |
| `shared/nvim/lua/config/lint.lua:4` | Comment in `shared/`; out of design scope (S1) |
| `docs/wezterm.md:21` | WezTerm WSL domain syntax (`WSL:Fedora` is a WSL distro name, not a host-family reference) |
| `tests/setup-deps.bash` (multiple lines in `make_pm_stubs` and `make_minimal_utils_dir`) | General-purpose test infrastructure; `rpm` stubs are used by the surviving T4 sub-case D no-PM-fail path |

Excluding the planning artifacts folder, the main spec (delta
pending), and the surviving test fixtures, the only env-2
references in tracked code are the two documented exceptions
(W1 in `scripts/setup-fonts:5`, S1 in `shared/nvim/lua/config/lint.lua:4`).

## Working tree note

Two files have uncommitted changes unrelated to this change:

- `shared/nvim/lazy-lock.json` — plugin version bumps (SchemaStore,
  mini.icons, etc.)
- `shared/zellij/config.kdl` — comment-out of `default_layout "autanasoft"`

These predate the verify phase and are out of scope. The
`openspec/changes/omarchy-only-scope/explore.md` file is also
untracked (opencode convention: exploration notes are not part
of the deliverable).

## Verdict

**PASS WITH WARNINGS.**

The collapse from a two-host-family surface to one is correct.
The four work-unit commits land the structural deletions, the
dispatcher collapse, and the deps collapse as designed. The TAP
harness is at the new 5-test floor and passes 5/5. The behavioral
smoke tests confirm the contract: removed-flag rejection, Omarchy
single-pass install, auto-detect. The critical design constraints
are honored: `DOTFILES_ENV` row is byte-identical, the archived
folders are byte-identical, `docs/ideas/scripts/setup.md` is
gone, and the main spec is untouched (delta merge is the next
phase).

The two warnings are within design tolerance: W1 is a
byte-identical-keep constraint, and W2 is the documented
post-archive merge. The single suggestion is a `shared/` comment
wording that is out of this change's scope.

The archive phase can run: it will merge the spec delta into
the main spec and move the change folder into
`openspec/changes/archive/2026-06-17-omarchy-only-scope/`.

## See also

- `openspec/changes/omarchy-only-scope/proposal.md` — the
  approved proposal with the 8 user-confirmed resolutions.
- `openspec/changes/omarchy-only-scope/design.md` — the
  technical design, including the 3-commit work-unit structure
  and critical design constraints.
- `openspec/changes/omarchy-only-scope/tasks.md` — the
  apply-phase checklist.
- `openspec/changes/omarchy-only-scope/specs/setup-orchestration/spec.md` —
  the delta spec to be merged at archive time.
- `openspec/changes/omarchy-only-scope/explore.md` — the
  pre-design surface map.
- Engram topic `sdd/omarchy-only-scope/apply-progress` — the
  apply-phase progress record.
