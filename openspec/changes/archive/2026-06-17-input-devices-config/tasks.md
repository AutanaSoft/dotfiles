# Tasks: input-devices-config (keyd + piper, Omarchy-only)

> **Locked**: Omarchy-only. keyd v2.6 `noop` (not `clear`). Piper profiles NOT in repo. Service enable in `scripts/setup-omarchy` (no `sudo -v`). `[ids] *` scope.

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~250 (implementation diff) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Decision needed before apply | No |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low

Units 1→2→3 sequential; Unit 4 independent. Single PR scope.

## Work Unit 1: Package install + TAP test (coupled)

- **Files**: `scripts/setup-deps` (line 61-68); `tests/setup-deps.bash` (line 1194-1196).
- **Tasks**:
  - 1.1 Append `keyd`, `piper`, `libratbag` (with `# provides: ratbagd`) to END of `OMARCHY_PACKAGES=()`. `FEDORA_PACKAGES` byte-identical.
  - 1.2 Extend `omarchy_pkgs=(...)` in T8 sub-case C with the three names.
  - 1.3 Add lockstep comment above the test array.
- **Acceptance**: `bash tests/setup-deps.bash` → `8/8 passed`; T8 D byte-identical; dry-run yay line lists all three names.
- **Coupling**: test array mirrors source.

## Work Unit 2: keyd config file

- **Files**: `omarchy/home/.config/keyd/default.conf`.
- **Tasks**:
  - 2.1 Author header (purpose, `sudo keyd reload`, VID:PID via `sudo keyd monitor`) + body:
    ```ini
    [ids]
    *
    [main]
    volumeup    = noop
    volumedown  = noop
    up          = pagedown
    ```
  - 2.2 Verify exact `check` flag via `man keyd` on live host.
- **Acceptance**: file exists with body; `clear` not used; `keyd -c <path> check` returns 0.

## Work Unit 3: setup-omarchy new step

- **Files**: `scripts/setup-omarchy`.
- **Tasks**:
  - 3.1 Add `install_input_devices()` per design §3.4 (dry-run + live): `install -m 644` repo→`/etc/keyd/default.conf`; `sudo systemctl enable --now keyd ratbagd`.
  - 3.2 Wire as Step 4/5 between `apply_symlinks` and `validate_system` via `step "..."`. Wording: `"Install keyd config and enable input-device services"`.
  - 3.3 Bump `TOTAL_STEPS` 4 → 5 at line 426.
  - 3.4 Block comment above function: first sudo service-enable in env flow; timestamp cache coalesces both calls; no `sudo -v`.
- **Acceptance**: dry-run emits both preview lines, no mutation; live mode creates `/etc/keyd/default.conf` (mode 0644) and enables both services in one coalesced sudo burst; `apply_symlinks` does NOT add `~/.config/keyd/` symlink. Live: `ls -l /etc/keyd/default.conf`, `systemctl is-enabled keyd ratbagd`, `sudo keyd reload`.

## Work Unit 4: Docs (three coupled)

- **Files**: `docs/inputs/keyboard-remap.md`; `docs/inputs/mouse-g502.md`; `docs/shared-layer.md`.
- **Tasks**:
  - 4.1 Create `docs/inputs/keyboard-remap.md` (cognitive-doc-design shape). Cover: config location, `sudo keyd reload`, `sudo keyd monitor` / `sudo keyd -V`, VID:PID migration. ≤120 lines.
  - 4.2 Create `docs/inputs/mouse-g502.md` (same shape). Cover: Default + Game profiles with binding table; "NOT version-controlled" caveat (firmware via DBus); Piper recreation steps; install notes. ≤120 lines.
  - 4.3 Add `### Exception: /etc/keyd/default.conf install pattern` to `docs/shared-layer.md` under `## SSH template exception`. Mirror SSH tone: Omarchy-only, copy-not-symlink, repo source.
- **Acceptance**: all three files exist; keyboard covers location + reload + VID:PID; mouse lists Default + Game with bindings AND states profiles on firmware; shared-layer has new paragraph scoped to Omarchy. Verify: `grep -c 'usb:VID:PID' docs/inputs/keyboard-remap.md` (≥1); `grep -iE 'firmware|not version-controlled' docs/inputs/mouse-g502.md`; `grep -A 2 'keyd/default.conf' docs/shared-layer.md`.
- **Coupling**: reviewers read all three together; ship in one commit.