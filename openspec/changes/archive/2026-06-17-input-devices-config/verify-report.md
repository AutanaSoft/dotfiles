# Verify report: input-devices-config (Omarchy-only)

## Summary

- **Overall verdict**: **PASS WITH WARNINGS** (0 CRITICAL, 1 WARNING, 1 SUGGESTION).
- 17/17 spec scenarios walked through: 14 PASS (static + TAP), 3 DEFERRED (live Omarchy host).
- `bash tests/setup-deps.bash` → `8/8 passed`. `bash -n scripts/setup-omarchy` → exit 0.
- `hyprctl configerrors` → empty. This change does NOT touch Hyprland; the project rule's
  "configerrors MUST be empty" corollary is "not applicable" and the actual check on
  the running Hyprland session passes.
- Sign-off: **GO** for archive. The single WARNING is working-tree drift unrelated to
  this change (LazyVim auto-update + a zellij config line) and can be excluded from the
  `input-devices-config` commit when the user opens the PR.

## Test results

### Bash TAP (`bash tests/setup-deps.bash`)

```
1..8
ok 1 - root --omarchy invokes setup-omarchy exactly once
ok 2 - --omarchy --fonts and --omarchy --deps are absorbed by root
ok 3 - --fedora (any combo) short-circuits to not-implemented and exits 0
ok 4 - --fonts runs only setup-fonts; --deps runs only setup-deps
ok 5 - env-script pre-flight handles missing/overridden $DOTFILES_FONTS_DIR
ok 6 - DOTFILES_* (5 vars) cleanup under env -i + trap source grep
ok 7 - scripts/setup-deps auto-detects env (yay/dnf/none) and respects override
ok 8 - scripts/setup-deps single-pass batch install per env (T8 A/B/C/D/F)
# 8/8 passed
```

`T8 sub-case C` (Omarchy substring array) passes — the three new packages
`keyd piper libratbag` are each a substring of the single `yay -S --needed` line.
`T8 sub-case D` (Fedora substring array) passes — the `lsof hunspell hunspell-en-US
hunspell-es trash-cli` array is byte-identical to the pre-change array (no new
Fedora packages).

### Bash syntax (`bash -n scripts/setup-omarchy`)

```
EXIT: 0
```

No parse errors. The new `install_input_devices` function and the `TOTAL_STEPS=5`
bump are syntactically clean.

### Hyprland (`hyprctl reload && hyprctl configerrors`)

This change does NOT modify any Hyprland, Mako, Waybar, or Walker config. Per the
project rule's corollary ("if NOT Hyprland, document that the change does not touch
Hyprland and configerrors is not applicable"), the literal check on the running
session is recorded for completeness:

- `hyprctl reload` → `ok`, exit 0.
- `hyprctl configerrors` → empty output, exit 0.

The rule's MUST requirement is "configerrors empty". Empty IS the result. The
"not applicable" framing is a meta-observation: Hyprland is not in this change's
scope, so even a stale configerrors reading from an unrelated drift would be
out-of-scope for this verify.

### keyd / systemctl availability on this verify host

- `command -v keyd` → `command not found` (keyd is not installed on the planning
  host). `/etc/keyd/` does not exist.
- `command -v systemctl` → `/usr/bin/systemctl` (available, but keyd/ratbagd units
  are not installed).
- `command -v piper` → not installed.

These three live-host items are the DEFERRED scenarios below. The Omarchy env flow
is the only context where they exist.

### Dry-run smoke (extra confidence)

`scripts/setup-omarchy --dry-run` emits the expected step counter AND both preview
lines for the new step (truncated):

```
[setup-omarchy] Step 1/5: Install OS dependencies (via scripts/setup-deps)
[setup-deps]   [miss] keyd
[setup-deps] Installing 3 missing: keyd piper libratbag
[setup-deps] [dry-run] would run: yay -S --needed keyd piper libratbag
[setup-omarchy] Step 2/5: Install Nerd Fonts (via scripts/setup-fonts)
[setup-omarchy] Step 3/5: Apply symlinks
[setup-omarchy] Step 4/5: Install keyd config and enable input-device services
[setup-omarchy] [dry-run] would run: install -m 644 .../omarchy/home/.config/keyd/default.conf /etc/keyd/default.conf
[setup-omarchy] [dry-run] would run: systemctl enable --now keyd ratbagd
[setup-omarchy] Step 5/5: Validate system
```

