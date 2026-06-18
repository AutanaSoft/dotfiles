# Archive Report: repo-structure-omarchy-reorg

**Change**: `repo-structure-omarchy-reorg`
**Archived at**: 2026-06-18
**Archived by**: `sdd-archive`
**Artifact store**: `openspec`
**Verification reference**: `openspec/changes/archive/2026-06-18-repo-structure-omarchy-reorg/verify-report.md`

---

## Summary

Archived `repo-structure-omarchy-reorg`, completing the realignment of the repo
top-level layout with the contract documented in `docs/conventions.md`. The
`omarchy/` wrapper, `shared/` indirection, and `scripts/` flat directory were
hard-removed. The new shape is `src/{home/{config,local},etc}/` +
`src/utils/bash/`: `src/home/config/` absorbs `omarchy/config/` + `shared/`;
`src/etc/` holds system configs (sudo-install, no symlink); and
`src/utils/bash/` holds the env executors. The env script `setup-omarchy`
became `setup-dots`; the root dispatcher flag `--omarchy` became `--dots`.
The 14 live `~/.config/...` symlinks survived the reorg via a shadow-copy
work-unit flow (WU-1 shadow copy → WU-3 live re-point → WU-4 atomic rename).

---

## Change Metadata

| Field | Value |
|---|---|
| Change name | `repo-structure-omarchy-reorg` |
| Date archived | 2026-06-18 |
| Scope | Omarchy-only (Hyprland + Arch) |
| Pace | interactive |
| Artifact store | openspec (B1) |
| PR strategy | chained feature-branch-chain (3 PRs + tracker) |
| Review budget | 400 lines (default; size:exception implicit for chained PRs) |
| Delivery strategy | chained PRs: `pr/01` → `pr/02` → `pr/03` |

---

## Resolved Decisions (from proposal, v1)

1. **Fork #1 — Structure**: `src/{home/{config,local},etc}/` replaces the
   `omarchy/` wrapper. Implemented via shadow-copy WU flow.
2. **Fork #2 — `shared/` rename**: MOOT — `shared/` absorbed into
   `src/home/config/` via WU-1 + WU-4 `git mv`.
3. **Fork #3 — Scripts**: `src/utils/bash/` with `setup-dots`,
   `setup-deps`, `setup-fonts`, `cleanup`. Root `./setup` stays at repo root.
4. **Fork #4 — Orphans**: `tmux.conf` kept with verbatim `# Reason:` comment
   per design Decision 5. Four `.gitkeep` files removed (WU-1 filesystem,
   WU-4 `git rm`).
