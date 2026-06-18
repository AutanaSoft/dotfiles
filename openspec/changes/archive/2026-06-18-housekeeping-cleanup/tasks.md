# Tasks: housekeeping-cleanup

> Implementation checklist for the `housekeeping-cleanup` change. This
> file is the apply-phase source of truth. The proposal encodes W3
> (`.gitignore` SSH rules point at `shared/home/.ssh/` which no longer
> exists) and W4 (Fedora/Windows-era `docs/git.md` + `docs/wezterm.md`
> document files that are gone after the reorg). W2 stays deferred.

## Outcome

Re-anchor the repo at its post-reorg reality:

- `.gitignore` rules actually protect `src/home/.ssh/` again (the
  `shared/home/.ssh/*` rules have been inert since PR #7 merged).
- `docs/git.md` and `docs/wezterm.md` are gone — both reference
  `home/.gitconfig`, `home/.wezterm.lua`, and `omarchy/README.md`,
  none of which exist in the tracked tree.

No runtime behavior changes. No code paths touched.

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~320 (planning + config + doc deletes) |
| Net changed lines | ~+180 (planning artifacts add; deleted docs are shorter) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | single-pr |
| Chain strategy | N/A |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: N/A
400-line budget risk: Low

The config + doc surface is well under 80 changed lines; the rest is
SDD planning artifacts (`proposal.md` + `tasks.md`). Comfortable margin
under the 400-line budget; no chained-PR overhead needed.

## Work-unit commit structure

| Commit | Scope | Work unit |
| --- | --- | --- |
| 0.1 | Proposal | `openspec/changes/housekeeping-cleanup/proposal.md` |
| 0.2 | Tasks | `openspec/changes/housekeeping-cleanup/tasks.md` |
| 1 | Gitignore fix | Point SSH rules at `src/home/.ssh/` and update the comment to match. |
| 2 | Doc deletions | `git rm docs/git.md docs/wezterm.md` in one commit. |
| (archive) | Spec sync | Post-merge, no main spec delta. Archive the change folder. |

## Pre-flight (before commit 0.1)

- [ ] Working tree is clean except for the new
      `openspec/changes/housekeeping-cleanup/` folder:
      `git status` shows only that untracked path.
- [ ] Read `proposal.md` lines 27-33 ("Qué cambia" table) — those three
      rows are the only surface this change touches.
- [ ] Confirm `docs/git.md` and `docs/wezterm.md` still mention
      `omarchy/README.md` or `home/.{gitconfig,wezterm.lua}` (the W4
      reason for deletion). They should; otherwise stop and re-check
      scope.

## Commit 0.1 — Proposal

- [ ] `git add openspec/changes/housekeeping-cleanup/proposal.md`
      (99 lines, the approved proposal).
- [ ] Commit message: `docs(sdd): add housekeeping-cleanup proposal`.

**Verification**: `git ls-tree HEAD openspec/changes/housekeeping-cleanup/`
returns `proposal.md`.

## Commit 0.2 — Tasks

- [ ] `git add openspec/changes/housekeeping-cleanup/tasks.md` (this file).
- [ ] Commit message: `docs(sdd): add housekeeping-cleanup tasks`.

**Verification**: `git ls-tree HEAD openspec/changes/housekeeping-cleanup/`
returns both `proposal.md` and `tasks.md`.

## Commit 1 — Fix `.gitignore` SSH rules

> "Re-anchor the SSH ignore rules at the post-reorg path."

Scope: `.gitignore` lines 4-8 (the SSH comment block + the two rules).
The two path updates and the comment edit are atomic — leaving the
comment claiming `shared/home/.ssh/` while the rules point at
`src/home/.ssh/` would be worse than the current state.

- [ ] `.gitignore` line 5: rewrite the parenthetical "Anything else that
      lands in shared/home/.ssh/" to "Anything else that lands in
      src/home/.ssh/".
- [ ] `.gitignore` line 8: replace `shared/home/.ssh/*` with
      `src/home/.ssh/*`.
- [ ] `.gitignore` line 9: replace `!shared/home/.ssh/config` with
      `!src/home/.ssh/config`.
- [ ] Confirm the file is now 9 lines (no line count drift).
- [ ] Commit message:
      `chore(gitignore): point SSH ignore rules at src/home/.ssh/`
      (per the proposal's stated direction).

**Verification**:
- [ ] `git grep -nE 'shared/home/\.ssh' -- .gitignore` returns zero hits.
- [ ] `git grep -nE 'src/home/\.ssh' -- .gitignore` returns the two
      expected hits (the rule and the negative-lookahead exception).
- [ ] The SSH comment block on line 4 still ends with "must never
      enter the repo." (no comment drift).

**Rollback**: revert one commit. The pre-reorg dead rules return; no
runtime impact (the rules were inert before too).

## Commit 2 — Remove Fedora/Windows-era docs

> "Delete `docs/git.md` and `docs/wezterm.md`; both reference files
> the reorg removed."

Scope: two file deletions in one commit. The two files are
independent but adjacent concerns (Fedora-era git guide, Windows-era
WezTerm guide) that share the same fix (delete). Pairing them keeps
the PR's story tight: "two doc relics, gone in one step."

- [ ] `git rm docs/git.md` (36 lines, references `home/.gitconfig` and
      `omarchy/README.md`).
- [ ] `git rm docs/wezterm.md` (36 lines, references `home/.wezterm.lua`
      and `omarchy/README.md`).
- [ ] Confirm `git status` shows no other deletion candidates. The
      apply phase must NOT touch `docs/ideas/scripts/cleanup.md` (W2
      stays deferred per the proposal).
- [ ] Commit message:
      `chore(docs): remove Fedora/Windows-era guides`
      (per the proposal's stated direction).

**Verification**:
- [ ] `git ls-tree HEAD docs/git.md docs/wezterm.md` returns empty.
- [ ] `git grep -nE 'home/\.gitconfig|home/\.wezterm\.lua' -- ':!openspec/changes/archive/'`
      returns zero hits in tracked code, config, or docs.
- [ ] `docs/ideas/scripts/cleanup.md` is byte-identical to before
      (`git diff HEAD -- docs/ideas/scripts/cleanup.md` is empty —
      W2 stays deferred).

**Rollback**: revert one commit. Both files return with their original
content; no runtime impact (docs only).

## Apply phase — Push and open PR

- [ ] Push the branch: `git push -u origin <branch>`.
- [ ] Open a single PR to `main` with the title
      `chore: housekeeping follow-up — fix .gitignore and remove Fedora/Windows-era docs`.
- [ ] PR body lists the three work units, links the proposal, and
      calls out W2 as intentionally out of scope.
- [ ] No auto-merge. Wait for the user's review decision per the
      `apply:` rule in `openspec/config.yaml`.

## Verify phase (post-PR, pre-merge)

- [ ] **Tracked-surface scan** (per the proposal's success criteria):
      `git grep -nE 'shared/home/\.ssh|home/\.gitconfig|home/\.wezterm\.lua|omarchy/README\.md' -- ':!openspec/changes/archive/'`
      returns zero hits.
- [ ] **Archive intact**: `git status` shows no edit to
      `openspec/changes/archive/*`; the six archived change folders
      are byte-identical to before this change.
- [ ] **Unrelated change intact**: `git status` shows no edit to
      `openspec/changes/cleanup-omarchy/` (the in-flight unrelated
      change).
- [ ] **Work-unit commit log**: `git log --oneline origin/main..HEAD`
      shows four commits in order: 0.1 proposal, 0.2 tasks, 1
      gitignore, 2 docs.
- [ ] **TAP harness unchanged**: `bash tests/setup-deps.bash` still
      exits 0 with its prior test count (this change did not touch
      the test surface, so the count is the same as on `main`).
- [ ] **`.gitignore` final state**: lines 4-8 read with `src/home/.ssh/`
      in both rules and the comment; line 9 is the `!src/home/.ssh/config`
      exception.

## Archive task (post-merge, NOT part of the PR)

The proposal's "Capacidades" section is empty (no new or modified
capabilities), so the archive phase has no main spec delta to merge.
The `sdd-archive` phase moves the change folder into the archive and
records the result.

- [ ] `sdd-archive` confirms no `openspec/specs/<domain>/spec.md`
      delta needs to be merged (proposal "Capacidades" is empty;
      verify-report will say the same).
- [ ] `git mv openspec/changes/housekeeping-cleanup
      openspec/changes/archive/2026-06-18-housekeeping-cleanup`.
- [ ] The six pre-existing archived change folders remain
      byte-identical to before this change. No retroactive edits to
      historical artifacts.

## Out of scope (do not implement in this change)

- **W2** — the `docs/ideas/scripts/cleanup.md` references in
  `src/utils/bash/cleanup` lines 3/42/90. Deferred per the proposal.
  This change must not touch `src/utils/bash/cleanup` or
  `docs/ideas/scripts/cleanup.md`.
- `docs/cleanup.md` and the broader doc-comment tone cleanup — the
  orchestrator-level decision deferred W2; W3+W4 only.
- `openspec/changes/cleanup-omarchy/` — unrelated in-flight change;
  do not touch.
- `openspec/changes/archive/*` — historical artifacts; do not touch.
- New `src/home/.ssh/config` content — the existing tracked template
  is the correct one; the gitignore fix just re-anchors the protection
  to the directory that actually holds it.
- Re-adding the deleted docs in a different form — the
  Omarchy-only-scope change already established that Omarchy installer
  handles terminal and git identity surfaces. A new doc would be
  documentation of a contract this repo does not own.