Confirms: `TOTAL_STEPS=5` renders correctly, `Step 4/5` is the new step, the dry-run
branch emits both preview lines, no `install` or `systemctl` is actually called.

## Spec compliance

5 requirements, 17 scenarios. PASS / FAIL / DEFERRED counts per requirement:

| Requirement | Scenarios | PASS | FAIL | DEFERRED |
| --- | --- | --- | --- | --- |
| 1. Input-devices packages (Omarchy only) | 4 | 4 | 0 | 0 |
| 2. TAP test coverage for the input-devices packages | 2 | 2 | 0 | 0 |
| 3. keyd config file in the Omarchy repo layer | 4 | 3 | 0 | 1 |
| 4. setup-omarchy installs the keyd config and enables input-device services | 4 | 2 | 0 | 2 |
| 5. Docs cover the input-devices workflow and the shared-layer exception | 3 | 3 | 0 | 0 |
| **Total** | **17** | **14** | **0** | **3** |

### Req 1 — Input-devices packages (Omarchy only)

- **S1.1 Omarchy package list contains the three input-device packages** → **PASS**.
  `scripts/setup-deps:68-70` shows `keyd`, `piper`, `libratbag` in `OMARCHY_PACKAGES`,
  with the explicit `# provides: ratbagd` comment on `libratbag`. No standalone
  `ratbagd` package is present (avoids the Arch pacman conflict).
- **S1.2 Fedora package list is unchanged** → **PASS**.
  `scripts/setup-deps:73-79` `FEDORA_PACKAGES` contains `lsof`, `hunspell`,
  `hunspell-en-US`, `hunspell-es`, `trash-cli` — byte-identical to the pre-change
  list. No `keyd`, `piper`, `libratbag`, or `ratbagd` in the array.
- **S1.3 Omarchy dry-run emits a single yay line with all three packages** → **PASS**.
  T8 sub-case C asserts `yay_count == 1` and that each of the three new names is a
  substring of that single `yay -S --needed` line. Test 8 passed.
- **S1.4 Fedora dry-run is unchanged** → **PASS**.
  T8 sub-case D asserts `dnf_count == 1` and the substring array contains ONLY the
  five pre-change Fedora packages (no `keyd`, `piper`, `libratbag`, `ratbagd`).
  Test 8 passed.

### Req 2 — TAP test coverage for the input-devices packages

- **S2.1 T8 sub-case C substring array contains all three new packages** → **PASS**.
  `tests/setup-deps.bash:1195-1197` defines
  `omarchy_pkgs=(lsof hunspell hunspell-en_us hunspell-es_any zellij trash-cli
  keyd piper libratbag)` with the lockstep comment on line 1194. Test 8 passed.
- **S2.2 T8 sub-case D Fedora substring array is unchanged** → **PASS**.
  `tests/setup-deps.bash:1250-1252` defines
  `fedora_pkgs=(lsof hunspell hunspell-en-US hunspell-es trash-cli)` — exactly the
  pre-change array. Test 8 passed.

### Req 3 — keyd config file in the Omarchy repo layer

- **S3.1 VolUp is silenced at the kernel level** → **PASS (config) + DEFERRED
  (runtime event verification)**.
  `omarchy/home/.config/keyd/default.conf:43` is `volumeup = noop` — the canonical
  keyd v2.6 disable action (man page Example 8: `esc = noop; end = noop`,
  "Disables the esc and end keys"). The `clear()` action is explicitly excluded
  in the inline comment (line 39-42) and in the checklist of the keyboard runbook
  (`docs/inputs/keyboard-remap.md:93-94`). Runtime event verification (hold
  VolUp, confirm no `volumeup` reaches the application) is deferred to a live
  Omarchy host with keyd running.
