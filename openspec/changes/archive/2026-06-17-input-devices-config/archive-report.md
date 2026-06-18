# Archive Report: input-devices-config (Omarchy-only)

**Change**: `input-devices-config`
**Archived at**: 2026-06-17
**Archived by**: `sdd-archive`
**Artifact store**: `openspec`
**Verification reference**: `openspec/changes/archive/2026-06-17-input-devices-config/verify-report.md`

---

## Summary

Archived `input-devices-config`, adding keyd keyboard remap (VolUp/VolDown silenced via `noop`, broken Up→PageDown) and Piper G502 mouse setup for Omarchy-only. Delta spec merged into `openspec/specs/setup-orchestration/spec.md` (5 requirements, 17 scenarios). 14/17 PASS in verify; 3 DEFERRED to live Omarchy host. Sign-off: **GO**.

---

## Change Metadata

| Field | Value |
|-------|-------|
| Change name | `input-devices-config` |
| Date archived | 2026-06-17 |
| Scope | Omarchy-only (Hyprland + Arch) |
| Pace | interactive |
| Artifact store | openspec (B1) |
| PR strategy | single-pr (C2) |
| Review budget | 800 lines (D2) |
| Delivery strategy | single-pr (locked) |

### Locked Decisions (from proposal, rev 2)

1. Scope is Omarchy-only.
2. Service enable runs from `scripts/setup-omarchy` (not `setup-deps`).
3. Shared-layer exception for `/etc/keyd/default.conf` (privileged copy, not symlink).
4. `[ids] *` in keyd config (universal scope; VID:PID migration in runbook).
5. `noop` for VolUp/VolDown (per keyd v2.6 Example 8; not `clear`).
6. Piper profiles NOT in the repo (live on mouse firmware via DBus).

---

## Files Changed

7 files touched by apply (4 modified + 3 untracked):

| Path | Kind | Line count |
|------|------|-----------|
| `docs/shared-layer.md` | modified | +19 lines (new exception paragraph) |
| `scripts/setup-deps` | modified | +4 lines (3 packages + comment) |
| `scripts/setup-omarchy` | modified | ~40 lines (new `install_input_devices` function, Step 4/5 wiring) |
| `tests/setup-deps.bash` | modified | +4 lines (T8 sub-case C array extension) |
| `docs/inputs/keyboard-remap.md` | new | 99 lines |
| `docs/inputs/mouse-g502.md` | new | 91 lines |
| `omarchy/home/.config/keyd/default.conf` | new | ~55 lines |

---

## Spec Merge

**Delta spec**: `openspec/changes/archive/2026-06-17-input-devices-config/specs/setup-orchestration/spec.md`
**Main spec**: `openspec/specs/setup-orchestration/spec.md`

5 ADDED requirements, 17 scenarios merged. The `Documentation and test coverage` requirement at the bottom of the main spec was preserved unchanged (the delta's Req 5 adds new doc requirements as a separate requirement, not modifying the existing one).

| # | Requirement | Scenarios | Added before |
|---|-------------|-----------|--------------|
| 1 | Input-devices packages (Omarchy only) | 4 | `Documentation and test coverage` |
| 2 | TAP test coverage for the input-devices packages | 2 | `Documentation and test coverage` |
| 3 | keyd config file in the Omarchy repo layer | 4 | `Documentation and test coverage` |
| 4 | setup-omarchy installs the keyd config and enables input-device services | 4 | `Documentation and test coverage` |
| 5 | Docs cover the input-devices workflow and the shared-layer exception | 3 | `Documentation and test coverage` |

Main spec grew from 389 → 566 lines. All existing requirements preserved.

---

## Verification Status

- **Tests**: 8/8 passed (`bash tests/setup-deps.bash`)
- **Syntax**: `bash -n scripts/setup-omarchy` → exit 0
- **Hyprland**: N/A (change does not touch Hyprland configs)
- **Spec compliance**: 14/17 PASS, 3 DEFERRED

### DEFERRED (live Omarchy host only)

These require a real Omarchy install. User must run after `./setup --omarchy` completes:

**1. Req 3 / S3.1, S3.2, S3.3 — runtime key event behavior**

```bash
sudo keyd -V                            # confirm /etc/keyd/default.conf is active
sudo keyd monitor                       # hold VolUp → no event; hold VolDown → no event; press broken "up" → pagedown event
sudo keyd -c /etc/keyd/default.conf check  # exit 0
```

**2. Req 4 / S4.1, S4.2 — file mode + service enable**

```bash
stat -c '%a' /etc/keyd/default.conf    # expected: 644
diff -q /etc/keyd/default.conf /home/lcardenas/Projects/autanasoft/dotfiles/omarchy/home/.config/keyd/default.conf  # no output
systemctl is-enabled keyd ratbagd      # expected: enabled, enabled
systemctl is-active keyd ratbagd        # expected: active, active
pacman -Ql keyd | grep -E 'keyd\.service$'
pacman -Ql libratbag | grep -E 'ratbagd\.service$'
ls -la ~/.config/keyd 2>&1             # expected: "No such file or directory"
```

**3. Req 5 / S5.2 — Piper profile recreation**

Follow `docs/inputs/mouse-g502.md` "Manual recreation in Piper" section to restore Default + Game profiles on the G502's onboard firmware.

### Sign-off

**GO** — zero CRITICAL findings. Single WARNING (unrelated working-tree drift) addressed at commit time.

---

## Post-Archive Working Tree

```
On branch main
Your branch is ahead of 'origin/main' by 1 commit.

Changes not staged for commit:
  M  docs/shared-layer.md                         ← input-devices (change)
  M  openspec/specs/setup-orchestration/spec.md   ← input-devices (change — spec merge)
  M  scripts/setup-deps                           ← input-devices (change)
  M  scripts/setup-omarchy                        ← input-devices (change)
  M  shared/nvim/lazy-lock.json                  ← WARNING: pre-existing drift (LazyVim auto-update)
  M  shared/zellij/config.kdl                    ← WARNING: pre-existing drift (omarchy default)
  M  tests/setup-deps.bash                       ← input-devices (change)

Untracked files:
  docs/inputs/                                   ← input-devices (change — new dir)
  omarchy/home/.config/                          ← input-devices (change — new dir, keyd default.conf)
  openspec/changes/archive/2026-06-17-input-devices-config/  ← archived change folder
```

---

## Recommended Next Step (User Decision)

**Review the diff and commit.** Suggested commit message:

```
feat(input-devices): add keyd keyboard remap and Piper G502 mouse setup (Omarchy)
```

**Stage only the 7 input-devices files** (exclude pre-existing dirty files):

```bash
git add docs/shared-layer.md \
        scripts/setup-deps \
        scripts/setup-omarchy \
        tests/setup-deps.bash \
        docs/inputs/ \
        omarchy/home/.config/keyd/default.conf \
        openspec/specs/setup-orchestration/spec.md
git commit -m "feat(input-devices): add keyd keyboard remap and Piper G502 mouse setup (Omarchy)"
```

Do NOT stage `shared/nvim/lazy-lock.json` or `shared/zellij/config.kdl` — those are pre-existing drift unrelated to this change.

---

## SDD Cycle Status

**Complete**: YES. All phases (explore, propose, spec, design, tasks, apply, verify, archive) are done. No CRITICAL findings. 3 DEFERRED scenarios are live-host-only and have exact verification commands above.

**Next**: User reviews diff and commits. No further SDD phases apply — the change is closed.
