# Keyboard remap (keyd)

Remap the broken hardware "up" arrow to `pagedown`, silence the
unwanted media keys (VolUp / VolDown), and reload keyd from a single
tracked file. Omarchy only.

## Quick path

1. Edit `omarchy/home/.config/keyd/default.conf` in the repo.
2. Re-apply the Omarchy env flow:
   ```bash
   ./setup --omarchy
   ```
   This copies the file to `/etc/keyd/default.conf` and re-enables the
   `keyd` service. The two `sudo` calls in the new step coalesce under
   the timestamp cache — one password prompt.
3. Verify the new bindings are live:
   ```bash
   sudo keyd -V
   sudo keyd monitor
   ```

## Details

### File locations

| Layer | Path | Owner | Notes |
| --- | --- | --- | --- |
| Repo (source of truth) | `omarchy/home/.config/keyd/default.conf` | user | Tracked in git. Lives in the env folder, not `shared/`, because keyd is Omarchy-only. |
| Daemon (live) | `/etc/keyd/default.conf` | root | Read by keyd at boot. Re-installed on every `./setup --omarchy`. |

keyd runs as root and reads **only** from `/etc/keyd/`. There is no
`~/.config/keyd/` symlink and the user-level path is unused. This is
the second tracked-on-repo-but-not-live-symlink exception (the first
is the SSH config template); see
[`docs/shared-layer.md`](../shared-layer.md).

### Edit and reload

| Action | Command |
| --- | --- |
| Re-run the env flow | `./setup --omarchy` |
| Copy + reload manually | `sudo install -m 644 omarchy/home/.config/keyd/default.conf /etc/keyd/default.conf && sudo keyd reload` |
| Dry-run preview | `./setup --omarchy --dry-run` |

The env flow is idempotent. Re-running does not duplicate state, and
the keyd service is already `enabled` after the first run, so the
`systemctl enable --now` call becomes a no-op.

### Inspecting active bindings

| Command | What it shows |
| --- | --- |
| `sudo keyd -V` | keyd version and the active config file in use. |
| `sudo keyd monitor` | Real-time key events. **This is also where you find the `<vid>:<pid>` of every connected device** — use it for the VID:PID migration below. |

### VID:PID migration (adding a second keyboard)

`[ids] *` is the universal scope. A single keyboard works without
device IDs, but a second keyboard with different bindings needs
scoping.

1. Plug the new keyboard in.
2. Run `sudo keyd monitor` and press a key on the new device. The
   output contains a line like `event: devname="..." vid=0x046d pid=0xc52b`.
3. In `omarchy/home/.config/keyd/default.conf`, replace
   ```ini
   [ids]
   *
   ```
   with the keyd v2.6 syntax — lowercase hex, no `0x` prefix, colon
   between VID and PID, `:*` to keep the universal fallback for any
   unlisted device:
   ```ini
   [ids]
   046d:c52b:*
   ```
   The conceptual placeholder for this scope is `usb:VID:PID` (the
   spec uses that label; the real config uses the bare hex form
   above).
4. Reload: `./setup --omarchy` (or `sudo keyd reload` after a manual
   `install`).

## Checklist

- [ ] `omarchy/home/.config/keyd/default.conf` is the only file you
      edit. Do not hand-edit `/etc/keyd/default.conf` — it gets
      overwritten on the next env run.
- [ ] `sudo keyd -V` shows `/etc/keyd/default.conf` as the active
      config after every reload.
- [ ] When adding a second keyboard, the migration path uses
      `sudo keyd monitor` to discover the device IDs, not a guess.
- [ ] Disabled keys use `= noop`, not `= clear` (`clear()` clears
      toggled/oneshot layers, it does not silence a key).

## Next step

For the Logitech G502 Hero mouse profiles (Default + Game), see
[`mouse-g502.md`](mouse-g502.md).
