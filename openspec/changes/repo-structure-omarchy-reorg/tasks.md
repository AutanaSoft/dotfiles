# Tasks: repo-structure-omarchy-reorg

> Implementation tasks for the `repo-structure-omarchy-reorg` change.
> This document is the apply-phase checklist; the design encodes the
> shadow-copy work-unit flow (see `design.md`).

## Outcome

Realign the repo top-level layout with the contract already documented
in `docs/conventions.md`. The `omarchy/` wrapper, the `shared/`
indirection, and the `scripts/` flat directory are hard-removed. The
new shape is `src/{home/{config,local},etc/}` + `src/utils/bash/`:
`src/home/config/` becomes the canonical home for `~/.config/`
contents (absorbing `omarchy/config/` + `shared/`); `src/home/local/`
for `~/.local/share/...` content; `src/etc/` for `/etc/` system
configs (sudo-install, no symlink); and `src/utils/bash/` for env
executors. The env script `setup-omarchy` becomes `setup-dots`; the
`cleanup-omarchy` helper becomes `cleanup`; the root dispatcher flag
`--omarchy` becomes `--dots`. The 14 live `~/.config/...` symlinks
keep resolving across the reorg.

## Work-unit commit structure

| Commit | Scope | Work unit |
| --- | --- | --- |
| 0 | Planning artifacts | `proposal.md`, `specs/.../spec.md`, `design.md`, `tasks.md` |
| 1 | WU-1 — Shadow copy + diff verify | Filesystem only, no `git add` / `git rm`. Shadow dirs `src/*-shadow` populated. 3 relative symlinks `rm`'d from filesystem. 3 `.gitkeep` files `rm`'d. `tmux.conf` gains `# Reason:` comment inside the shadow. |
| 2 | WU-2 — Edit scripts | `scripts/setup-omarchy` paths point at shadow paths. `docs/ideas/scripts/cleanup.md` moves to `docs/cleanup.md`. |
| 3 | WU-3 — Live re-point (no commit) | `bash scripts/setup-omarchy --dry-run`, then real run; live symlinks point at shadow paths. Verified with `readlink -f`, `cat /etc/keyd/default.conf`, `hyprctl configerrors`. |
| 4 | WU-4 — Atomic commit | All `git mv` from shadow to final paths. `git rm -r omarchy/ shared/ scripts/`. Path strings in scripts switch `*-shadow` → final. Root `setup` flag rename `--omarchy` → `--dots`. `--dots` propagates into `setup-deps` parser. |
| 5 | WU-5 — Doc/config edits + verify | `README.md`, `AGENTS.md`, `docs/conventions.md`, `docs/shared-layer.md`, `docs/setup.md`, `docs/hypr.md`, `docs/starship.md`, `docs/bin.md`, `docs/nvim.md`, `docs/ssh.md`, `docs/wezterm.md`, `docs/zellij.md`, `docs/git.md`, `docs/nvim-keymaps.md`, `docs/inputs/*.md`, `docs/nvim/opencode.md`, `src/README.md`, `openspec/config.yaml`. Spec delta stays in the change folder (archived post-merge). Final TAP test + `hyprctl configerrors` + `readlink -f` audit. |
| (archive) | Spec merge | Post-merge; `sdd-archive` phase. Not part of the PR. |

The design recommends a chained-PR strategy: WU-1+WU-2 are a small,
no-live-changes first PR; WU-3+WU-4 are the high-risk second PR
(live re-point + atomic commit); WU-5 is the docs PR. The apply
phase confirms the PR strategy with the user before opening PRs
(see Pre-flight below).

## Pre-flight (before any commit)

- [ ] **Confirm with the user which PR strategy applies**:
      (a) three chained PRs (WU-1+WU-2 → WU-3+WU-4 → WU-5), the
      design's recommended shape; (b) one PR with `size:exception`
      covering all five work units; (c) a different split the user
      prefers. Do not commit or push until the user picks.
- [ ] Read `design.md` "Architectural approach" section in full
      (six numbered decisions). Each is a place where a naive
      mechanical apply would silently regress the contract.
- [ ] Verify the working tree is clean: `git status` shows nothing
      pending. The apply phase starts from a clean state.

## Commit 0 — Planning artifacts

These four files already live in
`openspec/changes/repo-structure-omarchy-reorg/` and are committed
in the first commit so the change folder is self-contained on disk
before any work-unit commit lands.

- [ ] `git add openspec/changes/repo-structure-omarchy-reorg/proposal.md`
      (257 lines, Spanish per project preference
      `dotfiles/sdd-language-preference`).
- [ ] `git add openspec/changes/repo-structure-omarchy-reorg/specs/setup-orchestration/spec.md`
      (466 lines, Spanish).
- [ ] `git add openspec/changes/repo-structure-omarchy-reorg/design.md`
      (175 lines, English).
- [ ] `git add openspec/changes/repo-structure-omarchy-reorg/tasks.md`
      (this file, English).
- [ ] Commit message: `docs(sdd): add repo-structure-omarchy-reorg change artifacts`.

**Verification**:
`git ls-tree HEAD openspec/changes/repo-structure-omarchy-reorg/`
returns the four files plus the `specs/` directory.

## Commit 1 — WU-1: Shadow copy + diff verify

> "Shadow-copy data dirs to `src/*-shadow` (no live-system changes)."
>
> Scope: filesystem only. After this commit, the working tree has
> both the old paths and the new shadow paths in parallel. No
> `git add` / `git rm` is performed. The 3 relative symlinks
> (`omarchy/config/{nvim,zellij,starship.toml}` → `../../shared/...`)
> are removed from the filesystem because their targets are being
> moved (copying them would yield dangling links). The 3 `.gitkeep`
> files (`mako/`, `omarchy/hooks/`, `omarchy/themes/`) are removed
> from the filesystem because they are redundant per Fork #4.
> The tmux `# Reason:` comment is added inside the shadow copy
> only — the original file at `omarchy/config/tmux/tmux.conf` is
> untouched until WU-4.

- [ ] `cp -a omarchy/config src/home/config-shadow` — copy with
      attrs preserved, relative symlinks copied as symlinks (which
      we then `rm`).
