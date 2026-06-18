# Design: repo-structure-omarchy-reorg

## Context

The repo top-level layout drifts from `docs/conventions.md`: `omarchy/` wraps a
single-env setup (redundant since `omarchy-only-scope`), `shared/` adds a
two-hop symlink layer (`omarchy/config/nvim → ../../shared/nvim`) the spec
already deprecates, and `scripts/` mixes env executors with helpers under one
flat directory. The change replaces these with `src/{home/{config,local},etc/}`
+ `src/utils/bash/`, hard-removes `omarchy/`, `shared/`, `scripts/`, renames
the env script `setup-omarchy` → `setup-dots`, renames the dispatcher flag
`--omarchy` → `--dots`, and re-points the 14 live `~/.config/...` symlinks to
the new repo paths. The apply phase is the risk surface; this design
encodes a shadow-copy work-unit flow so every step is independently
reversible and the live system never loses its symlinks.

## Goals / Non-goals

| Goals | Non-goals |
| --- | --- |
| Close spec↔disk drift; one canonical layout | Change the symlink contract semantics |
| 14 live symlinks keep resolving across the reorg | Modify Hyprland/Zellij/nvim tool configs |
| `tmux.conf` stays tracked (97 lines, personal config) | Touch `openspec/changes/archive/*` or `cleanup-omarchy/` |
| `apply_symlinks()` is the single point of path truth | Touch `~/.local/share/omarchy/` or per-host secrets |
| Single-apply atomic rename (shadow → final) | Add new tooling or capacity |
| Dispatches (`./setup --dots`, `--fonts`, `--deps`) all work | Change `DOTFILES_*` variable contract |

## Architectural approach

### Decision 1 — Shadow copy, not direct `git mv`

**Choice**: copy data files to `src/home/config-shadow/` (and friends) in
WU-1; re-point live symlinks to the shadow paths in WU-3; only in WU-4 do
`git mv shadow → final` and `git rm -r omarchy shared scripts`.

**Why**: a direct `git mv omarchy/config → src/home/config` would delete
the old path before `apply_symlinks()` runs, leaving the 14 live symlinks
pointing at missing files between the move and the symlink re-point. The
shadow copy keeps both old and new trees on disk through WU-3, so
`ensure_symlink()` always finds a source at both the old and new paths.
WU-4's `git mv` is then atomic in git: the shadow path becomes the final
path in one step, and live symlinks that point at the shadow path keep
working because the path identity changes in one commit.

**Rollback points** (per WU): WU-1 `rm -r src/*-shadow`; WU-2
`git checkout -- scripts/setup-omarchy`; WU-3 re-run `bash scripts/setup-omarchy`
to revert symlinks to `omarchy/...`; WU-4 `git revert HEAD` +
`bash scripts/setup-omarchy`.

### Decision 2 — `cp -a` semantics and the 3 relative symlinks

**Choice**: `cp -a src dst` preserves attrs and copies symlinks as
symlinks. The 3 relative symlinks `omarchy/config/{nvim,zellij,starship.toml}`
→ `../../shared/...` are NOT copied: their targets are being moved, so
copying the symlinks would yield dangling links. Instead, copy the
target directories `shared/{nvim,zellij,}` and the file `shared/starship.toml`
directly into `src/home/config-shadow/` and `rm` the source-side relative
symlinks (filesystem-only — `git rm` comes in WU-4).

### Decision 3 — `apply_symlinks()` idempotency is the safety net

`ensure_symlink()` (lines 232–272 of `scripts/setup-omarchy`) resolves
both `$source` and `$target` via `readlink -f`; if the live symlink points
to the same real path as the requested source it returns 0 without
touching anything. This is what makes the rename safe across WU-3 → WU-4:
the symlinks already point to the shadow path, and when `git mv` makes
the shadow path the final path, the resolved targets are still identical,
so re-running the script is a no-op.

### Decision 4 — `--dots` flag rename timing (WU-2)

The dispatcher flag rename `--omarchy` → `--dots` and the script rename
`setup-omarchy` → `setup-dots` happen in **WU-2** (script edits) and
**WU-4** (atomic commit). WU-2 edits `scripts/setup-omarchy` paths and
the `setup-dots` invocations inside it; the root `setup` dispatcher's
flag parsing is rewritten to `--dots` only in WU-4 (because the
`scripts/` folder is renamed in WU-4 via `git mv`).

### Decision 5 — `tmux.conf` `# Reason:` wording

`omarchy/config/tmux/tmux.conf` is 97 lines (2,869 bytes) of personal
config (prefix `C-Space`, vi-mode copy, pane controls, status bar,
theme) — NOT byte-identical to Omarchy default as the explore phase
claimed. The `# Reason:` comment must therefore read:
> `# Reason: personal tmux config (97 lines); kept tracked to preserve the live symlink. No env-script changes.`