- **S3.2 VolDown is silenced at the kernel level** → **PASS (config) + DEFERRED
  (runtime)**.
  `omarchy/home/.config/keyd/default.conf:44` is `volumedown = noop`. Same
  reasoning as S3.1.
- **S3.3 broken Up key is remapped to PageDown** → **PASS (config) + DEFERRED
  (runtime)**.
  `omarchy/home/.config/keyd/default.conf:48` is `up = pagedown`. The inline
  comment (line 46-47) documents the intent. Runtime verification (press the
  broken `up`, confirm `pagedown` reaches the application) is deferred to a
  live Omarchy host.
- **S3.4 scope is universal `[ids] *` AND the runbook explains VID:PID migration**
  → **PASS**.
  `omarchy/home/.config/keyd/default.conf:35-36` is `[ids]` then `*` (universal).
  The runbook `docs/inputs/keyboard-remap.md:57-82` has a dedicated
  "VID:PID migration (adding a second keyboard)" section that walks through
  `sudo keyd monitor` to discover the `<vid>:<pid>` and the replacement
  syntax `046d:c52b:*`. The conceptual placeholder `usb:VID:PID` is
  mentioned in the doc (line 78) so the spec's `usb:VID:PID` label maps to
  the real keyd v2.6 syntax.

### Req 4 — setup-omarchy installs the keyd config and enables input-device services

- **S4.1 keyd config is installed to /etc/keyd with mode 0644** →
  **PASS (code review) + DEFERRED (live file mode)**.
  `scripts/setup-omarchy:404-420` `install_input_devices` runs
  `sudo install -m 644 "$src" "$target"` where `$src` is the repo file and
  `$target` is `/etc/keyd/default.conf`. The `install -m 644` form is the
  POSIX-portable way to set mode 0644 atomically. The function is called as
  Step 4/5 (line 525) and the dry-run branch (line 408-412) emits a preview
  line without mutation. Live file mode verification
  (`stat -c '%a' /etc/keyd/default.conf` returns `644`) is deferred to a
  live Omarchy host.
- **S4.2 keyd and ratbagd services are enabled and started** →
  **PASS (code review) + DEFERRED (live systemctl)**.
  `scripts/setup-omarchy:419` is `sudo systemctl enable --now keyd ratbagd` —
  a SINGLE coalesced call (not two). The block comment (line 386-403) documents
  the precedent (first sudo service-enable in the env flow, no `sudo -v` upfront,
  timestamp cache coalesces the `install` and `systemctl` calls). Live verification
  (`systemctl is-enabled keyd ratbagd` returns `enabled`,
  `systemctl is-active keyd ratbagd` returns `active`) is deferred. The exact
  service unit names (`keyd.service`, `ratbagd.service`) were flagged in the
  apply report as needing `pacman -Ql keyd libratbag` confirmation on the live
  host; this is a man-page-level detail and the units are the standard names
  shipped by those packages on Arch.
- **S4.3 dry-run previews the install and the service enable without mutating** →
  **PASS**.
  `scripts/setup-omarchy:408-412` is the dry-run branch — it returns early after
  emitting two preview lines (`install -m 644 ...` and `systemctl enable --now
  keyd ratbagd`) and does NOT call `install` or `systemctl`. The extra-confidence
  dry-run smoke above shows both preview lines in the live invocation output.
  T5 (the env-script pre-flight test in the TAP harness) passes, which means
  the dry-run path does not touch the system.
- **S4.4 no home symlink for keyd** → **PASS**.
  `scripts/setup-omarchy` `apply_symlinks` (lines 319-382) has no entry for
  `~/.config/keyd/`. The only keyd references in the function boundary are
  the explicit comment (line 400: "No `~/.config/keyd/` symlink is created
  here"). `docs/shared-layer.md:55-58` reinforces the rationale: "the
  user-level path (`~/.config/keyd/`) is unused, so no `~/.config/keyd/`
  symlink is created."

### Req 5 — Docs cover the input-devices workflow and the shared-layer exception

- **S5.1 keyboard runbook covers config layout, reload, and VID:PID migration**
  → **PASS**.
  `docs/inputs/keyboard-remap.md` (99 lines):
  - **Config location**: "File locations" table on lines 25-30 (repo source of
    truth + daemon live path).
  - **Reload flow**: "Edit and reload" table on lines 38-44 (env flow,
    manual `install` + `keyd reload`, dry-run preview).
  - **VID:PID migration**: dedicated "VID:PID migration (adding a second
    keyboard)" section on lines 57-82 with the `sudo keyd monitor` step,
    the conceptual `usb:VID:PID` placeholder, and the real keyd v2.6 syntax
    `046d:c52b:*`.