- [ ] `cp -a omarchy/home/.bashrc src/home/.bashrc-shadow`.
- [ ] `cp -a omarchy/local src/home/local-shadow`.
- [ ] `cp -a shared/home/.ssh src/home/.ssh-shadow`.
- [ ] `cp -a shared/nvim src/home/config-shadow/nvim` (nested copy
      of the real target that the relative symlink points at).
- [ ] `cp -a shared/zellij src/home/config-shadow/zellij`.
- [ ] `cp -a shared/starship.toml src/home/config-shadow/starship.toml`.
- [ ] `cp -a omarchy/home/.config/keyd src/etc-shadow/keyd`.
- [ ] `cp -a omarchy/README.md src/README-shadow.md`.
- [ ] `rm omarchy/config/nvim omarchy/config/zellij omarchy/config/starship.toml`
      — remove the 3 relative symlinks from the filesystem (NOT
      `git rm`; `git rm` comes in WU-4).
- [ ] `rm omarchy/config/mako/.gitkeep omarchy/config/omarchy/hooks/.gitkeep omarchy/config/omarchy/themes/.gitkeep`
      — remove the 3 redundant `.gitkeep` files from the filesystem
      (NOT `git rm`; `git rm` comes in WU-4).
- [ ] Edit `src/home/config-shadow/tmux/tmux.conf`: add a
      `# Reason:` comment at the top. **Critical**: re-read the
      file first to confirm the wording matches actual content
      (97 lines of personal config: prefix `C-Space`, vi-mode
      copy, pane controls, status bar, theme). The exact wording
      must be:
      > `# Reason: personal tmux config (97 lines); kept tracked to preserve the live symlink. No env-script changes.`
      See design Decision 5 and the tmux-discrepancy engram note.
- [ ] Confirm `diff -r omarchy/config src/home/config-shadow`
      shows only the 3 removed relative symlinks + 3 removed
      `.gitkeep` files (8 expected diff entries; the rest must be
      identical).
- [ ] Confirm `diff -r omarchy/home/.config/keyd src/etc-shadow/keyd`
      returns empty (identical).
- [ ] Confirm no live symlink was touched: `readlink -f ~/.config/...`
      still resolves to `omarchy/...` paths (or `shared/...` for
      the 3 symlinks that pointed at shared via the relative
      indirection).
- [ ] `git status` shows no staged changes; the working tree has
      `src/*-shadow` as untracked.

**Verification**:
- [ ] `ls src/` shows `config-shadow/`, `bashrc-shadow` (file),
      `local-shadow/`, `ssh-shadow/`, `README-shadow.md`, and
      `etc-shadow/` next to each other.
- [ ] `git status` lists `src/*-shadow` as untracked; no tracked
      files are staged.
- [ ] Live system unchanged: every `~/.config/...` symlink still
      points at the old `omarchy/...` (or `shared/...` for the
      3 relative ones, now dangling until WU-3).

**Rollback**: `rm -rf src/home/config-shadow src/home/.bashrc-shadow
src/home/local-shadow src/home/.ssh-shadow src/etc-shadow
src/README-shadow.md`, `git checkout -- omarchy/`. Working tree
restored. The 3 `rm`'d symlinks and 3 `rm`'d `.gitkeep` files are
recoverable from git index (`git checkout HEAD -- <path>`).

**Commit message**:
`chore(repo): shadow-copy data dirs to src/*-shadow (no live-system changes)`.

> **Note on the commit**: although this WU does not stage tracked
> changes, the design treats it as a single reviewable commit
> (forensic value: the shadow tree is in git history as a
> `git status` snapshot if anything goes wrong). If the user
> prefers, the apply phase can skip this commit and document the
> shadow state in the verify report. Confirm during pre-flight.

## Commit 2 — WU-2: Edit scripts (point at shadow paths)

> "Point `scripts/setup-omarchy` at shadow paths; move
> `docs/ideas/scripts/cleanup.md` out of the scratch folder."
>
> Scope: the env script (path strings only — no behavior change)
> and one doc move. Live symlinks are NOT touched in this commit
> (the env script edits take effect on the WU-3 run).

- [ ] `docs/cleanup.md` move:
  - [ ] `git mv docs/ideas/scripts/cleanup.md docs/cleanup.md`.
  - [ ] No content edit; the file content is correct as-is
        (the path examples inside still reference
        `scripts/cleanup-omarchy` and are updated in WU-5).
- [ ] `scripts/setup-omarchy` (534 lines) — apply the following
      path-string edits only:
  - [ ] `apply_symlinks()` (the symlink map near line 285): every
        `$REPO_ROOT/omarchy/config/...` reference changes to
        `$REPO_ROOT/src/home/config-shadow/...`. 9 entries:
        `nvim`, `zellij`, `hypr/*.conf` (7 hypr files via a glob),
        `waybar/config.jsonc`, `alacritty/alacritty.toml`,
        `omarchy/themes/tokyo-night-autana`, `starship.toml`,
        plus the `$REPO_ROOT/omarchy/home/.bashrc` entry (becomes
        `$REPO_ROOT/src/home/.bashrc-shadow`).
  - [ ] `install_input_devices()` (keyd install, near line 405):
        `$REPO_ROOT/omarchy/home/.config/keyd/default.conf` →
        `$REPO_ROOT/src/etc-shadow/keyd/default.conf`.
  - [ ] `seed_ssh_config()` (SSH template, near line 285):
        `$REPO_ROOT/shared/home/.ssh/config` →
        `$REPO_ROOT/src/home/.ssh-shadow/config`.
  - [ ] The `monitor` comment near line 378:
        `omarchy/local/bin/monitor` →
        `src/home/local-shadow/bin/monitor` (final path comes in
        WU-4).
  - [ ] The `mako/hooks/themes` comment near line 380:
        `omarchy/config/mako/`, `omarchy/config/omarchy/hooks/`,
        `omarchy/config/omarchy/themes/` → their `src/home/config-shadow/...`
        mirrors. (The `.gitkeep` files are gone from the shadow
        in WU-1; the comment notes the directories stay for
        future Omarchy defaults.)
  - [ ] Header comment block (top of file, ~lines 1-15):
        `scripts/setup-omarchy` references stay (file is not
        renamed until WU-4). The `omarchy` references in
        comments are OK to leave until WU-4.
  - [ ] Log prefix `[setup-omarchy]` stays; rename happens in
        WU-4.