### Decision 6 — Spec↔apply bridge

| Spec MODIFIED scenario | Apply phase implementation |
| --- | --- |
| Root is a thin dispatcher → invokes `src/utils/bash/setup-dots` | WU-2 edits script paths; WU-4 `git mv` and rewrites `setup` dispatch table |
| Flag contract (`--dots`, `--fonts`, `--deps`, ...) | WU-4 rewrites `setup` flag parsing (`--omarchy` → `--dots`); spec delta already updated |
| `--dots` dispatch + env-script ownership | WU-2 edits `apply_symlinks()` to point at `src/home/config-shadow/`; WU-3 re-points live symlinks; WU-4 path finalization |
| `apply_symlinks` map | WU-2 rewrites every `$REPO_ROOT/omarchy/config/...` reference (9 entries); grep assertion in verify |
| keyd config source = `src/etc/keyd/default.conf` | WU-1 copies `omarchy/home/.config/keyd/` to `src/etc-shadow/keyd/`; WU-2 updates `install_input_devices()`; WU-4 renames |
| SSH template source = `src/home/.ssh/config` | WU-1 copies `shared/home/.ssh/` to `src/home/.ssh-shadow/`; WU-2 updates `seed_ssh_config()` |
| No `~/.config/keyd/` symlink | `apply_symlinks()` in new `setup-dots` has no keyd entry; grep assertion in verify |

## File-by-file changes

| Path | Action | Notes |
| --- | --- | --- |
| `src/home/config/` | Create (via shadow) | Absorbs `omarchy/config/` + `shared/{nvim,zellij,starship.toml}` |
| `src/home/config/tmux/tmux.conf` | Move + add `# Reason:` | 97-line personal config; see Decision 5 |
| `src/home/config/{mako,omarchy/hooks,omarchy/themes}/.gitkeep` | Delete (filesystem WU-1, git WU-4) | Redundant per Fork #4 |
| `src/home/.bashrc` | Move from `omarchy/home/.bashrc` | top of `src/home/`, not `src/home/config/` |
| `src/home/local/bin/monitor` | Move from `omarchy/local/bin/monitor` | Manual-only, NOT symlinked |
| `src/home/.ssh/config` | Move from `shared/home/.ssh/config` | SSH template exception moves with it |
| `src/etc/keyd/default.conf` | Move from `omarchy/home/.config/keyd/default.conf` | New `src/etc/` tier; install pattern preserved |
| `src/README.md` | Move + rename from `omarchy/README.md` | Update managed-paths table |
| `src/utils/bash/setup-dots` | Rename + move from `scripts/setup-omarchy` | Docstring/usage updated |
| `src/utils/bash/setup-deps` | Move from `scripts/setup-deps` | Body unchanged; flag `--omarchy` → `--dots` |
| `src/utils/bash/setup-fonts` | Move from `scripts/setup-fonts` | Body unchanged |
| `src/utils/bash/cleanup` | Rename + move from `scripts/cleanup-omarchy` | Docstring/usage updated |
| `setup` (root) | Modify | `SCRIPTS_DIR=$DOTFILES_ROOT/src/utils/bash`; flag rename |
| `omarchy/`, `shared/`, `scripts/` | `git rm -r` in WU-4 | Historical surface stays in `git log` |
| `tests/setup-deps.bash` | Unchanged per Fork #5 | `TEST_PLAN=5`; assertions need path update |
| `docs/cleanup.md` | Move from `docs/ideas/scripts/cleanup.md` | Out of scratch folder |
| `AGENTS.md` | Modify | Rewrite Forbidden Paths list (line 55 is wrong); new `Setup entrypoint` rule |
| `README.md`, `docs/conventions.md`, `docs/shared-layer.md`, `src/README.md` | Modify | Path examples only |
| `openspec/config.yaml` | Modify | `context:` block reflects new layout |
| `openspec/changes/{archive/*,cleanup-omarchy/}` | Untouched | Policy |

## Test plan

| Layer | What | Approach |
| --- | --- | --- |
| Unit | `apply_symlinks()` path map is correct | After WU-2, grep `src/utils/bash/setup-dots` for `REPO_ROOT/src/home/config-shadow`; after WU-4 grep `src/utils/bash/setup-dots` for `REPO_ROOT/src/home/config`; assert no `REPO_ROOT/omarchy/` remains |
| Integration | 14 live symlinks re-pointed | After WU-3, `readlink -f` on each path; after WU-4, re-assert; `git ls-files | grep -E '^(omarchy\|shared\|scripts)/'` returns empty |
| Integration | keyd config installed | `/etc/keyd/default.conf` mode `0644`, bit-identical to `src/etc/keyd/default.conf` |
| E2E | TAP harness passes | `bash tests/setup-deps.bash` — `TEST_PLAN=5` (harness unchanged; one assertion pair in T1/T2/T4 needs new script name `setup-dots`) |
| E2E | Hyprland reload clean | `hyprctl reload && hyprctl configerrors` returns empty |
| Negative | No `../../shared/` survives | `git grep 'shared/'` returns empty in working tree |

