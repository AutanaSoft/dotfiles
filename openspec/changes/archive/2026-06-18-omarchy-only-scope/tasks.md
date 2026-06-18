# Tasks: omarchy-only-scope

> Implementation tasks for the `omarchy-only-scope` change. This document
> is the apply-phase checklist; the design encodes the work-unit commit
> structure (see `design.md`).

## Outcome

Collapse the dotfiles repo to Omarchy-family hosts only (stock Omarchy,
CachyOS + Omarchy, Arch + Omarchy). All three variants are treated
identically — the Omarchy installer handles distribution-specific
configuration; this repo's only AUR-helper concern is `yay`. The
secondary host family layer is hard-removed: folder deleted, CLI flag
becomes an unknown flag, install branches collapse, the spec drops the
secondary-env requirements.

## Work-unit commit structure

| Commit | Scope | Work unit |
| --- | --- | --- |
| 0 | Planning artifacts | `proposal.md`, `specs/.../spec.md`, `design.md`, `tasks.md` |
| 1 | Structural deletions | Drop the secondary env folder + the obsolete design note + the secondary-env rows from every doc and from `openspec/config.yaml`. No behavior change in code yet. |
| 2 | Dispatcher collapse | Narrow the root dispatcher: removed CLI flag now falls through to the existing unknown-flag branch. Drop T3 from the test plan. |
| 3 | Deps collapse | Narrow `scripts/setup-deps`: drop the secondary package list and every secondary branch in `detect_env` / `pkg_installed` / `install_batch` / `main`. Drop T7 + T8 from the test plan. |
| (archive) | Spec merge | Merge the spec delta into the main spec; archive the change folder. Post-merge, not part of the PR. |

The proposal and design approve a single PR with these three work-unit
commits. The `sdd-tasks` Review Workload Forecast flags the diff as
`High` 400-line-budget risk; the apply phase confirms the PR strategy
with the user before opening the PR (see "Pre-flight" below).

## Pre-flight (before any commit)