- [ ] **Critical**: do NOT touch the root `setup` dispatcher in
      this commit. The `SCRIPTS_DIR` change and the `--omarchy`
      → `--dots` flag rename in `setup` happen in WU-4 (after
      `scripts/` is `git mv`'d to `src/utils/bash/`).

**Verification**:
- [ ] `grep -n 'omarchy/config' scripts/setup-omarchy` returns
      zero hits.
- [ ] `grep -n 'src/home/config-shadow\|src/etc-shadow\|src/home/.ssh-shadow\|src/home/.bashrc-shadow' scripts/setup-omarchy`
      returns one hit per previous `omarchy/config/...`
      reference (sanity check: the count is roughly the same
      number of edits made).
- [ ] `git ls-files | grep cleanup.md` shows
      `docs/cleanup.md` and NOT `docs/ideas/scripts/cleanup.md`.
- [ ] `bash -n scripts/setup-omarchy` exits 0 (syntax check;
      no live run yet).
- [ ] Live system still untouched: `readlink -f ~/.config/...`
      still resolves to `omarchy/...` (no re-point yet).

**Rollback**: `git checkout -- scripts/setup-omarchy`. Doc move
revert is a `git mv docs/cleanup.md docs/ideas/scripts/cleanup.md`.

**Commit message**:
`refactor(scripts): point setup-omarchy at shadow paths`.

## Commit 3 — WU-3: Live re-point (no commit; live-only verification)

> "Re-point the 14 live symlinks from `omarchy/...` (or `shared/...`)
> to the shadow paths, with verification."
>
> This WU is the **only** step that touches the live system. The
> working tree change (the symlinks themselves) is not committed;
> the verification of the re-point is what we record. The next
> commit (WU-4) is the atomic rename that makes the shadow paths
> the canonical paths; the symlinks that now point at the shadow
> paths keep working because `git mv` is path-only (the resolved
> target stays the same inodes).

- [ ] **Dry-run check**:
  - [ ] `bash scripts/setup-omarchy --dry-run` — confirm the
        output lists exactly the 14 expected symlinks pointing
        to `src/home/config-shadow/...` (or the `*shadow` mirror
        for the special paths).
  - [ ] List of expected symlinks (14 entries, per the design's
        test plan and the `omarchy/README.md` managed-paths
        table):
        - `~/.config/nvim` → `src/home/config-shadow/nvim`
        - `~/.config/zellij` → `src/home/config-shadow/zellij`
        - `~/.config/hypr/hyprland.conf` → `src/home/config-shadow/hypr/hyprland.conf`
        - `~/.config/hypr/hypridle.conf` → `src/home/config-shadow/hypr/hypridle.conf`
        - `~/.config/hypr/p-bindings.conf` → `src/home/config-shadow/hypr/p-bindings.conf`
        - `~/.config/hypr/p-index.conf` → `src/home/config-shadow/hypr/p-index.conf`
        - `~/.config/hypr/p-looknfeel.conf` → `src/home/config-shadow/hypr/p-looknfeel.conf`
        - `~/.config/hypr/p-monitors.conf` → `src/home/config-shadow/hypr/p-monitors.conf`
        - `~/.config/hypr/p-rules.conf` → `src/home/config-shadow/hypr/p-rules.conf`
        - `~/.config/waybar/config.jsonc` → `src/home/config-shadow/waybar/config.jsonc`
        - `~/.config/alacritty/alacritty.toml` → `src/home/config-shadow/alacritty/alacritty.toml`
        - `~/.config/omarchy/themes/tokyo-night-autana` → `src/home/config-shadow/omarchy/themes/tokyo-night-autana`
        - `~/.config/starship.toml` → `src/home/config-shadow/starship.toml`
        - `~/.bashrc` → `src/home/.bashrc-shadow`
- [ ] **Real run**:
  - [ ] `bash scripts/setup-omarchy` — invokes
        `apply_symlinks()`, `install_input_devices()`,
        `seed_ssh_config()`. The function `ensure_symlink()` is
        idempotent: when the live symlink points to a different
        real path (`omarchy/...`), it replaces it with the new
        target (`src/home/config-shadow/...`).
- [ ] **Post-run verification** (each must pass):
  - [ ] `readlink -f ~/.config/nvim ~/.config/zellij ~/.config/hypr/{hyprland,hypridle,p-bindings,p-index,p-looknfeel,p-monitors,p-rules}.conf ~/.config/waybar/config.jsonc ~/.config/alacritty/alacritty.toml ~/.config/omarchy/themes/tokyo-night-autana ~/.config/starship.toml ~/.bashrc`
        resolves into `src/home/config-shadow/...` (and
        `src/home/.bashrc-shadow` for `~/.bashrc`). Capture the
        output for the verify-report.
  - [ ] `stat -c '%a' /etc/keyd/default.conf` reports `644`.
  - [ ] `cmp /etc/keyd/default.conf src/etc-shadow/keyd/default.conf`
        exits 0 (bit-identical).
  - [ ] `cat ~/.ssh/config` contains the SSH template content
        (copy-only-if-missing semantics; if the file already
        existed, the template is NOT overwritten — verify the
        existing content is preserved).
  - [ ] `systemctl is-active keyd ratbagd` reports `active` for
        both (or `inactive` if dry-run — the real run enables
        and starts them).
  - [ ] `hyprctl reload` exits 0.
  - [ ] `hyprctl configerrors` reports no errors (empty output).
  - [ ] `git grep '../../shared/'` in the working tree returns
        zero hits (the 3 relative symlinks are gone).
- [ ] **Failure path** (only if a verification check fails):
  - [ ] Stop immediately; do NOT proceed to WU-4.
  - [ ] Capture the failing check in the apply report.
  - [ ] Restore live symlinks: re-run `bash scripts/setup-omarchy`
        (the script is now editing from `src/home/config-shadow/...`
        targets; the re-point to shadow paths has already happened,
        so to revert the symlinks to `omarchy/...` would require
        a manual `git checkout` of the script to the pre-WU-2
        version, then a re-run).
  - [ ] Alternative simpler revert: just restore the 14 symlinks
        to point at `omarchy/...` with `ln -sfn` for each path,
        then `git checkout -- scripts/setup-omarchy` and remove
        the shadow dirs.
  - [ ] Confirm `readlink -f ~/.config/...` resolves into
        `omarchy/...` again.
  - [ ] Report the failure to the user; await instruction.

**Verification** (pass state only):
- [ ] All 14 symlinks point at shadow paths.
- [ ] `hyprctl configerrors` empty.
- [ ] `keyd` and `ratbagd` services active (or the run was a
      dry-run; document which).
- [ ] `git status` shows no tracked-file changes; the 14
      symlinks are working-tree changes that are NOT committed
      in this WU.

**Commit message**: **none** — this is a no-commit WU. The
working-tree symlink re-point is recorded in the verify report
and the apply report; the actual `git` change is the WU-4
commit.

## Commit 4 — WU-4: Atomic commit (rename shadow → final + rm old)

> "Atomically rename shadow paths to final paths, remove
> `omarchy/`, `shared/`, `scripts/`, and finalize the
> `setup-dots` script + root dispatcher flag rename."
>
> This is the **high-risk** commit. The shadow paths become the
> final paths in one atomic step. The 14 live symlinks (now
> pointing at the shadow paths from WU-3) keep working because
> `git mv` is path-only — the resolved targets (the inodes) are
> unchanged. The `apply_symlinks()` idempotency means a re-run
> is a no-op (the live symlink already points at the final
> path).

- [ ] `git mv src/home/config-shadow src/home/config`.
- [ ] `git mv src/home/.bashrc-shadow src/home/.bashrc`.
- [ ] `git mv src/home/local-shadow src/home/local`.
- [ ] `git mv src/home/.ssh-shadow src/home/.ssh`.
- [ ] `git mv src/etc-shadow src/etc`.
- [ ] `git mv src/README-shadow.md src/README.md`.
- [ ] `git mv scripts/setup-omarchy src/utils/bash/setup-dots`
      — file content edits land in this commit:
  - [ ] Update the script's path strings (still shadow paths
        after WU-2) to the final paths:
        `src/home/config-shadow/...` → `src/home/config/...`;
        `src/etc-shadow/...` → `src/etc/...`;
        `src/home/.ssh-shadow/...` → `src/home/.ssh/...`;
        `src/home/.bashrc-shadow` → `src/home/.bashrc`;
        `src/home/local-shadow/...` → `src/home/local/...`.
  - [ ] Update the header docstring: `scripts/setup-omarchy` →
        `src/utils/bash/setup-dots`; entrypoint reference
        `./setup --omarchy` → `./setup --dots`.
  - [ ] Update log prefix: `[setup-omarchy]` → `[setup-dots]`
        (3 occurrences: `log`, `warn`, `fail`).
  - [ ] Update internal references to `setup-deps` and
        `setup-fonts` invocations to use the new path
        `src/utils/bash/setup-deps` /
        `src/utils/bash/setup-fonts`.
  - [ ] The `--omarchy` flag passed to `setup-deps` in the
        sub-process invocation (current line 154,
        `local -a args=(--omarchy)`) changes to `--dots`
        per the flag rename.
  - [ ] The `monitor` comment near line 378:
        `src/home/local-shadow/bin/monitor` →
        `src/home/local/bin/monitor`.
