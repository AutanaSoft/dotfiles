# Verify Report: `housekeeping-cleanup`

> **Outcome**: W3 (`.gitignore` SSH rules) and W4 (Fedora/Windows-era docs)
> match the proposal and tasks. All four work-unit commits landed in order,
> the TAP harness still passes 5/5, and the archive + cleanup-omarchy paths
> are untouched. One broader proposal grep is unachievable without expanding
> scope (documented as a NOTE). Archive can proceed.

| Status | Critical | Warning | Suggestion |
| --- | --- | --- | --- |
| **PASS WITH WARNINGS** (archive ready) | 0 | 0 | 2 |

Verify pass: 2026-06-18 against `chore/housekeeping-cleanup` @ `e0d78b8`
(branched off `main@b5b4702` / merge PR #7).

## Verification scope

The change has proposal + tasks only (no spec.md, no design.md). Per the
`Tasks only` graceful-handling rule, this verify focuses on objective task
completion plus constraint coverage from the proposal's "Criterios de éxito".

| Artifact | Present? | Used for |
| --- | --- | --- |
| `proposal.md` | Yes (Spanish) | Source of scope + success criteria |
| `tasks.md` | Yes (English) | Source of work-unit commit structure |
| `spec.md` | No | Proposal explicitly states "no capabilities"; no spec delta to merge |
| `design.md` | No | N/A — this change touches `.gitignore` rules and deletes docs; no design decisions to deviate from |

## Quick path

| Check | Result |
| --- | --- |
| W3 — `.gitignore` lines 5/8/9 use `src/home/.ssh/` | ✅ Verified |
| W3 — no leftover `shared/home/.ssh/` in `.gitignore` | ✅ Verified |
| W3 — `.gitignore` line count preserved at 9 | ✅ Verified |
| W4 — `docs/git.md` and `docs/wezterm.md` removed from tracked tree | ✅ Verified |
| W4 — `git log --diff-filter=D` shows both deletions on this branch | ✅ Verified |
| TAP harness — `bash tests/setup-deps.bash` | ✅ 5/5 passed |
| Branch — `chore/housekeeping-cleanup` with clean working tree | ✅ Verified |
| Constraint — no `shared/` or `omarchy/` in tracked tree | ✅ Verified |
| Constraint — `openspec/changes/archive/*` byte-identical to main | ✅ Verified |
| Constraint — `openspec/changes/cleanup-omarchy/` untouched | ✅ Vacuously verified (not present on this branch — see NOTE-1) |
| W2 deferral — `docs/ideas/scripts/cleanup.md` and `src/utils/bash/cleanup` byte-identical to main | ✅ Verified |

## Detailed checks

### W3 — `.gitignore` SSH rules re-anchored

`.gitignore` final state (9 lines, no drift):

```gitignore
.atl/
backup/

# SSH: only `config` is tracked, as a safe template (no secrets, no real
# hostnames/users/keys). Anything else that lands in src/home/.ssh/
# (private keys, known_hosts, real machine-specific configs) is per-host
# and must never enter the repo.
src/home/.ssh/*
!src/home/.ssh/config
```

| Line | Content | Status |
| --- | --- | --- |
| 4 | `# SSH: only \`config\` is tracked, as a safe template (no secrets, no real` | ✅ Unchanged |
| 5 | `# hostnames/users/keys). Anything else that lands in src/home/.ssh/` | ✅ Updated per tasks.md §"Commit 1" |
| 8 | `src/home/.ssh/*` | ✅ Updated per tasks.md §"Commit 1" |
| 9 | `!src/home/.ssh/config` | ✅ Updated per tasks.md §"Commit 1" |

Grep evidence:

- `git grep -nE 'shared/home/\.ssh' -- .gitignore` → 0 hits
- `git grep -nE 'src/home/\.ssh' -- .gitignore` → 3 hits (line 5 comment, line 8 rule, line 9 exception)

### W4 — Fedora/Windows-era docs removed

```text
$ git ls-files | grep -E '^docs/(git|wezterm)\.md$'
(empty — exit 1)

$ git log --diff-filter=D --name-only --pretty=format:"%H %s" HEAD~2..HEAD
e0d78b8232bc4685430678e8ff9981afc6365d7e chore(docs): remove guides referencing non-existent files
docs/git.md
docs/wezterm.md

$ wc -l docs/git.md docs/wezterm.md
wc: docs/git.md: No such file or directory
wc: docs/wezterm.md: No such file or directory
```

Both files are gone from the working tree and from `git ls-files`; both deletions are recorded in commit `e0d78b8`.

### TAP harness unchanged

```text
$ bash tests/setup-deps.bash
1..5
ok 1 - root --dots invokes setup-dots exactly once
ok 2 - --dots --fonts and --dots --deps are absorbed by root
ok 3 - --fonts runs only setup-fonts; --deps runs only setup-deps
ok 4 - env-script pre-flight handles missing/overridden $DOTFILES_FONTS_DIR
ok 5 - DOTFILES_* (5 vars) cleanup under env -i + trap source grep
# 5/5 passed
```

Test count unchanged from `main`. This change did not touch the test surface; behavior is unchanged.

### Branch and commit structure

```text
$ git status
On branch chore/housekeeping-cleanup
nothing to commit, working tree clean

$ git log --oneline origin/main..HEAD
e0d78b8 chore(docs): remove guides referencing non-existent files
113092b chore(gitignore): fix SSH path post-reorg
ecde163 docs(sdd): add housekeeping-cleanup tasks
02c0193 docs(sdd): add housekeeping-cleanup proposal
```

4 commits in the planned order: 0.1 proposal → 0.2 tasks → 1 gitignore → 2 docs.

Diff stat vs `main`:

```text
.gitignore                                        |   6 +-
docs/git.md                                       |  36 ----
docs/wezterm.md                                   |  36 ----
openspec/changes/housekeeping-cleanup/proposal.md | 100 +++++++++++
openspec/changes/housekeeping-cleanup/tasks.md    | 208 ++++++++++++++++++++++
5 files changed, 311 insertions(+), 75 deletions(-)
```

Net change matches the proposal's "Qué cambia" table (1 modified, 2 deleted) plus the two planning artifacts. Well under the 400-line review budget.

### Out-of-scope paths untouched

```text
$ git diff origin/main..HEAD -- docs/ideas/scripts/cleanup.md src/utils/bash/cleanup
(empty — exit 0)

$ git diff origin/main..HEAD -- openspec/changes/archive/
(empty — 0 lines)

$ git diff origin/main..HEAD -- openspec/changes/cleanup-omarchy/
(empty — directory does not exist on this branch)
```

W2 stays deferred. Archive byte-identical. The `cleanup-omarchy` active change referenced in the prompt is not present on this branch (it was archived as `archive/2026-06-16-cleanup-omarchy/`); see NOTE-1.

### Repo-scope constraints

```text
$ git ls-files | grep -E '^shared/|^omarchy/'
(empty — exit 1)
```

No `shared/` or `omarchy/` paths in the tracked tree. Confirms the reorg (PR #7) cleanup that motivated this follow-up is complete.

## Proposal success-criteria check

The proposal lists four success criteria (lines 95-100):

| # | Criterion | Result |
| --- | --- | --- |
| 1 | `.gitignore` lines 5-9 use `src/home/.ssh/*` and `!src/home/.ssh/config` | ✅ Met |
| 2 | `docs/git.md` and `docs/wezterm.md` no longer in tracked tree | ✅ Met |
| 3 | `git grep -nE 'shared/home/\.ssh\|home/\.gitconfig\|home/\.wezterm\.lua\|omarchy/README\.md' -- ':!openspec/changes/archive/'` returns empty | ⚠️ Partial — see NOTE-2 |
| 4 | `openspec/changes/archive/*` and `openspec/changes/cleanup-omarchy/` byte-identical to `main` | ✅ Met |

## Notes (non-blocking)

### NOTE-1 — `cleanup-omarchy/` not present on this branch

The verify brief flagged `openspec/changes/cleanup-omarchy/` as an "active
unrelated change" that must not be touched. On this branch and on `main`,
that directory does not exist — it was archived on 2026-06-16 as
`openspec/changes/archive/2026-06-16-cleanup-omarchy/`. The constraint is
satisfied vacuously (nothing to touch). If the brief assumed an in-flight
re-activation of that work on a sibling branch, that is out of scope for
this verify pass; the archive evidence already shows the folder is
byte-identical to its archived state on `main`.

### NOTE-2 — proposal grep criterion #3 has one historical hit

The proposal's success criterion #3 (line 97) expects the broader grep
(`shared/home/.ssh|home/.gitconfig|home/.wezterm.lua|omarchy/README.md`)
to return empty. It returns one hit outside the change artifacts:

```text
openspec/specs/omarchy-preinstall-cleanup/spec.md:212: - An `omarchy/README.md` entry in v1.
```

This line lives in the **"Out of scope"** section of the unrelated
`omarchy-preinstall-cleanup` main spec. It is an explicit historical
marker documenting an intentional non-decision (we did NOT add an
`omarchy/README.md` entry in v1). It predates this change and is
unrelated to the housekeeping scope.

The narrower scan specified by `tasks.md` (lines 135-136 — excludes
`omarchy/README.md`) returns empty in tracked code, config, and docs:

```text
$ git grep -nE 'home/\.gitconfig|home/\.wezterm\.lua' -- ':!openspec/changes/archive/'
openspec/changes/housekeeping-cleanup/proposal.md:19,32,33
openspec/changes/housekeeping-cleanup/tasks.md:16,122,124
```

All hits are inside the planning artifacts of this change (descriptions
of what was removed). The actual W4 surface is clean.

See SUGGESTION-S1 for the recommended follow-up to reconcile the
proposal's broader grep with reality.

## Findings

### CRITICAL

None. Implementation matches proposal and tasks on every dimension that
affects archive readiness.

### WARNING

None.

### SUGGESTION

- **S1 — Reconcile proposal success-criterion #3 with `tasks.md`.** The
  proposal's broader grep is unachievable without expanding scope into
  the `omarchy-preinstall-cleanup` spec. The `tasks.md` narrower scan
  (lines 135-136) is the correct gate. A 1-line proposal patch in a
  follow-up housekeeping change would prevent the same "partial pass"
  from recurring on future verify passes against this archive folder.

- **S2 — Commit message drift on commit 2.** `tasks.md` §"Commit 2"
  specifies `chore(docs): remove Fedora/Windows-era guides`. The actual
  commit message is `chore(docs): remove guides referencing
  non-existent files`. Per the apply-phase engram record
  (`sdd/housekeeping-cleanup/apply-progress`), the orchestrator
  imposed a hard constraint to avoid "Fedora-era" wording in commit
  messages; the deviation is documented and intentional. Not
  blocking — but if a future contributor expects the tasks.md wording
  verbatim, the tasks file could be amended in a future housekeeping
  pass.

## Verdict

**PASS WITH WARNINGS** — archive ready.

The implementation is complete, the tests pass, the branch is in the
expected state with the expected commit structure, and the constraints
the proposal depends on hold. The two SUGGESTIONs are documentation
hygiene items for a future change; they do not affect archive readiness
for this one.

## Next step

Archive this change per the proposal's "Criterios de éxito":

1. Confirm `openspec/specs/<domain>/spec.md` delta is empty (proposal
   "Capacidades" is empty; no main spec merge needed).
2. `git mv openspec/changes/housekeeping-cleanup openspec/changes/archive/2026-06-18-housekeeping-cleanup`.
3. The six pre-existing archived change folders remain byte-identical.