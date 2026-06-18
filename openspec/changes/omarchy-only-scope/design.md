# Design: omarchy-only-scope — collapse to a single host family

## Summary

The repo collapses from a two-host-family surface to one. `git rm -r fedora/` and
`git rm docs/ideas/scripts/setup.md` remove the structural env-2 footprint. The
`./setup` dispatcher and `scripts/setup-deps` lose every env-conditional branch
and every env-2 row from their help / detection / dispatch tables; the env-2
CLI flag becomes a plain unknown-flag case and exits 2. The test plan drops
from 8 to 5 (T3, T7, T8 removed entirely; T1, T2, T4, T5, T6 stay). `setup-omarchy`,
the symlink map, the Omarchy-only input-devices install, and the
`DOTFILES_*` exported-variable contract are unchanged. CachyOS+Omarchy and
Arch+Omarchy are treated identically from this repo's perspective — the
Omarchy installer owns the base-distribution differences; this repo's only
AUR-helper concern is `yay`.

The change lands as a single PR with three work-unit commits (structural
deletions → dispatcher collapse → deps collapse + spec delta). One PR is
the right shape here: the diff is mostly deletions, the per-commit story is
linear, and the test-suite loss is a known, recorded gap that a future
change can re-cover with TAP if regressions appear.

## Context

The repo's `--<env-2>` flag has been a deliberate short-circuit since the
`--omarchy` short-circuit landed (`openspec/changes/archive/2026-06-14-ideas-implementation/`).
No `scripts/setup-fedora` was ever written; the env-2 package list and the
`dnf`/`rpm` probe rows in `scripts/setup-deps` are scaffolding for a target
that never shipped. CachyOS+Omarchy and Arch+Omarchy are already one env in
`scripts/setup-omarchy`'s preamble (the script declares all three
identical). The Omarchy installer (`omarchy` command) owns the
distribution-specific differences (kernel, pacman config, bootstrap);
this repo's role is the personal dotfiles layer, not the distribution
default. The scope lock is the explicit user decision of 2026-06-17.

The collapse is a deletion-and-narrowing, not a new design. No new
requirements, no new files except possibly a `verify-report.md` note
recording the lost automated coverage. The remaining code is
`scripts/setup-omarchy` (unchanged), `setup-fonts` (unchanged), and the
`./setup` + `scripts/setup-deps` surface narrowed to one host family.

## Goals

The eight user-confirmed resolutions from the explore phase, encoded
into the design:

| # | Resolution | Where it lands |
|---|------------|----------------|
| 1 | `git rm -r fedora/`; no local trace, recoverable from git history | Commit 1 |
| 2 | The removed CLI flag is an unknown flag → exit 2 (existing branch covers it) | Commit 2 |
| 3 | `git rm` of `FEDORA_PACKAGES` and every env-conditional install branch in `setup-deps`; auto-detect collapses to `yay`→omarchy and `pacman`→omarchy (with `yay` warning) | Commit 3 |
| 4 | Eliminate T3, T7, and T8 entirely. `TEST_PLAN` 8 → 5 (T1, T2, T4, T5, T6 remain) | Commits 2 + 3 |
| 5 | No env-2 row in the spec delta; no historical note in the modified main spec | Spec archive (post-merge) |
| 6 | CachyOS+Omarchy and Arch+Omarchy are functionally identical from this repo's perspective; the Omarchy installer handles distribution differences; this repo's only AUR helper concern is `yay` | (Behavioral statement; no code) |
| 7 | Eliminate `docs/ideas/scripts/setup.md` alongside the scope cut | Commit 1 (the spec delta misses this — see [Critical design constraints](#critical-design-constraints)) |
| 8 | Archived changes remain intact. SDD archive policy wins | (Policy; verified by verify-report) |

## Non-goals

- **No restore / archive path for the env-2 surface.** The cut is hard.
  The historical surface is recoverable from `git log` / `git revert`
  per the rollback plan in `proposal.md`.
- **No new requirements.** The change is a removal + a narrowing.
- **No automated coverage re-add for T7 / T8 Omarchy behaviors.** A future
  change can re-add TAP tests; the verify-report records which spec
  scenarios lost their bash-TAP harness.
- **No edit to `openspec/changes/archive/*`.** Archive policy wins.
  The verify-report of THIS change records what the archived env-2
  references are so future readers do not misread the current contract.
- **No commit, push, or PR without explicit user request.** Per
  `AGENTS.md` repo rules.
- **No edit to `scripts/cleanup-omarchy` or `scripts/setup-omarchy`.**
  Neither carries env-2 surface; both stay byte-identical.
- **No edit to `openspec/specs/omarchy-preinstall-cleanup/spec.md`.**
  That capability is clean of env-2 surface (verified during explore).

## Architectural approach

Three collapses, all in the same direction. None of them change the
Omarchy path's behavior — they only remove the env-2 surface that ran
alongside it.

### 1. Behavioral collapse (env-conditional code paths)

Functions that had `case "$DOTFILES_ENV_LOCAL" in omarchy|env-2) ... esac`
lose the env-2 branch and the `case` collapses to a single linear
`if/then` or to a single case arm:

| Function | File | Collapse |
|----------|------|----------|
| `detect_env` | `scripts/setup-deps` | Drop `dnf` / `rpm` rows. The probe becomes a 2-row check (`yay` → omarchy, `pacman` → omarchy-with-warn, else fail). |
| `pkg_installed` | `scripts/setup-deps` | Drop the `fedora)` arm (which called `rpm -q` / `dnf list installed`). The function is left as a single `pacman -Q "$pkg"` line. |
| `install_batch` | `scripts/setup-deps` | Drop the `fedora)` arm (which emitted `sudo dnf install -y ...`). The function is left as a single `yay -S --needed ...` line. |
| `main` | `scripts/setup-deps` | Drop the `fedora)` arm of the package-list dispatch. `packages=("${OMARCHY_PACKAGES[@]}")` becomes the only branch. |
| `main` | `setup` | Drop the `if [[ "$DOTFILES_ENV" == "fedora" ]]` short-circuit at lines 234-238. The `--<env-2>` flag is now rejected by the existing `*)` arm of the parser at line 159 (prints "Unknown argument" + usage → exit 2). |

The mutual-exclusion check in `setup` (lines 175-179) is dropped
because there is no second env flag to exclude. The validation block
at lines 181-195 is also re-evaluated: with only one env flag, the
"choose only one standalone helper" check is the only remaining
validation rule.

### 2. Structural collapse (folder + test plan)

| Surface | Action |
|---------|--------|
| `fedora/` (9 tracked entries) | `git rm -r` |
| `docs/ideas/scripts/setup.md` | `git rm` (the obsolete env-specific design note) |
| `FEDORA_PACKAGES` array in `scripts/setup-deps` | `git rm` (delete the lines) |
| `TEST_PLAN=8` in `tests/setup-deps.bash` | `TEST_PLAN=5` |
| `test_fedora_short_circuit_exits_zero` (T3) | Function body and `run_test` line removed |
| `test_setup_deps_auto_detects_env` (T7) | Function body and `run_test` line removed |
| `test_setup_deps_single_pass_batch_install` (T8) | Function body and `run_test` line line removed |
| Test-file header comment (lines 26-44) | Trimmed to a 5-test plan |

The `make_pm_stubs` and `make_minimal_utils_dir` fixtures stay
(they're still used by the surviving tests' setup, and they're
general-purpose test infrastructure). The `STUB_LOG` plumbing and
`env -i PATH=...` pattern stay.

### 3. Spec collapse (delta already authored, plus the side doc)

The delta at `openspec/changes/omarchy-only-scope/specs/setup-orchestration/spec.md`
is the authoritative spec change. The archive phase (post-merge) merges
the delta into `openspec/specs/setup-orchestration/spec.md`. The merged
main spec loses:

- The `Quick path` row for the env-2 flag
- The `Requirement: --fedora not-implemented behavior` (whole requirement)
- The `Requirement: Fedora single-pass install coalesces sudo` (whole requirement)
- The `--fedora` row from the Flag Contract table
- The `dnf` / `rpm` rows from the auto-detect probe table
- The `--fedora` cross-references in the override scenarios, the
  setup-deps single-pass scenarios, and the input-devices
  cross-tests
- The `Minimum TEST_PLAN=5` line in the "Documentation and test
  coverage" requirement (replaces `TEST_PLAN=8`)

The `Exported variable contract` requirement stays **byte-identical**:
`DOTFILES_ENV` remains accurate because `--omarchy` is still a valid
override. See [Critical design constraints](#critical-design-constraints).

The `openspec/config.yaml` `context:` block is rewritten to a one-env
statement: "Omarchy-family personal dotfiles repo: stock Omarchy,
CachyOS+Omarchy, and Arch+Omarchy share one dotfiles layer. The
Omarchy installer handles distribution-specific config; this repo's
only AUR-helper concern is `yay`." The `rules:` block examples that
cite `omarchy/README.md` and `fedora/README.md` lose the `fedora/`
example.

### CachyOS+Omarchy vs Arch+Omarchy

Explicitly identical. The repo's behavior is one env (`omarchy/`,
`scripts/setup-omarchy`, `OMARCHY_PACKAGES`, `yay` as AUR helper). The
three base distros only differ at the Omarchy bootstrap step
(CachyOS ships its own kernel and pacman config); once the Omarchy
layer is on top, the dotfiles layer cannot tell the three apart. No
per-base divergence is encoded in this repo. This is the lock
declared in `proposal.md` and recorded in the verify-report.

## File-by-file changes

| File | Change | Description | Lines (est.) |
|------|--------|-------------|--------------|
| `fedora/` | `git rm -r` | Hard removal of the env-2 folder. 9 tracked entries: `bin/.gitkeep`, `README.md`, `config/{nvim,zellij,starship.toml}` (symlinks into `shared/`), `home/{.gitconfig,.wezterm.lua,.zshenv,.zshrc}`. | −9 entries |
| `docs/ideas/scripts/setup.md` | `git rm` | Obsolete Spanish-language env-specific design note. NOT in the spec delta — the apply-phase work-units must capture it explicitly. | −38 |
| `README.md` | Modify | Drop the env-2 row from the env table; drop the `./setup --<env-2> --fonts` example; drop the `fedora/README.md` link in "Related docs"; rewrite the line that says env-2 setup is manual so it does not name the removed host family. | −5 / +2 |
| `AGENTS.md` | Modify | Drop the env-2 row from the env table; drop the env-2 reference in the shared-layer line. | −2 / +1 |
| `docs/setup.md` | Modify | Drop the env-2 row from Accepted Flags; drop the "Valid Combinations" line; drop the `dnf`/`rpm` rows from the dep-detection table; drop the env-2 override example. | −8 / +3 |
| `docs/conventions.md` | Modify | Drop the `fedora/README.md` example from the runbook convention. | −1 / +1 |
| `docs/git.md` | Modify | Drop the `fedora/README.md#setup-on-a-new-machine` link in "Related Files". | −1 / +0 |
| `docs/wezterm.md` | Modify | Drop the `fedora/README.md#setup-on-a-new-machine` link in "Related Files". The doc stays because WezTerm is still a tracked config under `home/.wezterm.lua`. | −1 / +0 |
| `docs/ssh.md` | Modify | Drop the env-2 manual-copy instruction (the line that points the env-2 user at a manual recipe). | −2 / +0 |
| `docs/starship.md` | Modify | Drop the env-2 runbook reference; keep the shared-layer explanation. | −1 / +0 |
| `docs/zsh.md` | Modify | Line 3: drop the wording that attributes the zsh plugins to the env-2 package list; the zsh plugins stay as the doc describes. | −0 / +0 (word-level edit) |
| `docs/shared-layer.md` | Modify | Drop the "or any future env added at repo root" parenthetical; drop the "env-2 is out of scope" sentence in the keyd exception paragraph (replace with the explicit Omarchy-only statement). | −3 / +2 |
| `setup` | Modify | Drop the env-2 parser branch (lines 138-142); drop the mutual-exclusion check (lines 175-179); drop the env-2 dispatch short-circuit (lines 234-238); drop the env-2 row from the usage text (lines 86, 102, 121); drop the env-2 from the header comment block (lines 11, 15, 23, 30-32, 44-45, 49); drop the env-2 from the precedence and dispatch comments (lines 29-34, 230). | −25 / +5 |
| `scripts/setup-deps` | Modify | Drop `FEDORA_PACKAGES` (lines 73-79); drop the env-2 branch in `detect_env` (lines 197-205); drop the env-2 branch in `pkg_installed` (lines 262-274); drop the env-2 branch in `install_batch` (lines 348-350, 364-368); drop the env-2 branch in `main` (lines 384-386); drop the env-2 from the usage text (lines 86, 97-106, 119); drop the env-2 from the "Could not detect" error message (line 221). | −50 / +10 |
| `tests/setup-deps.bash` | Modify | Remove `test_fedora_short_circuit_exits_zero` (T3, lines 383-439); remove `test_setup_deps_auto_detects_env` (T7, lines 725-999); remove `test_setup_deps_single_pass_batch_install` (T8, lines 1000-1317); drop `TEST_PLAN` from 8 to 5 (line 75); trim the header comment (lines 26-44); drop the 3 `run_test` lines (1346-1361 minus the 5 survivors). Keep `make_pm_stubs` and `make_minimal_utils_dir` fixtures (general-purpose infrastructure). | −600 / +5 |
| `openspec/config.yaml` | Modify | Rewrite the `context:` block to a one-env statement; drop the `fedora/README.md` example from the `rules:` block. | −3 / +3 |
| `openspec/specs/setup-orchestration/spec.md` | Delta merge (archive phase, post-merge) | The delta at `openspec/changes/omarchy-only-scope/specs/setup-orchestration/spec.md` is the authoritative spec change. Archive phase merges it into this file and removes the delta block. | (Out of PR; see `Risk: spec archive timing` below) |
| `openspec/changes/archive/*` | Untouched | Archive policy wins. Verify-report records what the archived env-2 references are. | 0 |

**Net diff estimate**: ≈ −700 / +30 lines, dominated by the test-file
removals. See [Verification approach](#verification-approach) for the
review-budget note.

## Test plan

Five retained tests, all under `tests/setup-deps.bash`:

| Test | What it covers | Survives as-is? |
|------|----------------|-----------------|
| T1: `test_root_omarchy_invokes_setup_omarchy_once` | `./setup --dry-run --omarchy` invokes `scripts/setup-omarchy` exactly once; root does not dispatch to setup-deps or setup-fonts directly | Yes. No edit. |
| T2: `test_omarchy_with_fonts_or_deps_absorbed` | `--omarchy --fonts` and `--omarchy --deps` are absorbed by root | Yes. No edit. |
| T4: `test_fonts_or_deps_only_direct_dispatch` | `--fonts` runs only `setup-fonts`; `--deps` runs only `setup-deps`; the standalone combo fails validation; the no-PM-fail path propagates | Yes. No edit. Sub-case D (no-PM-fail propagation) keeps the only remaining `Could not detect` assertion, with the narrowed message. |
| T5: `test_env_script_preflight_handles_fonts_dir` | `setup-omarchy` pre-flight honors `DOTFILES_FONTS_DIR`; missing-fonts dry-run warns and continues | Yes. No edit. |
| T6: `test_dotfiles_vars_unset_after_run` | All five `DOTFILES_*` vars are unset on every exit path; the trap line in `setup` lists all five | Yes. No edit. |

Three removed tests, with the lost automated coverage:

| Test | Removed | What the spec still says (lost automated harness) |
|------|---------|---------------------------------------------------|
| T3: `test_fedora_short_circuit_exits_zero` | Entirely | The unknown-flag scenario in `Requirement: Flag contract and precedence` is exercised by the existing T1 / T2 / T4 sub-cases. The `--<env-2>` flag falls through to the `*)` parser arm (exit 2 + usage). |
| T7: `test_setup_deps_auto_detects_env` | Entirely | Lost: yay→omarchy probe, pacman-no-yay warning, no-PM-fail, `--omarchy` override skips detection. The spec scenarios for these (`Requirement: setup-deps auto-detection` + `Requirement: setup-deps explicit override`) remain; only the bash TAP harness is gone. |
| T8: `test_setup_deps_single_pass_batch_install` | Entirely | Lost: all-present skip, 1-missing-Omarchy, ≥2-missing-Omarchy, install-failure. The spec scenarios for these (`Requirement: setup-deps single-pass batch install` + `Requirement: Input-devices packages`) remain. |

The verify-report of this change MUST list these lost scenarios so a
future change can re-add TAP coverage if regressions appear. See
[Critical design constraints](#critical-design-constraints).

## Work-unit commit structure

Three work-unit commits in a single PR, per the `work-unit-commits`
skill (commit by deliverable, tests with the behavior, docs with the
user-visible change).

### Commit 1: `chore(repo): drop the second host family from the dotfiles repo`

**What**: structural deletions and surface-description edits. No
behavior change in `./setup` or `scripts/setup-deps` yet.

- `git rm -r fedora/`
- `git rm docs/ideas/scripts/setup.md`
- `README.md`: rewrite the env table to one row; drop the env-2
  setup example; drop the env-2 doc link in "Related docs"
- `AGENTS.md`: rewrite the env table; drop the env-2 reference in the
  shared-layer line
- `docs/conventions.md`, `docs/git.md`, `docs/wezterm.md`,
  `docs/ssh.md`, `docs/starship.md`, `docs/zsh.md`,
  `docs/shared-layer.md`: scrub env-2 references
- `openspec/config.yaml`: rewrite the `context:` block to a one-env
  statement; drop the env-2 example from the `rules:` block

**Why one commit**: the structural deletions and the surface-description
edits share the same intent ("this repo is one host family") and have
no functional dependencies between them.

**Rollback**: revert one commit; the surface descriptions and the
folder state both return.

**Verification**: `git ls-tree HEAD fedora/ docs/ideas/scripts/setup.md`
returns empty. `grep -rn "fedora\|Fedora" -- ':!openspec/changes/archive'`
returns zero hits in tracked code/config/docs.

### Commit 2: `feat(setup): collapse dispatcher to a single host family`

**What**: dispatcher surface narrows to one env.

- `setup`: drop the env-2 parser branch; drop the mutual-exclusion
  check; drop the env-2 dispatch short-circuit; drop the env-2 row
  from the usage text and the header comment block
- `docs/setup.md`: drop the env-2 row from Accepted Flags; drop the
  "Valid Combinations" line; drop the env-2 row from the
  dep-detection table; drop the env-2 override example
- `tests/setup-deps.bash`: remove `test_fedora_short_circuit_exits_zero`
  (T3); trim the header comment to a 5-test plan; drop the T3
  `run_test` line

**Why one commit**: T3 is purely a dispatcher contract test, and the
dispatcher + its doc live together.

**Rollback**: revert one commit; the dispatcher restores its env-2
short-circuit and T3 returns.

**Verification**: `bash tests/setup-deps.bash` reports `4/4 passed`
at this point (T1, T2, T4, T5, T6 minus T6 = 4 if T6 is excluded; the
exact count depends on whether the change orders T6 alongside the
dispatcher or the deps cleanup — the apply phase decides). `./setup
--<env-2>` exits 2 with the "Unknown argument" + usage message.
`./setup --help` lists only the Omarchy-family flags.

### Commit 3: `feat(setup-deps): collapse auto-detect and install to a single host family`

**What**: `scripts/setup-deps` loses every env-conditional branch and
its env-2 package list.

- `scripts/setup-deps`: drop `FEDORA_PACKAGES`; drop the env-2
  branch in `detect_env`, `pkg_installed`, `install_batch`, `main`;
  drop the env-2 from the usage text and the "Could not detect"
  error message
- `tests/setup-deps.bash`: remove `test_setup_deps_auto_detects_env`
  (T7); remove `test_setup_deps_single_pass_batch_install` (T8);
  drop `TEST_PLAN` from 8 to 5; drop the T7 + T8 `run_test` lines

**Why one commit**: T7 and T8 are `setup-deps` contract tests; the
dep-script collapse and its tests live together.

**Rollback**: revert one commit; `FEDORA_PACKAGES` returns and the
auto-detect regains its `dnf` / `rpm` rows.

**Verification**: `bash tests/setup-deps.bash` reports `5/5 passed`.
`scripts/setup-deps --<env-2>` exits 2. `scripts/setup-deps --help`
lists only `--omarchy`, `--dry-run`, `--help`. `scripts/setup-deps
--omarchy --dry-run` on a host with `yay` on PATH emits exactly one
`yay -S --needed` line with all 9 packages.

### Spec archive (out of PR)

The delta at `openspec/changes/omarchy-only-scope/specs/setup-orchestration/spec.md`
merges into `openspec/specs/setup-orchestration/spec.md` at archive
time (per the `archive:` rule in `openspec/config.yaml`). This is
post-merge work, not part of the apply-phase PR. The verify-report
of this change references the delta and notes that the spec is
applied at archive time.

## Verification approach

| Layer | What | How | Expected |
|-------|------|-----|----------|
| Bash TAP | `bash tests/setup-deps.bash` | All 5 tests pass | `5/5 passed` |
| Dispatcher help | `./setup --help` | The output lists the 5 surviving flags and the Omarchy dispatcher table | No env-2 row; no env-2 "not implemented" line |
| Dispatcher unknown flag | `./setup --<env-2>` | Existing unknown-flag branch | Exit 2, "Unknown argument: --<env-2>" + usage on stderr |
| Deps help | `scripts/setup-deps --help` | The output lists `--omarchy`, `--dry-run`, `--help` | No env-2 row in the auto-detection or packages section |
| Deps unknown flag | `scripts/setup-deps --<env-2>` | Existing unknown-flag branch | Exit 2, "Unknown argument" + usage on stderr |
| Deps omarchy dry-run | `scripts/setup-deps --omarchy --dry-run` on a host with `yay` on PATH | Single-pass batch install | Exactly ONE `yay -S --needed` line with all 9 packages |
| Deps narrow no-PM | `scripts/setup-deps --dry-run` on a stripped PATH | Probe fails | Exit non-zero, "Could not detect a supported package manager (yay, pacman). Install one and re-run." |
| Tracked-surface scan | `rg -l "fedora\|Fedora" --type-add 'f:*.{sh,md,yaml,yml,toml,json,bash,kdl,lua,gitignore}' -t f 2>/dev/null` | Search the working tree | Zero hits outside `openspec/changes/archive/` (the archive rule preserves those references) |
| Archive intact | `git status` after the apply phase | No edit to archive folders | `openspec/changes/archive/*` byte-identical to before |
| `DOTFILES_*` contract | Read `Requirement: Exported variable contract` in the main spec | Spec merge preserves the table | `DOTFILES_ENV` row still says `omarchy`, set by root, unset when no env selected |

The TAP harness is run as `bash tests/setup-deps.bash` (the only
command in the `verify.test_command` of `openspec/config.yaml`).

## Critical design constraints

These four constraints were called out by the spec phase and must be
preserved by the apply phase. Each is a place where a naive
"follow the spec mechanically" apply would silently regress.

### 1. `docs/ideas/scripts/setup.md` is NOT in the spec delta

The spec phase authored a delta that captures all env-2 requirements
and code paths but does NOT mention `docs/ideas/scripts/setup.md`.
If the apply phase copies the spec mechanically (touch every
file the spec mentions), this file is left behind — a stale
env-specific design note from before the scope lock. The apply
phase MUST capture `git rm docs/ideas/scripts/setup.md` in
Commit 1 explicitly. This design records the requirement so the
apply phase cannot drop it.

### 2. T7 and T8 are removed entirely — record the lost coverage

Per user decision #4, T3, T7, and T8 are removed entirely (the
proposal's wording is slightly different — "drop T7-B and T8-D" —
but the spec removes both top-level tests, and the spec is
authoritative). The Omarchy behaviors they exercised lose their
bash-TAP harness:

- **T7 (auto-detect)**: `yay`→omarchy probe, `pacman`-no-`yay`
  warning, no-PM-fail, `--omarchy` override skips detection
- **T8 (single-pass batch install)**: all-present skip,
  1-missing-Omarchy, ≥2-missing-Omarchy, install-failure-aborts

The spec scenarios for these behaviors remain in the merged main
spec (in `Requirement: setup-deps auto-detection`,
`Requirement: setup-deps explicit override`, and
`Requirement: setup-deps single-pass batch install`). The
verify-report of this change MUST add a section that lists each
lost scenario with a one-line "lost TAP coverage" note, so a
future change can re-add TAP tests for the ones that matter.

### 3. Archived changes still mention the env-2 surface

The four archived change folders under `openspec/changes/archive/`
mention the env-2 surface (e.g., the `--<env-2>` short-circuit
contract, the env-2 package list, the `sudo dnf install -y` install
command, the env-2 row in the auto-detect probe). They are
byte-identical to before this change, per the archive policy. The
verify-report of this change MUST add a one-paragraph note at the
top of the relevant findings section explaining what those archived
references are, that they predate the scope cut, and that they are
preserved on purpose. The note is for future readers (including a
future agent) who would otherwise misread the current contract from
the archive history.

### 4. `DOTFILES_ENV` row in the Exported variable contract stays untouched

The main spec's `Requirement: Exported variable contract` table
defines `DOTFILES_ENV` as `omarchy`, set by root, unset when no env
selected, consumed by env scripts and `setup-deps` (optional
override). This row remains accurate after the cut because
`--omarchy` is still a valid explicit override for `scripts/setup-deps`,
and the variable is still set on `--omarchy` dispatch. The apply
phase MUST NOT touch this row. The spec delta does not list this
table; the archive phase preserves it byte-identical. The verify
layer confirms by reading the merged main spec and asserting the
row text matches the pre-change row text.

## Risks and mitigations

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|------------|--------|------------|
| R1 | Test diff exceeds the 400-line review budget. The test file alone loses ≈ 600 lines (T3 + T7 + T8 + header + runner lines), plus doc / code / config diffs. | High | Medium | User explicitly authorized one PR for this change ("the change is small (mostly deletions + spec edits)"). The diff is dominated by deletions, which are easier to review than equivalent additions. The 3 work-unit commits split the review load. If the apply phase shows the diff is much larger than 700 lines, escalate to the user with a chained-PR proposal (Commit 1 alone, then Commits 2+3, then the spec archive). |
| R2 | Loss of automated coverage for Omarchy behaviors (T7, T8 sub-cases). Regressions in `setup-deps` auto-detect or single-pass batch install would not be caught by `bash tests/setup-deps.bash`. | Medium | Medium | The verify-report records every lost scenario with a one-line note. The spec scenarios themselves remain in the merged main spec. A future change can re-add TAP tests for the regressions that matter. The apply phase cannot prevent this loss; the design records it. |
| R3 | `docs/ideas/scripts/setup.md` left behind because the spec delta doesn't mention it. | Medium | Low | Commit 1 explicitly includes `git rm docs/ideas/scripts/setup.md`. The design records the requirement so the apply phase cannot drop it. The verify layer greps for the env-2 name and confirms the file is gone. |
| R4 | Archived changes still mention the env-2 surface; future readers misread the current contract. | Low | Low | Verify-report of this change adds a one-paragraph note explaining what the archived references are and that they predate the scope cut. No retroactive edits to archived folders (archive policy). |
| R5 | The removed CLI flag is in a user's muscle memory or a stale script. The flag is rejected by the unknown-flag branch, but the error message ("Unknown argument") is generic. | Low | Low | The error message prints the flag name + usage, which is loud enough to be caught. No additional error message is added; the existing unknown-flag contract is the rejection path. |
| R6 | Stale "active unrelated change: `openspec/changes/cleanup-omarchy/`" reference in the project context. The change folder does not exist on disk; only `scripts/cleanup-omarchy` exists. The apply phase must NOT create the change folder just to "match" the project context note. | Low | None | Verified during design: `ls openspec/changes/` shows only `archive/` and `omarchy-only-scope/`. The apply phase operates on real files only. The verify layer does not need to do anything special. |
| R7 | Spec archive timing. The delta lives in `openspec/changes/omarchy-only-scope/specs/setup-orchestration/spec.md` and merges into the main spec post-merge. If the apply phase ships a PR that references the delta in the spec-archive note, but the merge happens before the archive, the spec delta is in two places at once. | Low | Low | The apply phase ships the change with the delta in the change folder. The spec archive (sdd-archive phase) runs after the PR is merged. This is the documented SDD flow and matches the archive rule in `openspec/config.yaml`. The verify-report records the post-merge archive step. |

## Out of scope

- **`scripts/setup-fedora`**: does not exist and will not be created.
  The removed CLI flag is a deliberate unknown-flag case; the flag is
  not a "future env" target.
- **CachyOS or Arch kernel / pacman config**: the Omarchy installer
  owns it. This repo does not touch distribution defaults.
- **Restore / archive path for the env-2 surface**: the rollback
  plan in `proposal.md` is `git revert` of the change, not a
  per-file restore.
- **Auto profile switching per app** (keyd layers): orthogonal; the
  previous change (`input-devices-config`) scoped it out.
- **Piper profile version control**: impossible (firmware-only);
  the previous change documented this.
- **Re-adding TAP tests for the T7 / T8 Omarchy behaviors**: a
  future change can pick this up. The verify-report of this change
  records the lost scenarios.
- **Tweaking the unknown-flag error message**: the existing
  "Unknown argument: $1" + usage contract is the rejection path;
  no special-case message for the removed env-2 flag.
- **Editing `scripts/cleanup-omarchy`, `scripts/setup-omarchy`,
  `scripts/setup-fonts`, or the `omarchy/` folder**: none of
  these carry env-2 surface; they stay byte-identical.
- **Editing `openspec/specs/omarchy-preinstall-cleanup/spec.md`**:
  that capability is clean of env-2 surface (verified during
  explore).

## See also

- `openspec/changes/omarchy-only-scope/proposal.md` — the
  approved proposal.
- `openspec/changes/omarchy-only-scope/specs/setup-orchestration/spec.md` —
  the delta spec.
- `openspec/changes/omarchy-only-scope/explore.md` — the
  exploration surface map.
- `openspec/changes/archive/2026-06-17-input-devices-config/design.md` —
  the most recent Omarchy-only design (precedent for the
  "no env-2 surface" statement in the work-unit commits).