## Work-unit commit structure

Each WU is one PR-reviewable commit. Sequenced; each independently
reversible.

| WU | Commit message shape | Committed surface |
| --- | --- | --- |
| WU-1 | `chore(repo): shadow-copy data dirs to src/*-shadow (no live-system changes)` | Shadow dirs untracked; no `git add` |
| WU-2 | `refactor(scripts): point setup-omarchy at shadow paths` | `scripts/setup-omarchy` (apply_symlinks + install_input_devices + seed_ssh_config); `docs/cleanup.md` move |
| WU-3 | (no commit — live re-point only) | Working tree change only; commit deferred to WU-4 |
| WU-4 | `chore(repo): atomic rename to src/{home/{config,local},etc/} + src/utils/bash/` | All `git mv` + `git rm`; final path edits in scripts; root `setup` flag rewrite (`--omarchy` → `--dots`); `--dots` propagation into `setup-deps` |
| WU-5 | `docs(repo): align docs with src/ layout + AGENTS.md forbidden-paths fix` | `README.md`, `AGENTS.md`, `docs/conventions.md`, `docs/shared-layer.md`, `src/README.md`, `openspec/config.yaml`, spec delta |

The chained-PR budget is medium risk: WU-1+WU-2 are a small first PR
(<400 lines, no live changes); WU-3+WU-4 are the high-risk second PR
(live re-point + atomic commit); WU-5 is the docs PR. Confirm
chained-PR strategy with the user before applying.

## Verification approach

| When | Check |
| --- | --- |
| After WU-1 | `diff -r omarchy/config src/home/config-shadow` shows only the 3 removed relative symlinks + 3 removed `.gitkeep` files; live system untouched |
| After WU-2 | `grep -r 'omarchy/config' scripts/setup-omarchy` returns empty; `grep 'src/home/config-shadow' scripts/setup-omarchy` matches every previous `omarchy/config/...` reference |
| After WU-3 (dry-run) | `bash scripts/setup-omarchy --dry-run` lists 14 expected symlinks pointing to `src/home/config-shadow/...` |
| After WU-3 (real) | `readlink -f` on each of the 14 paths resolves into `src/home/config-shadow/`; `cat /etc/keyd/default.conf` matches `src/etc-shadow/keyd/default.conf`; `hyprctl configerrors` empty |
| After WU-4 | `git ls-files | grep -E '^(omarchy\|shared\|scripts)/'` empty; `readlink -f` re-asserted (now resolves into `src/home/config/`); `git grep '../../shared/'` empty |
| Final | `bash tests/setup-deps.bash` → 5/5; `hyprctl configerrors` empty; `docs/cleanup.md` exists; `docs/ideas/scripts/cleanup.md` does not; `AGENTS.md` line 55 fixed (grep "not shared" empty) |

## Risks and mitigations

| Risk | Prob | Mitigation |
| --- | --- | --- |
| Live symlinks dangle during `git mv` | High | Shadow copy in WU-1; re-point in WU-3; `git mv` is atomic in WU-4; `apply_symlinks()` idempotency means re-run is safe |
| 3 relative symlinks (`omarchy/config/{nvim,zellij,starship.toml}`) become dangling under shadow | Med | Don't copy them; copy targets directly; `rm` from filesystem (WU-1); `git rm` (WU-4); verify with `git grep '../../shared/'` |
| `tmux.conf` `# Reason:` mis-describes actual content | Med | Read file before comment edit; 97-line personal config (not Omarchy default); see Decision 5 |
| `AGENTS.md` line 55 correction incomplete | Low | After WU-5, grep `AGENTS.md` for "not shared" returns empty; verify report quotes new Forbidden Paths section |
| `--dots` flag rename misses a reference | Low | WU-4 grep `--omarchy` across `setup`, `src/utils/bash/*`, docs; assert empty post-rename |
| `cleanup` rename breaks external cron/alias | Med | WU-5 greps `~/.bashrc`, `~/.config/{zellij,nvim}/...` for `cleanup-omarchy`; offer one-line update |
| `p-` prefix semantic breaks under new path | None | Files now under `src/home/config/hypr/`; symlink target is the only path Omarchy's updater sees |
| Docs over-edited (changes layout rule, not just paths) | Low | WU-5 edits are path-only; layout table text unchanged; review focus on diff scope |
