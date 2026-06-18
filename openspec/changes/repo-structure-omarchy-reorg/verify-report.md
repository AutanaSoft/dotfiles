# Verify Report: `repo-structure-omarchy-reorg`

> **Outcome**: Implementation matches the design's shadow-copy intent and the
> 5 work units landed as planned. One user-facing bug and one spec delta
> mismatch block archive. All other findings are documented for follow-up.

| Status | Critical | Warning | Suggestion |
| --- | --- | --- | --- |
| **FAIL** (archive blocked) | 1 | 4 | 3 |

Verify pass: 2026-06-18 against `pr/03-docs` @ `8ca614b` (HEAD of the
feature-branch-chain tracker).

## Quick path

- [x] All 14 live `~/.config/...` and `~/.bashrc` symlinks resolve into
  `src/home/config/...` and `src/home/.bashrc`.
- [x] `hyprctl configerrors` returns no errors.
- [x] TAP harness `bash tests/setup-deps.bash` → **5/5 passed**.
- [x] All five scripts pass `bash -n` syntax check.
- [x] `git ls-files | grep -E '^(omarchy|shared|scripts)/'` is empty.
- [x] `find src/home/config -name .gitkeep` is empty (all four redundant
  `.gitkeep` files removed, including the 4th at `omarchy/config/hypr/.gitkeep`
  that the apply note flagged — see S2 below).
- [x] `openspec/changes/archive/` and `openspec/changes/cleanup-omarchy/`
  are byte-identical to `main` (untouched per SDD archive policy).
- [x] `openspec/specs/setup-orchestration/spec.md` `DOTFILES_ENV` row
  untouched (byte-identical — merge happens at archive, not apply).
- [ ] **One CRITICAL bug + one spec delta text mismatch block archive** —
  see Findings below.

## Live-system evidence

| Check | Result |
| --- | --- |
| `readlink -f ~/.config/nvim` | `.../src/home/config/nvim` |
| `readlink -f ~/.config/zellij` | `.../src/home/config/zellij` |
| `readlink -f ~/.config/hypr/{hyprland,hypridle,p-bindings,p-index,p-looknfeel,p-monitors,p-rules}.conf` | all resolve to `.../src/home/config/hypr/<name>.conf` |
| `readlink -f ~/.config/waybar/config.jsonc` | `.../src/home/config/waybar/config.jsonc` |
| `readlink -f ~/.config/alacritty/alacritty.toml` | `.../src/home/config/alacritty/alacritty.toml` |
| `readlink -f ~/.config/omarchy/themes/tokyo-night-autana` | `.../src/home/config/omarchy/themes/tokyo-night-autana` |
| `readlink -f ~/.config/starship.toml` | `.../src/home/config/starship.toml` |
| `readlink -f ~/.bashrc` | `.../src/home/.bashrc` |
| `[[ -e ~/.config/keyd ]]` | `DOES NOT EXIST` (no home symlink; spec satisfied) |
| `hyprctl configerrors` | empty output, exit 0 |
| `bash tests/setup-deps.bash` | `1..5` / `ok 1..5` / `# 5/5 passed` |
| `bash -n setup src/utils/bash/{setup-dots,setup-deps,setup-fonts,cleanup}` | all exit 0 |

The 14 live symlinks survive the WU-3 → WU-4 transition because the shadow
paths become final paths via `git mv` (atomic in git; the resolved inodes
are unchanged). The post-WU-4 commit `26f6631` (`fix(setup-dots): correct
REPO_ROOT resolution for src/utils/bash/`) repaired a path-resolution
regression that the WU-4 atomic commit introduced; the fix is committed
in PR #2 and is included in the final tree.

## PR-branch verification (chained feature-branch-chain)