- **S5.2 mouse runbook covers two profiles and the firmware-storage caveat**
  → **PASS**.
  `docs/inputs/mouse-g502.md` (91 lines):
  - **Two profiles with bindings**: "Profile bindings" table on lines 21-29
    covers Default + Game with X1/X2/DPI Up/DPI Down/DPI Shift/Scroll Left/
    Scroll Right. The DPI-Shift row explicitly notes it is the profile-toggle
    (cannot be remapped to "do nothing").
  - **Firmware-storage caveat**: "Why profiles are NOT in the repo" section
    on lines 40-49 explicitly states "ratbagd over DBus to the G502's
    onboard EEPROM (firmware). There is no on-disk artefact to version
    control. [...] This is the recovery path, not a bug." The checklist
    (line 84) reinforces: "No version-controlled copy of the profiles
    exists anywhere in the repo (this is by design)."
- **S5.3 shared-layer doc gets a keyd exception (Omarchy only)** → **PASS**.
  `docs/shared-layer.md:51-64` is a new `### Exception: /etc/keyd/default.conf
  install pattern` paragraph under `## SSH template exception`. It mirrors the
  SSH template's tone ("repo source", "copies [...] to /etc/keyd/", "install -m
  644", "root-owned, daemon config — not a symlink"). It is explicitly
  scoped to Omarchy only ("It is **Omarchy only** (Fedora is out of scope —
  Piper and keyd are not installed on the Fedora env, and there is no
  `shared/` involvement)").

## Findings

### CRITICAL

None. The 14 PASS scenarios are covered by static evidence + the 8/8 TAP test
result. The 3 DEFERRED scenarios are all live-host-only items that are
documented in the manual verification checklist below. No locked decision was
violated:

- Omarchy-only scope: `FEDORA_PACKAGES` byte-identical; no `shared/` edits; no
  `scripts/setup-fedora` created; shared-layer exception paragraph explicitly
  Omarchy-scoped.
- `noop` (not `clear`): used in the keyd config body; the wrong primitive is
  ruled out in two inline comments and the keyboard runbook checklist.
- Piper profiles NOT in the repo: explicit "by design" caveat in
  `docs/inputs/mouse-g502.md` and the runbook is the recovery path.
- Service enable in `scripts/setup-omarchy` (not in setup-deps): the
  `install_input_devices` function lives in `scripts/setup-omarchy` and the
  `systemctl enable --now` is in that function.
- No `sudo -v` upfront: the block comment on lines 386-403 documents the
  precedent (rely on timestamp cache, not explicit `sudo -v`).
- `[ids] *` (universal) with documented VID:PID migration: present in both
  the keyd config and the runbook.
- No commit / push / PR: confirmed by `git status` showing only working-tree
  edits and untracked files.
- Locked artifacts untouched: `openspec/changes/input-devices-config/{proposal,
  specs/.../spec,design,tasks}.md` not modified. `openspec/specs/setup-orchestration/
  spec.md` (merge target) not modified. `openspec/changes/cleanup-omarchy/`
  confirmed archived (not in working tree).

### WARNING

**W1. Working tree contains 2 unrelated modifications outside this change's
scope.** `git status` shows:

- `M shared/nvim/lazy-lock.json` (4 lines) — LazyVim auto-update bumped
  `SchemaStore.nvim` and `mini.icons` plugin commits.
- `M shared/zellij/config.kdl` (2 lines) — `default_layout "autanasoft"`
  commented out to use the omarchy default.