- [ ] Confirm with the user which PR strategy applies: single PR with
      `size:exception` (per the design's stated direction), or chained
      PRs (per the forecast's recommendation). Do not commit or push
      until the user picks.
- [ ] Read `design.md` "Critical design constraints" section in full
      (four numbered constraints). Each is a place where a naive
      mechanical apply would silently regress the contract.
- [ ] Verify the working tree is clean: `git status` shows nothing
      pending. The apply phase starts from a clean state.

## Commit 0 — Planning artifacts

These four files already live in `openspec/changes/omarchy-only-scope/`
and are committed in the first commit so the change folder is
self-contained on disk before any work-unit commit lands.

- [ ] `git add openspec/changes/omarchy-only-scope/proposal.md`
      (110 lines, the approved proposal).
- [ ] `git add openspec/changes/omarchy-only-scope/specs/setup-orchestration/spec.md`
      (301 lines, the delta spec).
- [ ] `git add openspec/changes/omarchy-only-scope/design.md`
      (439 lines, the technical design).
- [ ] `git add openspec/changes/omarchy-only-scope/tasks.md`
      (this file).
- [ ] Commit message: `docs(sdd): add omarchy-only-scope change artifacts`.

**Verification**: `git ls-tree HEAD openspec/changes/omarchy-only-scope/`
returns the four files plus the `specs/` directory.

## Commit 1 — Structural deletions

> "Drop the secondary host family from the dotfiles repo."
>
> Scope: surface descriptions and the secondary env folder. No code
> behavior change yet. The dispatcher and `scripts/setup-deps` still
> carry the secondary-env branches; commits 2 and 3 remove them.

- [ ] `git rm -r fedora/` — hard removal of the secondary env folder
      (9 tracked entries: `bin/.gitkeep`, `config/nvim`, `config/zellij`,
      `config/starship.toml`, `home/.gitconfig`, `home/.wezterm.lua`,
      `home/.zshenv`, `home/.zshrc`, `README.md`). No local trace.
- [ ] `git rm docs/ideas/scripts/setup.md` — obsolete Spanish-language
      design note predating the scope lock. **Critical**: the spec
      delta does NOT mention this file; the apply phase must remember
      to include it here (design constraint #1).
- [ ] `README.md` (60 lines): rewrite the env table to one row; drop
      the secondary-env setup example; drop the secondary-env doc link
      in "Related docs"; rewrite the line about manual setup so it
      does not name the removed host family.
- [ ] `AGENTS.md` (73 lines): rewrite the env table to one row; drop
      the secondary-env reference in the shared-layer line.
- [ ] `docs/conventions.md` (99 lines): drop the secondary-env
      `README.md` example from the runbook convention.
- [ ] `docs/git.md` (36 lines): drop the secondary-env
      `README.md#setup-on-a-new-machine` link in "Related Files".
- [ ] `docs/wezterm.md` (36 lines): drop the secondary-env
      `README.md#setup-on-a-new-machine` link in "Related Files". The
      doc stays because WezTerm is still a tracked config under
      `home/.wezterm.lua`.
- [ ] `docs/ssh.md` (24 lines): drop the secondary-env manual-copy
      instruction.
- [ ] `docs/starship.md` (42 lines): drop the secondary-env runbook
      reference; keep the shared-layer explanation.
- [ ] `docs/zsh.md` (54 lines): line-level edit — drop the wording
      that attributes the zsh plugins to the secondary-env package
      list.
- [ ] `docs/shared-layer.md` (83 lines): drop the "or any future env
      added at repo root" parenthetical; drop the secondary-env
      out-of-scope sentence in the keyd exception paragraph; replace
      with the explicit Omarchy-only statement.
- [ ] `openspec/config.yaml` (101 lines): rewrite the `context:` block
      to a one-env statement (Omarchy-family only); drop the
      secondary-env `README.md` example from the `rules:` block.
- [ ] Confirm `docs/ideas/scripts/setup.md` is gone
      (`git ls-tree HEAD docs/ideas/scripts/setup.md` returns empty).
- [ ] Confirm `fedora/` is gone
      (`git ls-tree HEAD fedora/` returns empty).

**Verification**:
- [ ] `git ls-tree HEAD fedora/ docs/ideas/scripts/setup.md` returns
      empty.
- [ ] `git grep -nE 'fedora|Fedora|FEDORA' -- ':!openspec/changes/archive'`
      returns zero hits in tracked code/config/docs outside the archive
      (per the design's grep guard).
- [ ] The dispatcher and `scripts/setup-deps` are byte-identical to
      before this commit (no behavior change in code yet).

**Rollback**: revert one commit. Folder state and surface descriptions
both return.

**Commit message**: `chore(repo): drop the secondary host family from the dotfiles repo`

## Commit 2 — Dispatcher collapse

> "Collapse the root dispatcher to a single host family."
>
> Scope: the root `./setup` script. The removed CLI flag is now an
> unknown flag (rejected by the existing `*)` arm of the parser at
> exit 2 with usage on stderr). The mutual-exclusion check is dropped
> (no second env flag to exclude). T3 (the short-circuit contract
> test) is removed.

- [ ] `setup` (root, 280 lines):
  - [ ] Drop the secondary-env parser branch (current lines 138-142).
  - [ ] Drop the mutual-exclusion check (current lines 175-179).
  - [ ] Drop the secondary-env dispatch short-circuit (current lines
        234-238).
  - [ ] Drop the secondary-env row from the usage text (current lines
        86, 102, 121).
  - [ ] Drop the secondary-env mentions from the header comment block
        (current lines 11, 15, 23, 30-32, 44-45, 49) and from the
        precedence / dispatch comments (current lines 29-34, 230).
  - [ ] Drop the secondary-env error message line in validation
        (current line 184, "choose --omarchy, --<env-2>, --fonts,
        --deps, or any combination").
  - [ ] Update the validation block at lines 181-195 so the
        "choose only one standalone helper" check is the only
        remaining validation rule.
- [ ] `docs/setup.md` (69 lines):
  - [ ] Drop the secondary-env row from the Accepted Flags table.
  - [ ] Drop the "Valid Combinations" line for the secondary env.
  - [ ] Drop the secondary-env row from the dep-detection table.
  - [ ] Drop the secondary-env override example.
- [ ] `tests/setup-deps.bash` (1367 lines):
  - [ ] Remove `test_fedora_short_circuit_exits_zero` (T3, lines
        383-439, 57 lines including header comment and closing
        brace).
  - [ ] Drop the T3 `run_test` call (current lines 1350-1351).
  - [ ] Update `TEST_PLAN` from 8 to 7 (line 75).
  - [ ] Trim the header comment block (lines 25-46) to reflect the
        7-test state: remove T3 mention, leave T7 + T8 mentions
        for the next commit.
  - [ ] Update the post-PR-3 comment at lines 67-74: remove the
        "PR-3 covers T1..T7" line (T7 is now removed in commit 3)
        and adjust the surrounding text.
- [ ] `bash tests/setup-deps.bash` exits 0 and reports `7/7 passed`
      (T1, T2, T4, T5, T6, T7, T8).

**Verification**:
- [ ] `bash tests/setup-deps.bash` reports `7/7 passed`.
- [ ] `./setup --help` lists only the surviving flags (no
      secondary-env row).
- [ ] `./setup --<env-2>` exits 2 with the "Unknown argument"
      + usage message on stderr.
- [ ] `./setup --omarchy`, `./setup --omarchy --fonts`,
      `./setup --omarchy --deps`, `./setup --fonts`, `./setup
      --deps` all behave as before.
- [ ] The `DOTFILES_*` exported-variable contract is preserved
      (the main spec's `Requirement: Exported variable contract`
      stays byte-identical; see design constraint #4).
- [ ] `scripts/setup-deps` is byte-identical to before this commit
      (no behavior change in deps yet).

**Rollback**: revert one commit. Dispatcher restores its
secondary-env short-circuit and T3 returns.

**Commit message**: `feat(setup): collapse dispatcher to a single host family`

## Commit 3 — Deps collapse

> "Collapse `scripts/setup-deps` to a single host family."
>
> Scope: `scripts/setup-deps` loses every secondary-env branch and
> the secondary-env package list. Auto-detection narrows to two
> Omarchy outcomes: `yay` → Omarchy; `pacman` → Omarchy with a
> `yay` warning; else fail. T7 (auto-detect with secondary-env
> sub-cases) and T8 (single-pass batch install per env, with
> secondary-env sub-cases) are removed entirely. `TEST_PLAN`
> drops from 7 to 5.

- [ ] `scripts/setup-deps` (428 lines):
  - [ ] Drop the `FEDORA_PACKAGES` array (current lines 73-79, 7
        lines).
  - [ ] Drop the secondary-env header comment block (current lines
        24-27, 4 lines).
  - [ ] Drop the secondary-env branch in `detect_env` (current
        lines 197-205, 9 lines: `dnf` → env, `rpm` → env+warn).
  - [ ] Drop the secondary-env branch in `pkg_installed` (current
        lines 262-274, 13 lines: `rpm -q` / `dnf list installed`).
  - [ ] Drop the secondary-env branch in `install_batch` (current
        lines 348-350, 364-368, 10 lines total: `sudo dnf
        install -y` plus the `dnf`-on-PATH pre-check).
  - [ ] Drop the secondary-env branch in `main` (current lines
        384-386, 3 lines: `packages=("${FEDORA_PACKAGES[@]}")`).
  - [ ] Drop the secondary-env row from the usage text (current
        lines 86, 97-106, 119, 8 lines: precedence list, env
        override line, packages list).
  - [ ] Drop the secondary-env from the "Could not detect" error
        message (current line 221: collapse to "yay, pacman").
  - [ ] Drop the secondary-env flag from the argument parser
        (current lines 132-135, 4 lines).
- [ ] `tests/setup-deps.bash` (now ~1310 lines after commit 2):
  - [ ] Remove `test_setup_deps_auto_detects_env` (T7, lines
        725-999, 275 lines including header comment and closing
        brace).
  - [ ] Remove `test_setup_deps_single_pass_batch_install` (T8,
        lines 1001-1317, 317 lines including header comment and
        closing brace).
  - [ ] Drop the T7 + T8 `run_test` calls (current lines
        1358-1361, 4 lines).
  - [ ] Update `TEST_PLAN` from 7 to 5 (line 75).
  - [ ] Trim the header comment block to a 5-test plan: drop
        the T7 + T8 mentions, keep T1, T2, T4, T5, T6.
  - [ ] Drop the `make_minimal_utils_dir` fixture call comments
        that referenced T7 / T8 fixture usage.
  - [ ] Keep `make_pm_stubs` and `make_minimal_utils_dir` fixture
        definitions (general-purpose infrastructure; still used
        by T4 sub-case D's no-PM-fail propagation path).

**Verification**:
- [ ] `bash tests/setup-deps.bash` reports `5/5 passed`.
- [ ] `scripts/setup-deps --help` lists only `--omarchy`,
      `--dry-run`, `--help`. No secondary-env row in the
      auto-detection or packages section.
- [ ] `scripts/setup-deps --<env-2>` exits 2 with "Unknown
      argument" + usage on stderr (the existing unknown-flag
      branch covers rejection).
- [ ] `scripts/setup-deps --omarchy --dry-run` on a host with
      `yay` on `PATH` emits exactly ONE `yay -S --needed` line
      with all 9 packages in `OMARCHY_PACKAGES`.
- [ ] `scripts/setup-deps --dry-run` on a stripped PATH (no
      `yay`, no `pacman`) exits non-zero with "Could not
      detect a supported package manager (yay, pacman). Install
      one and re-run."

**Rollback**: revert one commit. `FEDORA_PACKAGES` returns and
the auto-detect regains its `dnf` / `rpm` rows; T7 and T8
return.

**Commit message**: `feat(setup-deps): collapse auto-detect and install to a single host family`

## Verify phase (post-commits, pre-PR)

> Run after all three work-unit commits land but before opening
> the PR. Records the verify-report content.

- [ ] **TAP harness**: `bash tests/setup-deps.bash` exits 0 and
      reports `5/5 passed`. Confirm the TAP header says `1..5`
      and every `ok N - <name>` line is present.
- [ ] **Dispatcher help**: `./setup --help` output contains the
      surviving flags (`--omarchy`, `--fonts`, `--deps`,
      `--dry-run`, `--help` / `-h`) and the Omarchy dispatcher
      table. No secondary-env row. No "not implemented" line.
- [ ] **Dispatcher unknown flag**: `./setup --<env-2>` exits 2
      with "Unknown argument: --<env-2>" + usage on stderr.
- [ ] **Deps help**: `scripts/setup-deps --help` lists
      `--omarchy`, `--dry-run`, `--help` only.
- [ ] **Deps unknown flag**: `scripts/setup-deps --<env-2>`
      exits 2 with "Unknown argument" + usage on stderr.
- [ ] **Deps omarchy dry-run**: `scripts/setup-deps --omarchy
      --dry-run` on a host with `yay` on `PATH` emits exactly
      one `yay -S --needed` line with all 9 packages
      (`lsof`, `hunspell`, `hunspell-en_us`, `hunspell-es_any`,
      `zellij`, `trash-cli`, `keyd`, `piper`, `libratbag`).
- [ ] **Deps narrow no-PM**: `scripts/setup-deps --dry-run` on
      a stripped `PATH` (no `yay`, no `pacman`) exits non-zero
      with "Could not detect a supported package manager
      (yay, pacman). Install one and re-run."
- [ ] **Tracked-surface scan**:
      `git grep -nE 'fedora|Fedora|FEDORA|fdn|dnf|rpm' -- ':!openspec/changes/archive'`
      returns zero hits in tracked code, config, or docs. The
      archive exception is the only place the secondary env
      name still appears.
- [ ] **Archive intact**: `git status` shows no edit to
      `openspec/changes/archive/*`. The four archived change
      folders are byte-identical to before this change.
- [ ] **`DOTFILES_*` contract preserved**: the main spec's
      `Requirement: Exported variable contract` table row for
      `DOTFILES_ENV` is byte-identical to before (design
      constraint #4). The `DOTFILES_ENV` row still says
      `omarchy`, set by root, unset when no env selected.
- [ ] **Work-unit commit log**: `git log --oneline -5` shows
      the four commits in order (commit 0 planning artifacts,
      commit 1 structural, commit 2 dispatcher, commit 3
      deps). The Conventional Commit prefixes match the
      design.

### Verify-report content (the `sdd-verify` output)

- [ ] **Lost TAP coverage** (recorded so a future change can
      re-add tests if regressions appear):
  - [ ] T3 `test_fedora_short_circuit_exits_zero` — removed
        entirely. The "unknown flag fails" scenario in
        `Requirement: Flag contract and precedence` is still
        exercised by T1 / T2 sub-cases.
  - [ ] T7 `test_setup_deps_auto_detects_env` — removed
        entirely. Lost scenarios: `yay` → Omarchy probe,
        `pacman` no-`yay` warning, no-PM-fail, `--omarchy`
        override skips detection. Spec scenarios remain in
        `Requirement: setup-deps auto-detection` and
        `Requirement: setup-deps explicit override`.
  - [ ] T8 `test_setup_deps_single_pass_batch_install` —
        removed entirely. Lost scenarios: all-present skip,
        1-missing-Omarchy, ≥2-missing-Omarchy,
        install-failure-aborts. Spec scenarios remain in
        `Requirement: setup-deps single-pass batch install`
        and `Requirement: Input-devices packages`.
- [ ] **Archived-changes note**: a one-paragraph note at the
      top of the verify-report's findings section explaining
      that `openspec/changes/archive/*` still mentions the
      secondary env, that those references predate the
      2026-06-17 scope lock, and that they are preserved
      on purpose per the SDD archive policy. The note is
      for future readers (and future agents) who would
      otherwise misread the current contract from the
      archive history. (Design constraint #3.)
- [ ] **No `docs/ideas/scripts/setup.md` left behind**:
      confirm the file is gone (design constraint #1).

## Archive task (post-merge, NOT part of the PR)

Per the `archive:` rule in `openspec/config.yaml`, the spec
delta is merged into the main spec and the change folder is
archived. This happens AFTER the PR is merged; it is the
`sdd-archive` phase, not the `sdd-apply` phase.

- [ ] `sdd-archive` merges the delta at
      `openspec/changes/omarchy-only-scope/specs/setup-orchestration/spec.md`
      into `openspec/specs/setup-orchestration/spec.md` and
      removes the delta block from the change folder. The
      merge removes:
  - [ ] The secondary-env row from the Quick path table.
  - [ ] The `Requirement: --fedora not-implemented behavior`
        requirement (whole requirement).
  - [ ] The `Requirement: Fedora single-pass install
        coalesces sudo` requirement (whole requirement).
  - [ ] The `--fedora` row from the Flag Contract table.
  - [ ] The `dnf` / `rpm` rows from the auto-detect probe
        table.
  - [ ] The secondary-env cross-references in the override
        scenarios, the setup-deps single-pass scenarios, and
        the input-devices cross-tests.
  - [ ] The `Minimum TEST_PLAN=8` line in `Requirement:
        Documentation and test coverage` (replaces with
        `TEST_PLAN=5`).
- [ ] The `Requirement: Exported variable contract` table
      stays **byte-identical** (design constraint #4). The
      `DOTFILES_ENV` row still says `omarchy`.
- [ ] `git mv openspec/changes/omarchy-only-scope
      openspec/changes/archive/2026-06-17-omarchy-only-scope`.
- [ ] The four pre-existing archived change folders
      (`2026-06-14-ideas-implementation`,
      `2026-06-16-cleanup-omarchy`,
      `2026-06-17-input-devices-config`,
      `2026-06-17-setup-deps-batch-install`) remain
      byte-identical to before this change. No retroactive
      edits to historical artifacts.

## Out of scope (do not implement in this change)

- `scripts/setup-fedora` — does not exist and will not be
  created. The removed CLI flag is a deliberate unknown-flag
  case.
- CachyOS or Arch kernel / pacman config — the Omarchy
  installer owns it. This repo does not touch distribution
  defaults.
- Restore / archive path for the secondary-env surface — the
  rollback plan in `proposal.md` is `git revert` of the
  change, not a per-file restore.
- Auto profile switching per app (keyd layers) — orthogonal;
  scoped out by the previous `input-devices-config` change.
- Piper profile version control — impossible (firmware-only);
  documented by the previous change.
- Re-adding TAP tests for the T7 / T8 Omarchy behaviors — a
  future change can pick this up. The verify-report records
  the lost scenarios.
- Tweaking the unknown-flag error message — the existing
  "Unknown argument: $1" + usage contract is the rejection
  path; no special-case message for the removed flag.
- Editing `scripts/cleanup-omarchy`, `scripts/setup-omarchy`,
  `scripts/setup-fonts`, or the `omarchy/` folder — none
  carry secondary-env surface; they stay byte-identical.
- Editing `openspec/specs/omarchy-preinstall-cleanup/spec.md`
  — that capability is clean of secondary-env surface
  (verified during explore).
- Editing the unrelated `openspec/changes/cleanup-omarchy/`
  change — the project context note about it is stale; the
  folder does not exist on disk and must NOT be created.