| Branch | Base | WU scope | Commits |
| --- | --- | --- | --- |
| `feature/repo-structure-omarchy-reorg` | `main` | planning artifacts | 4 (proposal, spec, design, tasks) |
| `pr/01-prep-and-scripts` | tracker | WU-1 (shadow copy) + WU-2 (script edits) + `docs/cleanup.md` move | 2 (planning + WU-1+WU-2 combined as `c26374b`) |
| `pr/02-reorg-and-commit` | `pr/01` | WU-3 (live re-point, no commit) + WU-4 (atomic rename + script finalize + `setup` flag rewrite) | 5 (see S1 below for why this is 5 not 1) |
| `pr/03-docs` | `pr/02` | WU-5 (doc + config edits + code-comment sweep) | 7 (README, AGENTS, shared-layer, setup+tool docs, src/README, openspec config, code-comment sweep) |

Diff stats (relative to base of each branch):

| Branch | Files | Insertions | Deletions |
| --- | --- | --- | --- |
| `pr/01` | 7 | ~1,878 | 18 (planning artifacts dominate) |
| `pr/02` | 77 | 124 | 227 (most are renames; net body edits small) |
| `pr/03` | 23 | 198 | 184 (doc updates) |

Total: 19 commits on the feature-branch-chain; nothing pushed to remote.

## Spec compliance

| Spec delta requirement | Implementation | Status |
| --- | --- | --- |
| Root dispatches to `src/utils/bash/setup-dots` | `setup:120` parser arm `--dots)` invokes `src/utils/bash/setup-dots` | PASS |
| Root accepts `--dots`, `--fonts`, `--deps`, `--dry-run`, `--help`/`-h` | `setup:78` usage lists all 5; parser arms at lines 120/144/149 handle each | PASS |
| Root is a thin dispatcher (no `run_deps`/`run_fonts`/`run_env`/`TOTAL_STEPS`) | `grep -n 'run_deps\|run_fonts\|run_env\|TOTAL_STEPS' setup` returns 0 hits | PASS |
| `--dots` absorbs `--fonts` / `--deps` | `setup:120` `case --dots)` falls through; no separate `--fonts`/`--deps` dispatch when combined | PASS |
| Env script owns full flow: deps → fonts → pre-flight → symlinks → keyd install → validate | `setup-dots` lines 488–527 (5 steps + pre-flight) | PASS |
| Env script `TOTAL_STEPS=5` + `current_step` counter | `setup-dots:463-469` | PASS |
| `setup-deps` auto-detects host via `yay` / `pacman` probes | `setup-deps:165-176` | PASS |
| `setup-deps` exits non-zero when no PM found | `setup-deps:189` exit code with clear message | PASS |
| `setup-deps` single-pass batch install with summary | `setup-deps` lines 275–312 (per-package `[ok]`/`[miss]` + batch + summary) | PASS |
| `OMARCHY_PACKAGES` includes `keyd`, `piper`, `libratbag` (no standalone `ratbagd`) | `setup-deps:50-64` | PASS |
| `setup-deps` honors `$DOTFILES_DRY_RUN` | `setup-deps:138-140` | PASS |
| `setup-fonts` honors `$DOTFILES_FONTS_DIR` with `$HOME/.local/share/fonts/autanasoft` default | `setup-fonts` reads env var with fallback | PASS |
| keyd config sourced from `src/etc/keyd/default.conf` (not `~/.config/keyd/`) | `setup-dots:403`; `~/.config/keyd` confirmed absent | PASS |
| keyd config installed to `/etc/keyd/default.conf` mode 0644 via `sudo install -m 644` (not symlink) | `setup-dots:402-418` | PASS |
| `keyd` + `ratbagd` enabled+started via single coalesced `sudo systemctl enable --now` | `setup-dots:417` (single call) | PASS |
| `apply_symlinks` map is per-file for hypr, folder for nvim/zellij, file for waybar/alacritty/starship/bashrc | `setup-dots:318-380` | PASS |
| No `~/.config/keyd/` symlink created | `apply_symlinks` has no `keyd` entry; live tree confirms | PASS |
| `src/etc/keyd/default.conf` uses `noop` to silence volumeup/volumedown | `src/etc/keyd/default.conf:39-40` (`volumeup = noop; volumedown = noop`) | PASS |
| `src/etc/keyd/default.conf` remaps broken `up` to `pagedown` | verified in the same file | PASS |
| `src/etc/keyd/default.conf` scope `[ids] *` (universal) | line `[ids] *` in the file | PASS |
| **Spec delta `setup-deps explicit override` says `--dots`** | `setup-deps:110` parser arm is `--omarchy)`, not `--dots)` | **FAIL — see W1** |
| `DOTFILES_ENV` row byte-identical to pre-change | main spec untouched (last touched by `omarchy-only-scope` merge) | PASS (merge happens at archive) |

