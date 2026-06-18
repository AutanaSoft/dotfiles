# Archive Report: omarchy-only-scope (Omarchy-only)

**Change**: `omarchy-only-scope`
**Archived at**: 2026-06-18
**Archived by**: `sdd-archive`
**Artifact store**: `openspec`
**Verification reference**: `openspec/changes/archive/2026-06-18-omarchy-only-scope/verify-report.md`

---

## Summary

Archived `omarchy-only-scope`, collapsing the dotfiles repo from a
two-host-family surface to one. Hard-removed `fedora/` and
`docs/ideas/scripts/setup.md`; the `./setup` dispatcher and
`scripts/setup-deps` lost every env-conditional branch; the removed
CLI flag is now a plain unknown-flag case (exit 2 with usage on
stderr); the TAP harness dropped from 8 to 5 tests (T3, T7, T8
removed). CachyOS+Omarchy and Arch+Omarchy are treated identically —
the Omarchy installer handles distribution-specific config; this
repo's only AUR-helper concern is `yay`. Delta spec merged into
`openspec/specs/setup-orchestration/spec.md` (9 requirements removed or
narrowed, 73 lines removed from the main spec). Sign-off: **PASS WITH
WARNINGS**.

---

## Change Metadata

| Field | Value |
|---|---|
| Change name | `omarchy-only-scope` |
| Date archived | 2026-06-18 |
| Scope | Omarchy-only (Hyprland + Arch/CachyOS) |
| Pace | interactive |
| Artifact store | openspec |
| PR strategy | single-pr with `size:exception` |
| Review budget | 2,400 line-equivalents (forecast) |
| Delivery strategy | single-pr (user-authorized exception) |
| Final diff | 2,707 line-equivalents (+307 over forecast, +12.8%) |

### Locked Decisions (from proposal, user-confirmed 2026-06-17)

1. `git rm -r fedora/` — hard removal; no local trace; recoverable
   from git history.
2. Removed CLI flag becomes unknown flag → exit 2 (existing branch
   covers it; no special-case message).
3. `FEDORA_PACKAGES` and every env-conditional install branch removed
   from `scripts/setup-deps`; auto-detection collapses to `yay` →
   Omarchy and `pacman` → Omarchy with a `yay`-missing warning.
4. T3, T7, T8 removed entirely; `TEST_PLAN` drops from 8 to 5.
5. No historical note added to the main spec after the env-2 surface
   is removed.
6. CachyOS+Omarchy and Arch+Omarchy are functionally identical; `yay`
   is the only AUR helper concern.
7. `docs/ideas/scripts/setup.md` eliminated alongside the scope cut.
8. Archived change folders remain intact; SDD archive policy wins over
   retroactive edits.

---

## Commit History (6 commits)

| # | SHA | Summary |
|---|---|---|
| 1 | `1dfb9dd` | docs(sdd): add omarchy-only-scope change artifacts |
| 2 | `5c2341c` | chore(repo): drop the secondary host family from the dotfiles repo |
| 3 | `3864f37` | feat(setup): collapse dispatcher to a single host family |
| 4 | `46721c3` | feat(setup-deps): collapse auto-detect and install to a single host family |
| 5 | `50fcd68` | chore(spec): merge omarchy-only-scope delta into main spec |
| 6 | (pending) | chore(sdd): archive omarchy-only-scope |

---

## Spec Merge

**Delta spec**:
`openspec/changes/archive/2026-06-18-omarchy-only-scope/specs/setup-orchestration/spec.md`

**Main spec**:
`openspec/specs/setup-orchestration/spec.md`

9 requirements removed or narrowed; 73 lines removed from the main
spec (566 → 493 lines).

| # | Requirement | Action |
|---|---|---|
| 1 | Quick path table | Removed `--fedora` row |
| 2 | Flag contract and precedence | Removed `--fedora` from accepted flags; removed mutual-exclusion scenario |
| 3 | `--fedora not-implemented behavior` | Removed entirely (whole requirement) |
| 4 | Fedora single-pass install coalesces sudo | Removed entirely (whole requirement) |
| 5 | setup-deps auto-detection | Removed `dnf`/`rpm` probe rows; narrowed error message |
| 6 | setup-deps explicit override | Removed `--fedora` override scenario |
| 7 | Input-devices packages | Removed `FEDORA_PACKAGES` reference and 2 Fedora-only scenarios |
| 8 | TAP test coverage for input-devices | Removed T8 sub-case D Fedora scenario; narrowed text |
| 9 | Documentation and test coverage | Removed `--fedora` mention; changed `TEST_PLAN=8` → `TEST_PLAN=5` |