- [ ] `git mv scripts/setup-deps src/utils/bash/setup-deps` —
      body is byte-identical except for the flag rename:
  - [ ] `Usage:` line near line 72:
        `Usage: $0 [--omarchy] [--dry-run] [--help]`
        → `Usage: $0 [--dots] [--dry-run] [--help]`.
  - [ ] The argument parser `case` arm near line 111:
        `--omarchy)` → `--dots)`.
  - [ ] Header docstring: `scripts/setup-deps` →
        `src/utils/bash/setup-deps`; entrypoint reference
        `./setup --omarchy` → `./setup --dots`.
  - [ ] The auto-detect comment near line 188
        `Detected env: $DOTFILES_ENV_LOCAL (no --omarchy passed)`
        → `Detected env: $DOTFILES_ENV_LOCAL (no --dots passed)`.
- [ ] `git mv scripts/setup-fonts src/utils/bash/setup-fonts` —
      body is byte-identical (no flag references; no docstring
      edits). The flag rename does not apply to `setup-fonts`.
- [ ] `git mv scripts/cleanup-omarchy src/utils/bash/cleanup` —
      file content edits:
  - [ ] Update the script's header docstring:
        `scripts/cleanup-omarchy` → `src/utils/bash/cleanup`.
  - [ ] Update the entrypoint reference: `./setup --omarchy`
        → `./setup --dots` (if present in the docstring).
  - [ ] Update log prefix `[cleanup-omarchy]` → `[cleanup]`
        (occurrences in `log` / `warn` / `fail` helpers).