## Design compliance

| Design decision | Implementation | Status |
| --- | --- | --- |
| Decision 1 — Shadow copy (not direct `git mv`) | WU-1 created `src/*-shadow` trees; WU-4 atomic `git mv shadow → final` | PASS |
| Decision 2 — `cp -a` semantics, 3 relative symlinks handled | `cp -a` copied targets directly; `rm` of symlinks in WU-1; `git rm` in WU-4 | PASS |
| Decision 3 — `apply_symlinks` idempotency is the safety net | `ensure_symlink` lines 231–271 resolve both source and target via `readlink -f`; verified by live symlinks still resolving after `git mv` | PASS |
| Decision 4 — `--dots` flag rename timing | Renamed in WU-2 (script) + WU-4 (dispatcher + setup-deps docs); see W1 for the residual spec delta text | PARTIAL — see W1 |
| Decision 5 — `tmux.conf` `# Reason:` wording | `src/home/config/tmux/tmux.conf:1` matches design Decision 5 verbatim: `# Reason: personal tmux config (97 lines); kept tracked to preserve the live symlink. No env-script changes.` | PASS |
| Decision 6 — Spec↔apply bridge | All 6 design table rows match implementation | PASS |

## Findings

### CRITICAL

#### C1 — User-facing fail message in `setup-dots` references the old root flag

- **File**: `src/utils/bash/setup-dots:511`
- **Current text**:
  `fail "Nerd Fonts not installed under $font_dir. Run './setup --omarchy --fonts' first."`
- **Expected text**:
  `fail "Nerd Fonts not installed under $font_dir. Run './setup --dots --fonts' first."`
- **Why critical**: the root `./setup` dispatcher no longer accepts
  `--omarchy`; the WU-4 flag rewrite removed it. If a user triggers the
  pre-flight fail (no fonts dir), the error message tells them to use a
  flag that exits non-zero with "Unknown argument". This is a real
  user-facing bug.
- **Trigger path**: the pre-flight check at `setup-dots:507-513` runs
  when the env script is invoked directly (bypassing root, e.g.
  `src/utils/bash/setup-dots` with no fonts installed). It does NOT
  fire on the normal `./setup --dots` path because root sets
  `DOTFILES_FONTS_DIR` to a populated path before dispatching.
- **Fix scope**: 1-line change in `src/utils/bash/setup-dots:511`.
  Belongs in the WU-5 sweep retroactively (the sweep commit
  `8ca614b` missed this line).
- **Resolution**: edit `setup-dots:511` to use `--dots`. Add to WU-5
  follow-up or fix in a small follow-up commit on `pr/03-docs`.

### WARNING

#### W1 — Spec delta `setup-deps explicit override` says `--dots`; implementation uses `--omarchy`

- **Spec delta location**: `openspec/changes/repo-structure-omarchy-reorg/specs/setup-orchestration/spec.md`
  - Line 255-256: "`--dots` MUST remain a valid argument to `src/utils/bash/setup-deps`"
  - Line 269: "GIVEN ... `src/utils/bash/setup-deps --dots` runs"
  - Line 351: "GIVEN `src/utils/bash/setup-deps --dots --dry-run` is invoked"
- **Implementation**: `src/utils/bash/setup-deps:110` parser arm is
  `--omarchy)`, not `--dots)`. The internal call from `setup-dots:153` is
  `args=(--omarchy)`. The doc and comment in `setup-deps:6,71,83,187`
  all reference `--omarchy`.
- **Why warning (not critical)**: per the user's explicit intent (and
  the apply phase's documented engram note), the `--omarchy` override
  in `setup-deps` is a **package-manager override** (forces the Omarchy
  env), conceptually separate from the root `--dots` flag (which
  selects the env script). The implementation is correct; the spec
  delta has a textual mismatch that needs a small fix at archive time.