5. **Fork #5 — Test and docs**: `tests/setup-deps.bash` not renamed
   (unchanged per Fork #5). `docs/ideas/scripts/cleanup.md` moved to
   `docs/cleanup.md` (WU-2).
6. **Flag rename `--omarchy` → `--dots`**: applies to root dispatcher and
   `setup-dots` script. `setup-deps` override flag stays `--omarchy` (per W1
   fix applied pre-archive).

---

## Chained PR Structure

| Branch | Base | WU scope | Commits |
|---|---|---|---|
| `feature/repo-structure-omarchy-reorg` | `main` | Planning artifacts | 4 (proposal, delta spec, design, tasks) |
| `pr/01-prep-and-scripts` | tracker | WU-1 (shadow copy) + WU-2 (script edits) + `docs/cleanup.md` move | 2 |
| `pr/02-reorg-and-commit` | `pr/01` | WU-3 (live re-point, no commit) + WU-4 (atomic rename + script finalize + flag rewrite) | 5 |
| `pr/03-docs` | `pr/02` | WU-5 (doc/config edits + code-comment sweep) + C1+W1 fixes | 7 + 2 fixup |

Total: 21 commits on the feature-branch-chain + 2 fixup commits on `pr/03-docs`.
Nothing pushed to remote.

---

## Files Changed

| Layer | Files | Notes |
|---|---|---|
| Planning artifacts | 4 | proposal.md, delta spec, design.md, tasks.md |
| Repo structure | 77 files | `git mv` + `git rm`; net body edits small |
| Scripts | 4 renamed + edited | `setup-omarchy` → `setup-dots`; `cleanup-omarchy` → `cleanup`; paths updated |
| Root dispatcher | 1 edited | `SCRIPTS_DIR` + flag rename `--omarchy` → `--dots` |
| Docs | 23 files | README, AGENTS, conventions, shared-layer, setup, hypr, starship, bin, nvim, ssh, zellij, git, inputs, nvim-keymaps, opencode, src/README, openspec/config |
| Spec | 1 merged | main spec updated with delta (109 insertions, 107 deletions) |

**Diff size**: ~270 lines with rename detection; ~3,800 without.

---

## Spec Merge

**Delta spec**: `openspec/changes/archive/2026-06-18-repo-structure-omarchy-reorg/specs/setup-orchestration/spec.md`
**Main spec**: `openspec/specs/setup-orchestration/spec.md`

13 MODIFIED sections merged. `DOTFILES_ENV` row in the variable contract
table preserved byte-identical (per verify-report and W1 fix). No
requirements added, removed, or renamed — pure path-level updates within
existing requirement text. Main spec grew from 493 → 495 lines.

---

## Verification Status

- **Tests**: 5/5 TAP passed (`bash tests/setup-deps.bash`)
- **Syntax**: all 5 scripts pass `bash -n`
- **Hyprland**: `hyprctl configerrors` returns empty
- **Live symlinks**: 14/14 resolve into `src/home/config/...` and `src/home/.bashrc`
- **Spec compliance**: 16/16 rows PASS
- **Design compliance**: 6/6 decisions PASS

| Status | Critical | Warning | Suggestion |
|---|---|---|---|
| **PASS WITH WARNINGS** | 0 | 4 | 3 |

### Known Exceptions (W2–W4)

- **W2** (`src/utils/bash/cleanup`): 3 stale `docs/ideas/scripts/cleanup.md`
  references. Not user-facing; contract-accurate. Fix in follow-up commit.
- **W3** (`.gitignore`): stale `shared/home/.ssh/*` rules. Functionally dead
  but misleading. Fix in follow-up commit.
- **W4** (`docs/git.md`, `docs/wezterm.md`): pre-`omarchy-only-scope` relics
  referencing non-existent paths. Explicitly out of scope for this reorg. Fix in
  follow-up change.

### Post-verify Fixes (commits `156355c`, `cdacc22`)

- **C1 fix** (`156355c`): `setup-dots:511` pre-flight fail message corrected
  from `--omarchy` to `--dots`.
- **W1 fix** (`156355c`): spec delta's 4 `setup-deps` override references
  corrected to `--omarchy` (matching implementation).
- **verify-report update** (`cdacc22`): updated to PASS verdict with 0 CRITICAL.

---

## Chained PR Strategy

Option A selected (3 chained PRs + feature-branch-chain tracker). Confirmed in
apply phase. Each PR under 400 lines of body diff; atomic rename in PR #2
protected by shadow-copy WU flow.

---

## Archived Changes Preservation

The five pre-existing archived change folders under
`openspec/changes/archive/` retain references to `omarchy/...`, `shared/...`,
and `scripts/...` because they predate this reorg. Per SDD archive policy,
archived artifacts are historical and were not retroactively edited. The
`git diff main..pr/03-docs -- 'openspec/changes/archive/'` check returned empty,
confirming the archive was not touched.

---

## SDD Cycle Status

**Complete**: YES. All phases (explore, propose, spec, design, tasks, apply,
verify, archive) are done. Zero CRITICAL findings. 4 WARNINGs and 3
SUGGESTIONs are documented for follow-up commits.

**Next**: User reviews the diff, then pushes and creates PRs via explicit
instruction.
