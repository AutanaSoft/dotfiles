# Design: setup-deps — single-pass batch install

## Technical Approach

Two-phase refactor of the install loop in `scripts/setup-deps`:
(1) iterate the env package list and collect every missing package
into `MISSING=()`, preserving per-package `[ok]` / `[miss]` log
lines; (2) emit one consolidated install line and invoke the env's
PM exactly once with `"${MISSING[@]}"`. Omarchy uses the plain
`yay -S --needed` command (no AUR flag suppression in this change).
The Fedora contract — one `sudo` per run — is preserved by relying
on the single `sudo dnf install -y` call. Auto-detection, overrides,
and `--help` are not refactored.

## Architecture Decisions

### Decision: T8 (new) vs extend T7

**Choice**: New `T8` for batch install. `TEST_PLAN` 7 → 8.

**Why**: T7 is "auto-detect". Mixing in "exactly one install call"
muddles its contract. T7's existing A–E keep passing because the
new code still emits `yay -S --needed` / `sudo dnf install -y`
substrings (one line, full command). T8 isolates the new behavior
with a clean name. Matches the spec's "Minimum TEST_PLAN=8".

| Sub | What | Stub shape | Assertion |
| --- | --- | --- | --- |
| A | All present | `pacman`/`rpm` exit 0 | `all present` in output; no install line in stub log |
| B | Single missing, Omarchy | `pacman` exits 1 | exactly ONE `yay -S --needed` line; per-pkg `[miss]` present |
| C | ≥ 2 missing, Omarchy | `pacman` exits 1 | exactly ONE `yay -S --needed` line containing all missing pkgs as args |
| D | ≥ 2 missing, Fedora | `rpm` exits 1 | exactly ONE `sudo dnf install -y` line with all pkgs; no `sudo -v` |
| F | Failure aborts | `pacman` exits 1, `yay` exits 7 | exit 7; exactly ONE `yay` invocation; no final summary line |

All sub-cases use `env -i PATH="$stubs:$utils_dir"` to keep host
PMs (dev box is Omarchy: `yay`/`pacman` on `/usr/bin`) out of
assertions. Reuses `make_pm_stubs` and `make_minimal_utils_dir`
from T7.

### Decision: Refactor shape

New `collect_missing()` and `install_batch()` functions. `main`
shrinks to a linear sequence. Old `pm_install_cmd` /
`install_package` are commented out with `# Reason: replaced by
install_batch in change setup-deps-batch-install` (repo convention).

### Decision: All-present early-exit

When `MISSING=()` is empty, log `All N packages present; nothing to
install.` and `exit 0` BEFORE the install call. The final summary
is NOT emitted in this path (nothing was installed). The spec
scenario is explicit: "exits 0 and the env's install command is
NOT invoked."

## Data Flow

```
main
  ├─ env detection (existing)
  ├─ packages = OMARCHY_PACKAGES | FEDORA_PACKAGES
  ├─ log "Checking N package(s)..."
  ├─ collect_missing packages → fills MISSING=(); counts [ok]/[miss]
  ├─ if [ ${#MISSING[@]} -eq 0 ]: log "All N packages present…"; exit 0
  ├─ log "Installing ${#MISSING[@]} missing: ${MISSING[*]}"
  ├─ install_batch                # ONE process; set -e propagates failure
  │     dry-run → log "[dry-run] would run: $cmd"; return 0
  │     real    → require_command yay|dnf; $cmd
  ├─ log "Summary: X installed, Y present, Z missing."
  └─ log "Setup complete."
```

## File Changes

| File | Action | Description | Est. lines |
| --- | --- | --- | --- |
| `scripts/setup-deps` | Modify | Add `MISSING=()`; new `collect_missing` / `install_batch`; all-present early-exit; consolidated log; `installed/present/missing` summary. Keep auto-detect, overrides, help, env-var passthrough, dry-run. | +60 / −20 (net +40) |
| `tests/setup-deps.bash` | Modify | `TEST_PLAN=8`. Add T8 sub-cases A–F. Reuse `make_pm_stubs` and `make_minimal_utils_dir`. T1–T7 unchanged. | +130 / 0 |
| `docs/setup.md` | Modify | Two-sentence note in "Dependency Detection": single-pass install per env; Fedora sudo coalesces. | +6 / 0 |
| `openspec/changes/setup-deps-batch-install/design.md` | Create | This file. | new (~150) |

## Interfaces / Contracts

```bash
collect_missing() {
    local pkg
    for pkg in "$@"; do
        if pkg_installed "$pkg"; then
            log "  [ok]   $pkg"; installed=$((installed + 1))
        else
            log "  [miss] $pkg"; MISSING+=("$pkg"); missing=$((missing + 1))
        fi
    done
}

install_batch() {
    local cmd
    case "$DOTFILES_ENV_LOCAL" in
        omarchy) cmd="yay -S --needed ${MISSING[*]}" ;;
        fedora)  cmd="sudo dnf install -y ${MISSING[*]}" ;;
    esac
    [[ "$DRY_RUN" -eq 1 ]] && { log "[dry-run] would run: $cmd"; return 0; }
    case "$DOTFILES_ENV_LOCAL" in
        omarchy) command -v yay >/dev/null 2>&1 || fail "yay is not on PATH…" ;;
        fedora)  command -v dnf >/dev/null 2>&1 || fail "dnf is not on PATH…" ;;
    esac
    log "Running: $cmd"; $cmd
}
```

## Testing Strategy

| Layer | What | Approach |
| --- | --- | --- |
| Bash TAP | T8 sub-cases A–D, F | Stub PMs; assert exactly one install line with all args; assert no `sudo -v`; assert failure aborts. |
| Regression | T1–T7 | Unchanged. T7 greps `yay -S --needed` / `sudo dnf install -y`; the new code still emits those substrings. |
| Manual smoke | Fresh Omarchy box | One install confirmation prompt for a multi-pkg batch install. |
| Manual smoke | Fedora box (best-effort) | ONE sudo prompt for the whole run. CI/dev host is Omarchy; Fedora verified by T8 sub-case D. |

## Risk Register

| Risk | L | I | Mitigation |
| --- | --- | --- | --- |
| Stub log doesn't capture batch arg order | M | M | Sub-cases C and D assert pkgs as substrings (not strict order). |
| `MISSING[*]` unquoted expansion breaks with spaces | L | H | Repo package lists have no spaces; use `"${MISSING[@]}"` (array) in the actual exec line. |
| Manual Fedora smoke requires a VM | M | L | Best-effort; T8 sub-case D is the primary Fedora contract check. |

## Open Questions for sdd-tasks

- **TEST_PLAN granularity**: 8 (T8 holds all batch-install scenarios)
  or 9 (split T8 = batch install, T9 = AUR flag set)? Spec minimum
  is 8. `sdd-tasks` picks what keeps the test diff under ~130 lines.
- **`Installing N missing:` exact wording**: design commits to
  `Installing ${#MISSING[@]} missing: ${MISSING[*]}`. T8 sub-case C
  asserts pkgs in stub log; wording is diagnostic, not load-bearing.