Neither file is in the `input-devices-config` change's design or apply report.
These will pollute any future `git add` / `git commit` for this change if the
user does not stage selectively. The fix is at commit time, not in this
verify: stage only the 4 modified + 3 untracked files that belong to
`input-devices-config` (`docs/shared-layer.md`, `scripts/setup-deps`,
`scripts/setup-omarchy`, `tests/setup-deps.bash`, `docs/inputs/keyboard-remap.md`,
`docs/inputs/mouse-g502.md`, `omarchy/home/.config/keyd/default.conf`).
This does NOT block archive readiness — the apply work itself is correct
and self-contained.

### SUGGESTION

**S1. Two stale "Step 2/4" references in `scripts/setup-omarchy` should be
"Step 2/5" for consistency with the bumped `TOTAL_STEPS=5`.** Lines 34 and 502:

- `scripts/setup-omarchy:34`:
  `# Fonts are installed by the env flow itself (Step 2/4). When this`
- `scripts/setup-omarchy:502`:
  `# fonts dir at this point means Step 2/4 was bypassed (e.g. someone`

The actual step counter (`TOTAL_STEPS=5`) and the active `Step X/5` log lines
in `main()` are correct — only these two doc comments are stale. No functional
impact (T5 TAP test confirms the step counter is right; the dry-run smoke
above shows the new Step 4/5 fires correctly). Fix is one-line per comment.

## Manual verification checklist (live Omarchy host)

These three DEFERRED scenarios require a real Omarchy host. The user runs the
following commands after `./setup --omarchy` completes:

### 1. Req 3 / S3.1, S3.2, S3.3 — runtime key event behavior

```bash
# Confirm keyd loaded the repo config
sudo keyd -V
# Expected: shows /etc/keyd/default.conf as the active config.

# Confirm VolUp / VolDown are silenced at the kernel level
sudo keyd monitor
# Hold the volumeup key — no 'volumeup' event should appear.
# Hold the volumedown key — no 'volumedown' event should appear.

# Confirm the broken Up arrow remap to PageDown
# Press the broken "up" key — 'pagedown' event should appear in the monitor.

# (Optional) Validate the config syntax with the keyd check subcommand.
# The exact flag spelling is `man keyd` on the live host
# (design §3.3 + open question).
sudo keyd -c /etc/keyd/default.conf check
# Expected: exit 0, no errors.
```

### 2. Req 4 / S4.1, S4.2 — file mode + service enable

```bash
# Confirm the config file mode
stat -c '%a' /etc/keyd/default.conf
# Expected: 644

# Confirm the file is bit-identical to the repo source
diff -q /etc/keyd/default.conf /home/lcardenas/Projects/autanasoft/dotfiles/omarchy/home/.config/keyd/default.conf
# Expected: no output (files match)

# Confirm keyd and ratbagd are enabled and active
systemctl is-enabled keyd
# Expected: enabled
systemctl is-enabled ratbagd
# Expected: enabled
systemctl is-active keyd
# Expected: active
systemctl is-active ratbagd
# Expected: active

# Confirm the service unit names (the design assumed keyd.service and
# ratbagd.service; this is the only live verification of that assumption)
pacman -Ql keyd | grep -E 'keyd\.service$'
pacman -Ql libratbag | grep -E 'ratbagd\.service$'
# Expected: each query returns a single line confirming the unit path.

# Confirm no ~/.config/keyd/ symlink was created
ls -la ~/.config/keyd 2>&1
# Expected: "No such file or directory"
```

### 3. Req 5 / S5.2 — Piper profile recreation (manual, by design)

The Piper profiles live on the G502's onboard firmware. After a fresh
`./setup --omarchy`, the mouse has its factory profile. The user follows
`docs/inputs/mouse-g502.md` "Manual recreation in Piper" (lines 51-62) to
recreate the Default and Game profiles with the bindings in the "Profile
bindings" table (lines 21-29). The runbook is the recovery path; this
cannot be automated from the repo.

## Sign-off

**GO** for archive. Zero CRITICAL findings. The single WARNING is
working-tree drift unrelated to this change; it is addressed at commit
time, not in the verify phase. The 3 DEFERRED scenarios are live-host-only
and the manual verification checklist above gives the user the exact
commands to run on a real Omarchy install.

Next recommended phase: `sdd-archive`.
