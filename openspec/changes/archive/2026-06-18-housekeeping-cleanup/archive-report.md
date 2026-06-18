# Archive Report: `housekeeping-cleanup`

**Change**: `housekeeping-cleanup`
**Archived at**: 2026-06-18
**Archived by**: `sdd-archive`
**Artifact store**: `openspec`
**Verification reference**: `openspec/changes/archive/2026-06-18-housekeeping-cleanup/verify-report.md`

---

## Summary

Archived `housekeeping-cleanup`, completing the post-reorg housekeeping follow-up
that re-anchored inert `.gitignore` SSH rules and removed two documentation relics.
W3 fixed `.gitignore` lines 5/8/9 to point at `src/home/.ssh/` (the path that
actually exists after PR #7's reorg) instead of the dead `shared/home/.ssh/*`.
W4 removed `docs/git.md` and `docs/wezterm.md`, both of which referenced files that
the reorg deleted (`home/.gitconfig`, `home/.wezterm.lua`, `omarchy/README.md`).
W2 (`docs/ideas/scripts/cleanup.md` and `src/utils/bash/cleanup` cross-references)
was explicitly deferred per proposal scope. No spec merge was needed; the proposal's
"Capacidades" section was empty.

---

## Change Metadata

| Field | Value |
|---|---|
| Change name | `housekeeping-cleanup` |
| Date archived | 2026-06-18 |
| Scope | W3 (`.gitignore` SSH rules) + W4 (Fedora/Windows-era doc removal) |
| Pace | interactive |
| Artifact store | openspec (B1) |
| PR strategy | single PR |
| Review budget | 400 lines (actual: ~80 lines of code/config + planning artifacts) |
| Delivery strategy | single PR |
| Spec merge | None (no capabilities delta) |

---

## Final Commit List (`chore/housekeeping-cleanup`)

```
02c0193 docs(sdd): add housekeeping-cleanup proposal
ecde163 docs(sdd): add housekeeping-cleanup tasks
113092b chore(gitignore): fix SSH path post-reorg
e0d78b8 chore(docs): remove guides referencing non-existent files
```

4 commits total. Commit 2 (`chore(docs): remove guides referencing non-existent files`)
deviates from `tasks.md` §"Commit 2" wording (`chore(docs): remove
Fedora/Windows-era guides`) — the orchestrator imposed a behavioral constraint
against Fedora-era framing in commit messages; the deviation is documented and
intentional (see SUGGESTION-S2).

---

## Files Changed

| Layer | Files | Net change |
|---|---|---|
| `.gitignore` | 1 modified | +3/-3 lines (path re-anchor only) |
| `docs/` | 2 deleted | -72 lines (`git.md`, `wezterm.md`) |
| Planning artifacts | 2 added | +308 lines (`proposal.md`, `tasks.md`) |
| **Total** | **5 files** | **+311/-75 lines** |

Diff stat vs `main`:
```text
.gitignore                                        |   6 +-
docs/git.md                                       |  36 ----
docs/wezterm.md                                   |  36 ----
openspec/changes/.../proposal.md | 100 +++++++++++
openspec/changes/.../tasks.md    | 208 ++++++++++++++++++++++
5 files changed, 311 insertions(+), 75 deletions(-)
```

---

## Verification Status

| Check | Result |
|---|---|
| TAP harness | ✅ 5/5 passed (`bash tests/setup-deps.bash`) |
| W3 — `.gitignore` lines 5/8/9 use `src/home/.ssh/` | ✅ Verified |
| W3 — no `shared/home/.ssh/` in `.gitignore` | ✅ 0 hits |
| W4 — `docs/git.md` and `docs/wezterm.md` deleted | ✅ Verified |
| W4 — `git grep -nE 'home/\.gitconfig\|home/\.wezterm\.lua'` returns hits only in planning artifacts | ✅ Verified |
| W2 deferral intact | ✅ `docs/ideas/scripts/cleanup.md` and `src/utils/bash/cleanup` byte-identical to `main` |
| Archive paths untouched | ✅ `openspec/changes/archive/*` byte-identical to `main` |
| Branch state | ✅ `chore/housekeeping-cleanup`, clean working tree |

| Status | Critical | Warning | Suggestion |
|---|---|---|---|
| **PASS WITH WARNINGS** (archive ready) | 0 | 0 | 2 |

---

## Suggestions (from verify-report)

### S1 — Reconcile proposal success-criterion #3 with `tasks.md`

The proposal's broader grep criterion (`shared/home/.ssh|home/.gitconfig|home/.wezterm.lua|omarchy/README.md`)
returns one historical hit in `openspec/specs/omarchy-preinstall-cleanup/spec.md:212`
— an explicit historical marker in the "Out of scope" section predating this change.
The `tasks.md` narrower scan (lines 135-136) is the correct gate and returns clean.
A 1-line proposal patch in a follow-up housekeeping change would prevent the same
"partial pass" from recurring on future verify passes against this archive folder.

### S2 — Commit message drift on commit 2

`tasks.md` §"Commit 2" specifies `chore(docs): remove Fedora/Windows-era guides`.
The actual commit message is `chore(docs): remove guides referencing non-existent
files`. Per the orchestrator's hard constraint, "Fedora-era" wording was avoided
in commit messages; the deviation is documented and intentional. Not blocking.
If a future contributor expects the `tasks.md` wording verbatim, the tasks file
could be amended in a future housekeeping pass.

---

## W2 Deferral

Per the proposal scope decision, `docs/ideas/scripts/cleanup.md` and the 3/42/90
line references in `src/utils/bash/cleanup` are intentionally out of scope for
this change. W2 is recorded as deferred for a future follow-up change.

---

## SDD Cycle Status

**Complete**: YES. All phases (explore, propose, tasks, apply, verify, archive)
are done. 0 CRITICAL findings. 2 SUGGESTIONs are documented for follow-up
commits. No spec merge was required.

**Next**: User reviews the diff, then pushes and opens PR via explicit instruction.