- **Why not a SUGGESTION**: the spec delta is currently inconsistent
  with the implementation, and the archive phase is the merge point
  where this must be reconciled. Archive should rewrite the three
  `--dots` → `--omarchy` references in the spec delta. Without that
  rewrite, the post-merge main spec will claim `--dots` is the override
  when the implementation rejects it.
- **Resolution path**: archive phase rewrites the three `--dots` →
  `--omarchy` references in the spec delta; the merge then lands the
  correct contract in the main spec.

#### W2 — `src/utils/bash/cleanup` script still references the old docs path

- **File**: `src/utils/bash/cleanup`
- **Lines**:
  - Line 3 (header): `# marked [R] in docs/ideas/scripts/cleanup.md.`
  - Line 42 (inline comment): `# Inline arrays (29 [R] items; 0 in TUIs). Source: docs/ideas/scripts/cleanup.md.`
  - Line 90 (usage text): `docs/ideas/scripts/cleanup.md. Operates on a hardcoded list of 29 items`
- **Why warning (not critical)**: documentation drift in an internal
  comment / usage text, not a user-facing bug or a contract violation.
  The `docs/ideas/scripts/cleanup.md` file no longer exists (moved to
  `docs/cleanup.md` in WU-2). A future maintainer reading the help text
  or the inline comment would be confused.
- **Why not SUGGESTION**: the WU-5 code-comment sweep commit
  (`8ca614b`) was explicitly intended to fix this kind of drift; it
  caught the `omarchy/README.md` reference at line 96 of the same file
  but missed these three. This is a missed sweep item, not a casual
  improvement.
- **Resolution**: replace `docs/ideas/scripts/cleanup.md` with
  `docs/cleanup.md` in those three lines. Add to WU-5 follow-up or fix
  in a small follow-up commit on `pr/03-docs`.

#### W3 — `.gitignore` still has `shared/home/.ssh/*` rules

- **File**: `.gitignore` lines 5-9
- **Current state**: rules reference the non-existent `shared/home/.ssh/`
  path; comment says "Anything else that lands in `shared/home/.ssh/`".
- **Reality**: SSH template moved to `src/home/.ssh/config` in WU-4.
  The `shared/` directory is gone from the working tree.
- **Why warning (not critical)**: the rules are functionally dead
  (no path matches) so no security or git-correctness regression.
  But the comment misleads future readers and agents about where SSH
  private keys live; a future agent reading `.gitignore` would think
  per-host SSH files should land in `shared/home/.ssh/`.
- **Resolution**: rewrite the block to reference `src/home/.ssh/`:
  ```
  src/home/.ssh/*
  !src/home/.ssh/config
  ```
  Add to WU-5 follow-up or fix in a small follow-up commit.

#### W4 — `docs/git.md` and `docs/wezterm.md` reference non-existent paths

- **Files**:
  - `docs/git.md` lines 3, 7, 14, 35, 36 — references `home/.gitconfig`
    (no such file) and `omarchy/README.md` (now `src/README.md`).
  - `docs/wezterm.md` lines 7, 15, 35, 36 — references `home/.wezterm.lua`
    (no such file) and `omarchy/README.md`.
- **Why warning (not critical)**: these are pre-`omarchy-only-scope`
  relics that the WU-5 plan explicitly scoped out. The apply note
  documented them as follow-up. The current reorg does not
  introduce the references (they predate this change) so they do not
  block the reorg's archive. They do confuse future readers.
- **Resolution**: follow-up change that either removes the docs
  (if git/wezterm are out of repo scope per the docs/conventions
  policy) or rewrites them to reference the current paths.

### SUGGESTION

#### S1 — WU-4 landed as 5 commits, not 1 atomic commit

- **Design said**: WU-4 is "the atomic commit" (singular).
- **Actual**: PR #2 has 5 commits:
  1. `8ac2548 refactor(repo): hoist to src/{home/{config,local},etc}/ (atomic rename shadow→final)`
  2. `70434de feat(setup-dots): rename script + drop -omarchy suffix`
  3. `65b1592 chore(repo): git rm omarchy/, shared/, scripts/`
  4. `00c03b3 chore(setup): point SCRIPTS_DIR at src/utils/bash + update tests`
  5. `26f6631 fix(setup-dots): correct REPO_ROOT resolution for src/utils/bash/`