**Preserved byte-identical**: `DOTFILES_ENV` row in Exported variable
contract (line 96 in main spec). The variable remains accurate because
`--omarchy` is still a valid explicit override for `scripts/setup-deps`.

---

## Verification Status

- **Tests**: 5/5 TAP passing (`bash tests/setup-deps.bash`)
- **Dispatcher**: `--help` lists 5 surviving flags; `--<removed-flag>`
  exits 2 with "Unknown argument" + usage
- **Deps**: `--help` lists only `--omarchy`, `--dry-run`, `--help`;
  `--<removed-flag>` exits 2; `--omarchy --dry-run` emits exactly one
  `yay -S --needed` line with all 9 packages
- **Findings**: 0 CRITICAL · 2 WARNING · 1 SUGGESTION

### Known Exceptions

| # | Finding | Disposition |
|---|---|---|
| W1 | `scripts/setup-fonts:5` retains one historical comment with the removed flag name | Byte-identical keep constraint; comment lies about current contract; future cleanup pass could trim it |
| W2 | Main spec retained env-2 references throughout before merge | Resolved by the delta merge in this archive phase |

### Lost TAP Coverage

9 scenarios lost their bash-TAP harness (T7 and T8 removed). They
remain in the spec; only the automated assertion is gone. A future
change can re-add TAP coverage for the ones that matter.

| From | Lost scenarios |
|---|---|
| T7 (auto-detect) | yay→omarchy probe; pacman-no-yay warning; no-PM-fail; `--omarchy` override skips detection |
| T8 (single-pass batch install) | all-present skip; 1-missing-Omarchy; ≥2-missing-Omarchy; install-failure-aborts |

---

## Size Exception

| Forecast | Actual | Delta |
|---|---|---|
| 2,400 line-equivalents | 2,707 line-equivalents (28 files, +1,394 / −1,313) | +307 (+12.8%) |

User authorized `size:exception` in advance. The diff is dominated by
deletions (test-file removals + folder removal), which are easier to
review than equivalent additions. The 3-commit work-unit structure
protected review focus: each commit is reviewable in isolation.

---

## Archived Changes Preservation

The four folders under `openspec/changes/archive/` retain references
to the removed host family. They predate the 2026-06-17 scope lock
and are preserved on purpose per the SDD archive policy declared in
`openspec/config.yaml` (`archive:` rules: "Never delete or modify
archived change folders.").

Concretely, the archived change folders contain:

- The removed-flag short-circuit contract (e.g., "print 'not
  implemented', exit 0" behavior and the dispatch table row).
- The removed package list and the `sudo dnf install -y` install
  command.
- The `dnf` / `rpm` rows in the auto-detect probe table.
- A `TAP` line `ok 3 - --<removed-flag> (any combo) short-circuits
  to not-implemented and exits 0` in an archived verify-report.

These references describe a contract that no longer exists. They are
not retroactive edits — they are history. Future readers (and future
agents) reading the archive should not interpret them as the current
contract. The current contract lives in
`openspec/specs/setup-orchestration/spec.md` after this delta merge.

---

## Post-Archive Working Tree

```
On branch main
Your branch is ahead of 'origin/main' by 7 commits.
```

Changes not staged for commit (unrelated drift):
- `shared/nvim/lazy-lock.json` — plugin version bumps
- `shared/zellij/config.kdl` — comment-out of `default_layout "autanasoft"`

Untracked files:
- `openspec/changes/omarchy-only-scope/explore.md` — opencode
  exploration notes (not part of deliverable)

---

## Recommended Next Step (User Decision)

**Review the diff and push.** The local branch is 7 commits ahead of
`origin/main`. Suggested push:

```bash
git push origin main
```

**Stage only the archived folder** (the spec merge is already
committed):

```bash
git add openspec/changes/archive/2026-06-18-omarchy-only-scope/
git status   # confirm only the archive folder is staged
```

Do NOT stage `shared/nvim/lazy-lock.json` or `shared/zellij/config.kdl`
— those are pre-existing drift unrelated to this change.

---

## SDD Cycle Status

**Complete**: YES. All phases (explore, propose, spec, design, tasks,
apply, verify, archive) are done. No CRITICAL findings. 2 WARNINGs are
within design tolerance (W1: byte-identical keep; W2: post-archive
merge). 1 SUGGESTION is out of this change's scope (S1: `shared/`
comment wording).

**Next**: User reviews the diff, optionally pushes, and closes the
session. No further SDD phases apply — the change is closed.
