# Proposal: setup-deps — single-pass batch install

## Why

`scripts/setup-deps` runs one PM process per missing package. AUR
calls spawn a fresh `yay` summary and may prompt per-package for
PKGBUILD diff/edit/clean; Fedora can trigger an independent `sudo`
per missing package. A fresh Omarchy host pays N processes, N AUR
prompts, up to N sudo escalations. One install per env collapses the
sudo cost and the install-confirmation count.

## What changes

| Kind | Path | Notes |
| --- | --- | --- |
| Modified | `scripts/setup-deps` | Build `MISSING=()` first; run ONE install per env. Keep per-pkg `[ok]`/`[miss]` lines. Summary becomes `installed/present/missing`. Empty list → log "all present", exit 0. Abort on first error. |
| Modified | `tests/setup-deps.bash` | Extend T7 sub-cases A and B: install command invoked ONCE with all missing packages as args. |
| Modified | `docs/setup.md` | Note single-pass install per env. |
| New (delta) | `openspec/changes/setup-deps-batch-install/specs/setup-orchestration/spec.md` | Delta spec; merges at archive. |
| Modified (delta) | `openspec/specs/setup-orchestration/spec.md` | Merged target at archive. |

No new capability. `setup-orchestration` is the only modified one.

## Scope (in)

- Symmetric for both envs (Omarchy + Fedora).
- Consolidated install line: `[setup-deps] Installing N missing: a b c`.
- All-present early-exit logs "all present" and exits 0.
- Fedora: rely on the single `sudo dnf install` for the password
  prompt; no upfront `sudo -v`.

## Scope (out)

- `--yes` / `-y` opt-in → deferred follow-up change.
- Re-detection of package lists at runtime.
- Pacman `--noconfirm` on Fedora.
- Audit log; per-run progress stays on stdout.

## Approach

1. Iterate the env package list, call `pkg_installed` per pkg,
   append missing to `MISSING=()`.
2. Empty `MISSING=()`: log "all present", exit 0.
3. Else: log the consolidated `[miss]` list once, run ONE install
   per env with `"${MISSING[@]}"` as args.
4. Dry-run: emit the consolidated command line, exit 0.
5. Real mode: require the env's PM up front (current behavior), run
   the consolidated command, log the final summary.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `setup-orchestration`: the `setup-deps install flow` requirement
  changes from per-pkg to one-install-per-env with all missing
  packages as args; abort on first error; consolidated summary.

## Affected Areas

| Area | Impact | Description |
| --- | --- | --- |
| `scripts/setup-deps` | Modified | New `MISSING=()` collection; single install call per env; consolidated log line; final `installed/present/missing` summary. |
| `tests/setup-deps.bash` | Modified | T7 sub-cases A and B get new assertions: exactly one install line with all missing packages as args, per-pkg `[miss]` lines still emitted. |
| `docs/setup.md` | Modified | One paragraph in Dependency Detection noting single-pass install per env. |
| `openspec/specs/setup-orchestration/spec.md` | Delta | Adds the "single-pass batch install" requirement; archive merges it. |

## Risks

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| Mid-batch AUR build failure inside `yay -S --needed a b c` — does it abort the rest? | Med | Per `yay` semantics, build failure aborts the build queue. `set -euo pipefail` propagates non-zero exit. Matches "abort on first error". |
| Test fixture needs invocation count assertions | Low | T7 already drives the script with stubbed PMs; extend stub log to assert exactly one install line with all args. |

## Rollback Plan

Revert `scripts/setup-deps` to the per-pkg install loop (git-tracked).
Revert the delta in `openspec/specs/setup-orchestration/spec.md`.
Restore T7 to its pre-extension form. Remove the `docs/setup.md`
paragraph. Stateless; no runtime state to clean up.

## Dependencies

- `yay` for the install command; no version-specific flags used in this change.
- `dnf` for Fedora; no flag changes.

## Decisions already made (locked, do NOT re-litigate)

1. **Scope**: BOTH envs. Symmetric.
2. **AUR PKGBUILD prompts**: NOT suppressed in this change. The
   Omarchy install command is plain `yay -S --needed`. A single
   `yay` invocation already coalesces the install confirmation
   ("Proceed with installation? [Y/n]") to once, regardless of
   package count. PKGBUILD edit/diff prompts remain at `yay`
   defaults. If those prompts need suppression in the future, that
   is a separate change.
3. **Mid-batch failure**: abort on first error; preserve
   `set -euo pipefail`. Do NOT collect-and-report.
4. **`--yes` / `-y` opt-in**: deferred to a follow-up change.

## Open items for the design phase

- Exact log format for the consolidated install line.
- Whether T7 extension with sub-cases is enough or a separate T8 is
  cleaner (orchestrator leans toward "extend T7 with sub-cases").

## Success Criteria

- [ ] `setup-deps --dry-run --omarchy` (≥ 2 missing) emits ONE
  `yay -S --needed` line with all missing packages, plus per-pkg
  `[miss]` lines, exits 0.
- [ ] `setup-deps --dry-run --fedora` (≥ 2 missing) emits ONE
  `sudo dnf install -y` line with all missing packages, plus
  per-pkg `[miss]` lines, exits 0.
- [ ] All-present run logs "all present" and exits 0 without
  invoking `yay` or `dnf`.
- [ ] Mid-batch failure propagates non-zero exit; subsequent items
  are not installed.
- [ ] `bash tests/setup-deps.bash` passes all 7+ tests; new
  assertions cover the "one install call, all args" contract for
  both envs.
- [ ] `docs/setup.md` reflects the new behavior.