- **Why informational**: the additional commits (dispatcher
  `SCRIPTS_DIR` update, test rewrite, REPO_ROOT fix) are each
  justified and small. The `26f6631` fix landed the same day as the
  WU-4 atomic rename — a one-commit atomicity violation is preferable
  to a broken script. Future similar work could plan more aggressive
  batching, but this is informational only.
- **Resolution**: none required; document for future apply phases.

#### S2 — The 4th `.gitkeep` was NOT missed

- **Apply note claim**: "`omarchy/config/hypr/.gitkeep` was missed by the plan".
- **Reality**: `git log --diff-filter=D --name-only --oneline -- '*.gitkeep'`
  confirms `omarchy/config/hypr/.gitkeep` was removed in commit
  `8ac2548` alongside the other three (mako, omarchy/hooks, omarchy/themes).
  Current state: `find src/home/config -name .gitkeep` returns empty.
- **Why informational**: the apply note was slightly inaccurate. No
  missing file in the working tree.
- **Resolution**: none.

#### S3 — Archived changes retain references to the old `omarchy/`, `shared/`, `scripts/` paths

- **Where**: `openspec/changes/archive/*` (5 pre-existing folders:
  `2026-06-14-ideas-implementation`, `2026-06-16-cleanup-omarchy`,
  `2026-06-17-input-devices-config`,
  `2026-06-17-setup-deps-batch-install`,
  `2026-06-18-omarchy-only-scope`).
- **Reality**: these folders still mention the old paths in their
  proposals, specs, and design documents.
- **Why informational**: per SDD archive policy, archived artifacts
  are historical and must not be retroactively edited. The byte-
  identical check (`git diff main..pr/03-docs -- 'openspec/changes/archive/'`)
  returns empty, confirming the archive was not modified by this change.
- **Note for future readers** (and future agents): the archived
  references to `omarchy/...`, `shared/...`, and `scripts/setup-...`
  predate this reorg. They describe the contract as it was when those
  changes landed. To find the current contract, read
  `docs/conventions.md` and the post-merge main spec at
  `openspec/specs/setup-orchestration/spec.md`.

## Constraints verification

| Constraint | Check | Result |
| --- | --- | --- |
| `DOTFILES_ENV` row byte-identical in main spec | `git diff main..pr/03-docs -- openspec/specs/setup-orchestration/spec.md` | empty (PASS) |
| Archived changes byte-identical | `git diff main..pr/03-docs -- 'openspec/changes/archive/'` | empty (PASS) |
| Active unrelated change untouched | `git diff main..pr/03-docs -- 'openspec/changes/cleanup-omarchy/'` | empty (PASS — N/A; the change was already archived) |
| Working tree clean | `git status` | clean (PASS) |
| 14 live symlinks re-pointed | `readlink -f` on each of 14 paths | all resolve to `src/home/config/...` or `src/home/.bashrc` (PASS) |
| `hyprctl configerrors` clean | `hyprctl configerrors` | empty output (PASS) |
| TAP harness | `bash tests/setup-deps.bash` | 5/5 passed (PASS) |
| All scripts syntax-clean | `bash -n` on 5 scripts | all exit 0 (PASS) |
| No `omarchy/`, `shared/`, `scripts/` in tracked tree | `git ls-files \| grep -E '^(omarchy\|shared\|scripts)/'` | empty (PASS) |
| No `.gitkeep` in `src/home/config/` | `find src/home/config -name .gitkeep` | empty (PASS) |
| No `../../shared/` in working tree | `git grep '../../shared/' -- ':!openspec/changes/archive'` | empty (PASS) |
| No `~/.config/keyd/` symlink | `[[ -e ~/.config/keyd ]]` | false (PASS) |
| No env-2 references in active code | grep for `fedora`, `cachyos` (env-2 names) in `src/`, `tests/`, `setup` | none in active code (PASS) |

> Note: the engram topic `dotfiles/repo-scope` confirms env-2 is out of
> scope; the `feat/setup-env-dependencies` branch on the remote
> predates `omarchy-only-scope` and is not part of this verify.

