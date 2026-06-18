# Logitech G502 Hero — Piper profiles

Two profiles (Default + Game) for the G502's extra buttons, with the
exact bindings and a recovery path for a fresh host. Omarchy only.

## Quick path

1. Open Piper: `piper` (or launch from the application launcher).
2. In Piper, confirm the G502 is selected and create / verify the two
   profiles below.
3. Save to the device. The profile bytes are written to the G502's
   onboard firmware by `ratbagd` over DBus; nothing is written to
   disk.
4. Toggle between profiles with the DPI-Shift button (the button just
   behind the wheel).

## Details

### Profile bindings

| Button | Default profile | Game profile |
| --- | --- | --- |
| X1 (thumb, top) | `alt+Left` (browser back) | `button 4` (native back) |
| X2 (thumb, bottom) | `alt+Right` (browser forward) | `button 5` (native forward) |
| DPI Up (top of cluster) | Switch to next workspace | `noop` |
| DPI Down (bottom of cluster) | Switch to previous workspace | `noop` |
| DPI Shift (behind wheel) | `noop` (toggle only) | `noop` (toggle only) |
| Scroll Left | `XF86Back` | `noop` |
| Scroll Right | `XF86Forward` | `noop` |

Default profile: daily-driver bindings that make the extra buttons
useful in the browser and in workspaces. Game profile: native
back/forward (the games ignore `alt+Left` / `alt+Right`).

DPI Shift is the profile-toggle button. It cannot be remapped to
"do nothing" because the toggle itself is the function. Piper
shows it as `noop` because there is no per-key action to assign;
the toggle is implicit.

### Why profiles are NOT in the repo

Piper profiles are written by `ratbagd` over DBus to the G502's
onboard EEPROM (firmware). There is no on-disk artefact to version
control. After a fresh `./setup --omarchy` on a new machine, the
mouse has the factory-default profile and you must recreate the two
profiles in Piper by hand. The install step does NOT (and cannot)
restore them automatically.

This is the recovery path, not a bug.

### Manual recreation in Piper

1. `piper` (or `bauh` / walker → Piper).
2. Select the G502 in the device list.
3. Create **Default** profile. Bind the buttons per the table above
   (use `Key chord` for `alt+Left` / `alt+Right`; use the workspace
   switcher action for the DPI Up / Down rows).
4. Create **Game** profile. Same device, second tab.
5. Click **Save / Apply** for each profile. Piper pushes the
   bindings to the firmware; the device retains them when the
   computer reboots.
6. Toggle between profiles with the DPI-Shift button to confirm.

### Install notes

- `piper` is in `OMARCHY_PACKAGES` in `scripts/setup-deps` and
  installed by Step 1/5 of `./setup --omarchy`. `libratbag` provides
  the `ratbagd` DBus service; `systemctl enable --now keyd ratbagd`
  runs in Step 4/5 of the same flow.
- Piper is a per-user GUI app — there is no autostart entry. Launch
  it on demand from the application launcher.
- On a fresh host, the first `./setup --omarchy` will install
  `piper` and `libratbag`, enable `ratbagd`, but the G502 will still
  have its factory profile. The Piper run above is the only way to
  get the two custom profiles back.

## Checklist

- [ ] Two profiles exist in Piper with the bindings in the table
      above.
- [ ] Both profiles are saved to the device (the Piper UI shows
      them as active for the connected mouse).
- [ ] The DPI-Shift button toggles between Default and Game.
- [ ] No version-controlled copy of the profiles exists anywhere in
      the repo (this is by design — see "Why profiles are NOT in the
      repo").

## Next step

For keyboard remap (keyd) and the VID:PID migration path, see
[`keyboard-remap.md`](keyboard-remap.md).