- [ ] `git rm -r scripts/` — the directory is now empty (all
      4 files were `git mv`'d).
- [ ] `git rm omarchy/config/nvim omarchy/config/zellij omarchy/config/starship.toml`
      — the 3 relative symlinks that were `rm`'d from the
      filesystem in WU-1. (The `git rm` removes them from the
      index now that they no longer exist on disk.)
- [ ] `git rm -r omarchy/` — the wrapper folder; everything
      inside has been either moved to `src/` (via the shadow
      copy + WU-4 `git mv`) or is one of the 3 relative
      symlinks that were `git rm`'d above.
- [ ] `git rm -r shared/` — already absorbed into
      `src/home/config/` via WU-1 + WU-4 `git mv`.
- [ ] `setup` (root dispatcher, 247 lines) — apply these edits
      in this commit (after the `scripts/` rename so the
      dispatcher's `SCRIPTS_DIR` resolves correctly):
  - [ ] `SCRIPTS_DIR="$DOTFILES_ROOT/scripts"` →
        `SCRIPTS_DIR="$DOTFILES_ROOT/src/utils/bash"` (line 210
        area).
  - [ ] `target_script="$SCRIPTS_DIR/setup-omarchy"` →
        `target_script="$SCRIPTS_DIR/setup-dots"` (line 210).
  - [ ] All `--omarchy` references in the dispatcher (header
        docstring, usage text, parser arm, dispatch comments,
        examples) → `--dots`. Per `grep -- '--omarchy' setup`,
        the references are at lines 11, 14, 15, 22-24, 29, 37-42,
        78, 82, 86, 90, 93, 94, 100, 106-111, 120, 159, 203,
        205, 206, 237 (and any others found at apply time).
  - [ ] Header docstring: `scripts/setup-omarchy` →
        `src/utils/bash/setup-dots`; `scripts/setup-deps` →
        `src/utils/bash/setup-deps`; `scripts/setup-fonts` →
        `src/utils/bash/setup-fonts`.

**Verification** (post-commit):
- [ ] `git ls-files | grep -E '^(omarchy|shared|scripts)/'`
      returns empty (all three folders fully removed from the
      index).
- [ ] `git ls-files | grep -E '^src/' | head` shows the new
      tree (`src/home/config/`, `src/home/.bashrc`,
      `src/home/local/`, `src/home/.ssh/`, `src/etc/`,
      `src/utils/bash/{setup-dots,setup-deps,setup-fonts,cleanup}`,
      `src/README.md`).
- [ ] `readlink -f ~/.config/nvim ~/.config/zellij ~/.config/hypr/{hyprland,hypridle,p-bindings,p-index,p-looknfeel,p-monitors,p-rules}.conf ~/.config/waybar/config.jsonc ~/.config/alacritty/alacritty.toml ~/.config/omarchy/themes/tokyo-night-autana ~/.config/starship.toml ~/.bashrc`
      now resolves into `src/home/config/...` (NOT
      `src/home/config-shadow/...`; the shadow path is now the
      final path). Capture output.
- [ ] `cmp /etc/keyd/default.conf src/etc/keyd/default.conf`
      exits 0.
- [ ] `git grep '../../shared/'` returns zero hits.
- [ ] `grep -rn 'omarchy/config' src/utils/bash/setup-dots`
      returns zero hits (all path strings updated).
- [ ] `grep -rn -- '--omarchy' setup src/utils/bash/ docs/ AGENTS.md README.md openspec/config.yaml 2>/dev/null`
      returns zero hits (flag fully renamed in code + dispatcher;
      docs/AGENTS.md/README/openspec/config.yaml updated in WU-5;
      WU-4 grep is for the code+dispatcher only).
- [ ] `grep -rn 'cleanup-omarchy' src/utils/bash/ setup 2>/dev/null`
      returns zero hits.
- [ ] `bash -n src/utils/bash/setup-dots && bash -n src/utils/bash/setup-deps && bash -n src/utils/bash/setup-fonts && bash -n src/utils/bash/cleanup && bash -n setup`
      — all five scripts pass syntax check.
- [ ] `./setup --help` exits 0 and lists `--dots`, `--fonts`,
      `--deps`, `--dry-run`, `--help` / `-h` (no `--omarchy`).
- [ ] `bash src/utils/bash/setup-dots --help` exits 0 (sanity;
      shadow paths now resolve to final paths because the
      `git mv` made them canonical).

**Rollback**:
- [ ] `git revert HEAD` restores the `git mv` + `git rm` + script
      edits.
- [ ] **Critical**: after the revert, re-run
      `bash scripts/setup-omarchy` to re-point the 14 live
      symlinks back to `omarchy/...` paths. (The symlinks still
      point at the new paths because they were re-pointed in
      WU-3; the revert does NOT undo the live symlink change.)
- [ ] Verify `readlink -f ~/.config/...` resolves into
      `omarchy/...` again before considering the rollback
      complete.

**Commit message**:
`chore(repo): atomic rename to src/{home/{config,local},etc/} + src/utils/bash/`.

## Commit 5 — WU-5: Doc/config edits + verify

> "Align docs and `openspec/config.yaml` with the new layout;
> fix `AGENTS.md` line 55; run final verification."
>
> Scope: documentation and config files only. No code or script
> behavior change. The 14 live symlinks and the script bodies
> are already final after WU-4.

- [ ] **`AGENTS.md` (75 lines)**:
  - [ ] **Line 55 correction** (per Fork #4 + the proposal's
        Risks table): the current line "Hyprland / Mako / Waybar
        / Walker configs (omarchy-only, not shared)" is wrong —
        those configs ARE in the repo under
        `omarchy/config/{hypr,waybar,mako}/`. Rewrite the
        Forbidden Paths list to reflect the new structure:
        `~/.local/share/omarchy/` (omarchy installer-managed);
        `src/etc/` (system configs, sudo-install only); SSH
        private keys / `known_hosts`; machine-specific tokens.
        Remove the misleading "omarchy-only, not shared" line.
  - [ ] Update the "Main tools" row: `shared/` →
        `src/home/config/`.
  - [ ] Update the "Setup entrypoint" rule: "Env executors:
        `scripts/setup-<env>`" → "Env executors:
        `src/utils/bash/setup-dots`" (single env, no `<env>`
        suffix).
  - [ ] Update the "Canonical source" row: `shared/` →
        `src/home/config/`.
  - [ ] Update the "Sensitive SSH" row: `shared/home/.ssh/*` →
        `src/home/.ssh/*`.
- [ ] **`README.md` (61 lines)**:
  - [ ] Rewrite the "Repo layout" table:
        `<env>/home/.<dotfile>` → `src/home/.<dotfile>`;
        `<env>/config/<app>/` → `src/home/config/<app>/`;
        `<env>/bin/<name>` → `src/home/local/bin/<name>`;
        `scripts/` → `src/utils/bash/`;
        `omarchy/README.md` → `src/README.md`.
  - [ ] Update the env example: `omarchy/config/...` paths →
        `src/home/config/...` paths.
  - [ ] Update any "Setup on a new machine" step that references
        `omarchy/...` or `shared/...` paths.
- [ ] **`docs/conventions.md` (99 lines)**:
  - [ ] Update path examples in the "Repo layout" table.
  - [ ] Update path examples in the "Source of truth" table.
  - [ ] Update the runbook convention that references
        `omarchy/README.md` → `src/README.md`.
  - [ ] Section "Adding a new environment" — already removed
        by the prior `omarchy-only-scope` change; if the
        section was kept as a stub, drop it.
  - [ ] Update the "Cross-env canonical config" row: `shared/`
        → `src/home/config/`.
- [ ] **`docs/shared-layer.md` (81 lines)**: the doc's premise
      (a `shared/` layer) is now obsolete; rewrite to document
      the `src/home/config/` canonical layer:
  - [ ] Heading: `# shared/ layer` → `# src/home/config layer`.
  - [ ] Diagram: `~/.config/<x>/<f>  →  <env>/config/<x>/  →  ../../shared/<x>/`
        → `~/.config/<x>/<f>  →  src/home/config/<x>/`.
  - [ ] "Mapping" table: the env-path column becomes
        `src/home/config/`.
  - [ ] "Adding a new tool" example: drop the relative-symlink
        example; just describe "add the tool under
        `src/home/config/<tool>/`".
  - [ ] SSH exception paragraph: `shared/home/.ssh/config` →
        `src/home/.ssh/config`.
  - [ ] keyd exception paragraph: `omarchy/home/.config/keyd/default.conf`
        → `src/etc/keyd/default.conf`. Update the install
        command source: `scripts/setup-omarchy` →
        `src/utils/bash/setup-dots`.
  - [ ] Drop the "Do not place any of the following in
        `shared/`" section (the `shared/` folder is gone).
- [ ] **`docs/setup.md` (60 lines)**:
  - [ ] `./setup --deps` delegates to `scripts/setup-deps` →
        `src/utils/bash/setup-deps`.
  - [ ] `scripts/setup-deps --omarchy` → `src/utils/bash/setup-deps --dots`.
  - [ ] `scripts/setup-omarchy` → `src/utils/bash/setup-dots`.
  - [ ] `scripts/setup-deps` → `src/utils/bash/setup-deps`.
  - [ ] `scripts/setup-fonts` → `src/utils/bash/setup-fonts`.
- [ ] **`docs/hypr.md` (91 lines)**:
  - [ ] `omarchy/config/hypr/` → `src/home/config/hypr/`.
  - [ ] `omarchy/README.md` link → `src/README.md`.
  - [ ] The "Never edit files under `~/.local/share/omarchy/`"
        line stays (out of repo scope per `dotfiles/repo-scope`).
- [ ] **`docs/starship.md` (41 lines)**:
  - [ ] `shared/starship.toml` → `src/home/config/starship.toml`.
  - [ ] The "shared layer" reference → "canonical layer" or
        "src/home/config layer".
  - [ ] The symlink reference: `~/.config/starship.toml`
        symlinked to `shared/starship.toml` →
        `~/.config/starship.toml` symlinked to
        `src/home/config/starship.toml`.
- [ ] **`docs/bin.md` (46 lines)**:
  - [ ] Heading: `# User scripts (\`omarchy/local/bin/\`)`
        → `# User scripts (\`src/home/local/bin/\`)`.
  - [ ] `omarchy/local/bin/<name>` →
        `src/home/local/bin/<name>`.
  - [ ] The "Implementation" line for `monitor`.
- [ ] **`docs/nvim.md` (56 lines)**:
  - [ ] The LazyVim source description: `shared/nvim/`
        → `src/home/config/nvim/`.
  - [ ] The relative-symlink note (no longer accurate): drop
        the "exposed at runtime as a single folder symlink
        (`<env>/config/nvim/` → `shared/nvim/`)" sentence;
        replace with "exposed at runtime via the per-file
        symlink map in `src/utils/bash/setup-dots`".
  - [ ] The references to `shared/nvim/lazyvim.json`,
        `shared/nvim/lazy-lock.json`, `shared/nvim/lua/plugins/`,
        `shared/nvim/lua/config/`, `shared/nvim/plugin/after/transparency.lua`,
        `shared/nvim/markdownlint.json` → all use the
        `src/home/config/nvim/...` prefix.
- [ ] **`docs/ssh.md` (22 lines)**:
  - [ ] The `shared/home/.ssh/config` reference →
        `src/home/.ssh/config`.
- [ ] **`docs/wezterm.md` (36 lines)**:
  - [ ] The `omarchy/README.md#setup-on-a-new-machine` link
        (if present) → `src/README.md#setup-on-a-new-machine`.
- [ ] **`docs/zellij.md` (52 lines)**:
  - [ ] Any `shared/zellij/` or `omarchy/config/zellij/`
        references → `src/home/config/zellij/`.
- [ ] **`docs/git.md` (36 lines)**:
  - [ ] The `omarchy/README.md#setup-on-a-new-machine` link
        → `src/README.md#setup-on-a-new-machine`.
- [ ] **`docs/nvim-keymaps.md` (118 lines)** + **`docs/nvim/*.md`**:
      update any `shared/nvim/...` or `omarchy/config/nvim/...`
      references → `src/home/config/nvim/...`.
- [ ] **`docs/inputs/keyboard-remap.md` (99 lines)** +
      **`docs/inputs/mouse-g502.md` (91 lines)**:
  - [ ] `omarchy/home/.config/keyd/default.conf` →
        `src/etc/keyd/default.conf`.
  - [ ] `scripts/setup-omarchy` → `src/utils/bash/setup-dots`.
- [ ] **`docs/cleanup.md` (94 lines, moved in WU-2)**:
  - [ ] The path examples inside that reference
        `scripts/cleanup-omarchy` → `src/utils/bash/cleanup`.
  - [ ] The doc was moved from `docs/ideas/scripts/cleanup.md`;
        cross-references in other docs that point at the old
        path → `docs/cleanup.md`.
- [ ] **`src/README.md` (64 lines, renamed from `omarchy/README.md`)**:
  - [ ] The managed-paths table (lines 34-49 in the original):
        every `omarchy/config/...` source → `src/home/config/...`;
        `omarchy/home/.bashrc` → `src/home/.bashrc`;
        `shared/home/.ssh/config` → `src/home/.ssh/config`;
        `omarchy/local/bin/monitor` → `src/home/local/bin/monitor`.
  - [ ] The `omarchy theme set tokyo-night-autana` line stays
        (Omarchy CLI command, not a repo path).
  - [ ] The "Do not run `omarchy refresh`" line stays
        (Omarchy CLI command).
  - [ ] The `install -m 600 shared/home/.ssh/config ~/.ssh/config`
        example (line 55) → `install -m 600 src/home/.ssh/config ~/.ssh/config`.
- [ ] **`openspec/config.yaml` (104 lines)**:
  - [ ] Rewrite the `context:` block to reflect the new
        layout: `src/{home/{config,local},etc/}` +
        `src/utils/bash/`. Drop any env-2 references (the
        `omarchy-only-scope` change already removed them;
        this is a sanity check).
  - [ ] Update any `rules:` block examples that reference
        old paths.
- [ ] **Spec delta placement** (no content edit, just
      verification):
  - [ ] The spec delta at
        `openspec/changes/repo-structure-omarchy-reorg/specs/setup-orchestration/spec.md`
        stays in the change folder. The `sdd-archive` phase
        (post-merge) merges it into
        `openspec/specs/setup-orchestration/spec.md`.

**Verification** (final):
- [ ] **`TAP harness`** (unchanged per Fork #5):
      `bash tests/setup-deps.bash` exits 0 and reports
      `5/5 passed` (T1, T2, T4, T5, T6).
- [ ] **Hyprland reload clean**:
      `hyprctl reload && hyprctl configerrors` reports no
      errors.
- [ ] **Live symlinks (re-asserted)**:
      `readlink -f ~/.config/{nvim,zellij,hypr/{hyprland,hypridle,p-bindings,p-index,p-looknfeel,p-monitors,p-rules}.conf,waybar/config.jsonc,alacritty/alacritty.toml,omarchy/themes/tokyo-night-autana,starship.toml} ~/.bashrc`
      resolves into `src/home/config/...` and `src/home/.bashrc`.
- [ ] **`docs/cleanup.md` exists**:
      `git ls-files | grep docs/cleanup.md` returns
      `docs/cleanup.md`.
- [ ] **`docs/ideas/scripts/cleanup.md` is gone**:
      `git ls-files | grep docs/ideas/scripts/cleanup.md`
      returns empty.
- [ ] **`AGENTS.md` line 55 fix**: `grep -n 'not shared' AGENTS.md`
      returns zero hits. `grep -n 'omarchy-only' AGENTS.md`
      returns zero hits (the misleading wording is gone).
- [ ] **No stale `setup-omarchy` / `cleanup-omarchy` / `omarchy/config/` / `shared/` / `scripts/setup-` references in code or docs**:
      `git grep -nE 'setup-omarchy|cleanup-omarchy|omarchy/config|shared/home|scripts/setup' -- ':!openspec/changes/archive' ':!openspec/changes/repo-structure-omarchy-reorg/proposal.md' ':!openspec/changes/repo-structure-omarchy-reorg/specs'`
      returns zero hits outside the proposal/spec delta and
      the archive. (The proposal and spec intentionally keep
      the old names in `(Previously: ...)` annotations.)
- [ ] **No stale `--omarchy` flag in code or docs**:
      `git grep -n -- '--omarchy' -- ':!openspec/changes/archive' ':!openspec/changes/repo-structure-omarchy-reorg/proposal.md' ':!openspec/changes/repo-structure-omarchy-reorg/specs'`
      returns zero hits outside the proposal/spec delta and
      the archive.
- [ ] **No `../../shared/` in working tree**:
      `git grep -n '\.\./\.\./shared/' -- ':!openspec/changes/archive'`
      returns zero hits.
- [ ] **Archived changes byte-identical**:
      `git status openspec/changes/archive/` shows no edits.
      The five archived change folders
      (`2026-06-14-ideas-implementation`,
      `2026-06-16-cleanup-omarchy`,
      `2026-06-17-input-devices-config`,
      `2026-06-17-setup-deps-batch-install`,
      `2026-06-18-omarchy-only-scope`) are byte-identical to
      before this change. No retroactive edits to historical
      artifacts.
- [ ] **All scripts syntax-clean**:
      `bash -n setup && bash -n src/utils/bash/setup-dots && bash -n src/utils/bash/setup-deps && bash -n src/utils/bash/setup-fonts && bash -n src/utils/bash/cleanup`
      exits 0.
- [ ] **Work-unit commit log**:
      `git log --oneline -7` shows the six commits in order
      (commit 0 planning, WU-1 shadow, WU-2 scripts, WU-3
      no-commit, WU-4 atomic, WU-5 docs). The Conventional
      Commit prefixes match the design.

**Rollback** (revert all five work-unit commits):
- [ ] `git revert <commit 5>..<commit 1>` (revert the work
      units in reverse order).
- [ ] After the revert, re-run `bash scripts/setup-omarchy`
      to re-point the 14 live symlinks back to `omarchy/...`
      paths (the revert does NOT undo the live symlink
      change; only the file-system changes are reverted).
- [ ] Verify `readlink -f ~/.config/...` resolves into
      `omarchy/...` again.

**Commit message**:
`docs(repo): align docs with src/ layout + AGENTS.md forbidden-paths fix`.

## Verify phase (post-commits, pre-PR)

> Run after all five work-unit commits land but before opening
> the PR. Records the verify-report content. Many of the
> verification checks are already in WU-5 above; this section
> adds the cross-cutting checks.

- [ ] **Tracked-surface scan (extended)**:
      `git grep -nE 'omarchy/config|shared/home|shared/nvim|shared/zellij|shared/starship|scripts/setup|scripts/cleanup|setup-omarchy|cleanup-omarchy|--omarchy' -- ':!openspec/changes/archive' ':!openspec/changes/repo-structure-omarchy-reorg/proposal.md' ':!openspec/changes/repo-structure-omarchy-reorg/specs'`
      returns zero hits in tracked code, config, or docs
      outside the proposal/spec delta and the archive. The
      archive exception is the only place old names still
      appear.
- [ ] **`git ls-files` summary**:
      `git ls-files | grep -E '^(omarchy|shared|scripts)/'`
      returns empty.
      `git ls-files | grep -E '^src/'` shows the new tree.
- [ ] **`apply_symlinks` path-source audit** (no more
      `omarchy/...` in the new script):
      `grep -n 'REPO_ROOT/omarchy' src/utils/bash/setup-dots`
      returns zero hits.
      `grep -n 'REPO_ROOT/src/home/config-shadow' src/utils/bash/setup-dots`
      returns zero hits (shadow path strings are gone from
      the final script).
- [ ] **`--dots` propagation**: `grep -n -- '--dots' src/utils/bash/setup-dots src/utils/bash/setup-deps setup`
      shows the new flag in all three locations (root
      dispatcher, env script, deps script).
- [ ] **No `~/.config/keyd/` symlink**:
      `readlink -f ~/.config/keyd` returns ENOENT (the symlink
      does not exist; keyd reads `/etc/keyd/default.conf` only).
- [ ] **`src/home/config/{mako,omarchy/hooks,omarchy/themes}/`**
      contain no `.gitkeep` files
      (`find src/home/config -name .gitkeep` returns empty).
- [ ] **TAP harness re-asserted**:
      `bash tests/setup-deps.bash` exits 0 and reports
      `5/5 passed`.
- [ ] **Hyprland reload re-asserted**:
      `hyprctl reload && hyprctl configerrors` is empty.
- [ ] **Live symlinks re-asserted**:
      `readlink -f` on each of the 14 paths resolves into
      `src/home/config/...` (and `src/home/.bashrc` for
      `~/.bashrc`).
- [ ] **Archived changes byte-identical**:
      `git status openspec/changes/archive/` shows no edits.
- [ ] **Main spec byte-identical** (pre-archive):
      `git status openspec/specs/` shows no edits. The spec
      delta merge is the `sdd-archive` phase.

### Verify-report content (the `sdd-verify` output)

- [ ] **Live-system smoke evidence**: capture the output of
      `readlink -f` on each of the 14 symlinks (post-WU-4 and
      post-WU-5); capture `hyprctl configerrors` output;
      capture `systemctl is-active keyd ratbagd` output;
      capture the TAP harness `5/5 passed` summary.
- [ ] **Apply phase notes**:
  - [ ] A one-paragraph note explaining the shadow-copy
        sequencing (WU-1 → WU-2 → WU-3 → WU-4) and why it
        was chosen over a direct `git mv` (the design
        Decision 1 rationale).
  - [ ] A one-line note per work-unit commit summarizing
        what landed and the verification result.
- [ ] **Archived-changes note**: a one-paragraph note at
      the top of the verify-report's findings section
      explaining that `openspec/changes/archive/*` still
      mentions `omarchy/...`, `shared/...`, and `scripts/...`
      paths (the archived change folders predate this
      reorg), and that they are preserved on purpose per
      the SDD archive policy. The note is for future
      readers (and future agents) who would otherwise
      misread the current contract from the archive
      history.
- [ ] **`tmux.conf` `# Reason:` wording check**: re-read
      `src/home/config/tmux/tmux.conf` after WU-4 to
      confirm the comment matches actual content. If the
      file was modified between the proposal and the apply
      phase, the verify-report records the actual file
      state and the final comment text.
- [ ] **`AGENTS.md` line 55 fix**: quote the new Forbidden
      Paths section in the verify-report so future readers
      can grep for "not shared" / "omarchy-only" and
      confirm the fix.

## Archive task (post-merge, NOT part of the PR)

Per the `archive:` rule in `openspec/config.yaml`, the spec
delta is merged into the main spec and the change folder is
archived. This happens AFTER the PR is merged; it is the
`sdd-archive` phase, not the `sdd-apply` phase.

- [ ] `sdd-archive` merges the delta at
      `openspec/changes/repo-structure-omarchy-reorg/specs/setup-orchestration/spec.md`
      into `openspec/specs/setup-orchestration/spec.md` and
      removes the delta block from the change folder. The
      merge removes:
  - [ ] The 11 MODIFIED requirement blocks (replaces old
        paths with new paths; preserves all scenarios).
  - [ ] The `### Purpose` and `### Quick path` heading
        blocks (replaces env-script name and paths).
  - [ ] The `DOTFILES_ENV` row in the variable contract
        table stays **byte-identical** (omarchy-only-scope
        resolution; not a path; not affected by the reorg).
- [ ] `git mv openspec/changes/repo-structure-omarchy-reorg
      openspec/changes/archive/2026-06-18-repo-structure-omarchy-reorg`.
- [ ] The five pre-existing archived change folders
      (`2026-06-14-ideas-implementation`,
      `2026-06-16-cleanup-omarchy`,
      `2026-06-17-input-devices-config`,
      `2026-06-17-setup-deps-batch-install`,
      `2026-06-18-omarchy-only-scope`) remain
      byte-identical to before this change. No retroactive
      edits to historical artifacts.

## Out of scope (do not implement in this change)

- Modifying any tracked tool config content
  (`alacritty.toml`, `hyprland.conf`, `nvim/...`,
  `zellij/...`, `starship.toml`, `keyd/default.conf`,
  etc.) — the reorg is path-only; tool config semantics
  stay intact.
- Changing the symlink contract semantics (e.g.,
  per-app vs per-file, p-prefix handling) — the
  `p-` prefix semantic is unchanged; `~/.config/hypr/`
  stays the only path Omarchy's updater sees.
- Editing `~/.local/share/omarchy/` or any per-host
  secrets (SSH private keys, `known_hosts`,
  machine-specific tokens) — out of repo scope per
  `dotfiles/repo-scope`.
- Editing the `backup/` folder — the per-run backup
  folder stays untouched; old logs are historical.
- Tweaking the unknown-flag error message in
  `setup` or in the env script — the existing
  "Unknown argument: $1" + usage contract is the
  rejection path.
- Re-adding TAP tests for `setup-dots` behaviors —
  `tests/setup-deps.bash` stays unchanged per Fork
  #5; the verify-report records any lost scenario
  coverage (none expected; the existing 5 tests
  exercise the renamed scripts transparently).
- Editing the unrelated `openspec/changes/cleanup-omarchy/`
  change — that change has been archived to
  `openspec/changes/archive/2026-06-16-cleanup-omarchy/`
  and is byte-identical to before this change.
- Editing any of the five pre-existing archived change
  folders — they remain byte-identical per SDD archive
  policy.

## Notes for the apply phase

- **PR strategy confirmation**: the design recommends three
  chained PRs (WU-1+WU-2 → WU-3+WU-4 → WU-5). Confirm
  with the user before opening any PR. The pre-flight
  section above captures the decision point.
- **Live-system discipline**: WU-3 is the only WU that
  touches the live system. The apply phase should run
  WU-3 in a focused session with the user present, so
  any failure can be addressed immediately. Do NOT
  batch WU-3 with WU-4 in a long unattended run.
- **`tmux.conf` wording check**: re-read the file at
  WU-1 commit time (before adding the `# Reason:`
  comment) and again at WU-5 verify time (after the
  rename). If the content has drifted from the
  97-line personal config described in the proposal,
  the comment must be amended to match.
- **Apply report**: the apply phase produces a
  standalone report (NOT the verify-report) that
  captures the work-unit sequence, the WU-3 live
  re-point evidence, and any deviations from this
  task plan. The verify-report is the next phase's
  output.