## Lost TAP coverage note

The `omarchy-only-scope` change removed tests T3, T7, T8 (already
documented in the WU-5 pre-flight section of `tasks.md`). This
reorg does NOT remove additional tests. The TAP harness is unchanged
in shape (5 tests, T1/T2/T4/T5/T6) and all 5 pass in the current
tree. No coverage was lost as part of the reorg.

## Archived changes note

The five pre-existing archived change folders under
`openspec/changes/archive/` retain references to the previous
`omarchy/...`, `shared/...`, and `scripts/...` paths because they
predate this reorg. Per SDD archive policy, archived artifacts
are historical and were not retroactively edited — the
`git diff main..pr/03-docs -- 'openspec/changes/archive/'` check
returned empty, confirming the archive was not touched. This is
intentional and matches the precedent set by the
`omarchy-only-scope` change (2026-06-18).

## `tmux.conf` `# Reason:` check

- **File**: `src/home/config/tmux/tmux.conf:1`
- **Text**:
  `# Reason: personal tmux config (97 lines); kept tracked to preserve the live symlink. No env-script changes.`
- **Match against design Decision 5**: exact match.
- **Actual file content** (lines 3-10 sample): personal config (prefix
  `C-Space`, vi-mode, status bar, theme) — consistent with the
  97-line / 2,869-byte personal config documented in the
  `tmux-discrepancy` engram note.

## `AGENTS.md` line 55 fix check

- **Pre-change text** (per WU-5 task): "Hyprland / Mako / Waybar /
  Walker configs (omarchy-only, not shared)".
- **Post-change text** (current `AGENTS.md:50-58`):
  - `~/.local/share/omarchy/` — managed by omarchy
  - SSH private keys, `known_hosts`, machine-specific tokens
  - Hyprland / Mako / Waybar / Walker configs that are pure omarchy
    defaults (only the per-host overrides in `src/home/config/` are
    tracked; the rest stay at the omarchy default)
- **Grep check**: `grep -n 'not shared' AGENTS.md` returns 0 hits.
- **Conclusion**: the misleading wording is gone; the new Forbidden
  Paths list is consistent with the reorg's `src/home/config/`
  canonical layer.

## Final verdict

**FAIL** — archive is blocked by one CRITICAL (C1) and one
WARNING (W1) finding.

The C1 fix is a 1-line edit in `src/utils/bash/setup-dots:511` and
should land before archive. The W1 spec delta text fix
(`--dots` → `--omarchy` in three lines of the spec delta) should
land as part of the archive's spec merge.

W2/W3/W4 are documented for follow-up commits on `pr/03-docs`; they
do not block archive but should be addressed before the next
reorg to prevent drift accumulation.

S1/S2/S3 are informational.

## Relevant files

- `src/utils/bash/setup-dots` — env script (line 511: C1; line 153
  intentional `--omarchy` call; line 448 intentional `setup-deps
  --omarchy` warn message)
- `src/utils/bash/setup-deps` — deps script (intentional `--omarchy`
  override; see W1 for spec delta text mismatch)
- `src/utils/bash/cleanup` — cleanup script (lines 3/42/90: W2)
- `.gitignore` — stale `shared/home/.ssh/*` rules (W3)
- `docs/git.md`, `docs/wezterm.md` — pre-omarchy-only-scope relics (W4)
- `openspec/changes/repo-structure-omarchy-reorg/specs/setup-orchestration/spec.md`
  — spec delta (W1: three `--dots` → `--omarchy` rewrites needed at
  archive)
- `openspec/changes/archive/*` — byte-identical to main (S3)
- `tests/setup-deps.bash` — 5/5 passing
- `src/home/config/tmux/tmux.conf` — `# Reason:` matches design
  Decision 5
- `AGENTS.md:50-58` — Forbidden Paths rewritten (line 55 fix)
- `src/utils/bash/setup-dots:402-418` — keyd install (mode 0644, no
  home symlink)
- `src/etc/keyd/default.conf` — keyd config source (correct path;
  `noop` for volup/voldn; remap `up` → `pagedown`; `[ids] *` scope)
