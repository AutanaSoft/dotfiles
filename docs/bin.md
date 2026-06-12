# User scripts (`omarchy/bin/`)

Executable scripts shipped in this repository. Each script lives at
`omarchy/bin/<name>` and is meant to be exposed on the user's `$PATH`
via a symlink in `~/.local/bin` (or similar). Adjust to match the
host's PATH conventions.

## monitor

Toggle the secondary monitor on or off without restarting Hyprland.

```bash
monitor on   # re-read p-monitors.conf and re-enable HDMI-A-1
monitor off  # disable HDMI-A-1 and let Hyprland migrate its workspaces
```

Implementation: `omarchy/bin/monitor`.

### How it works

| Command | Mechanism |
| --- | --- |
| `on` | `hyprctl reload` — Hyprland re-reads the config (sourced via `p-index.conf` from `p-monitors.conf` in this repo), restoring the full dual-monitor layout. |
| `off` | `hyprctl keyword monitor "HDMI-A-1,disable"` — temporarily disable just that monitor. Hyprland moves its workspaces and windows to the remaining active monitor. |

### Why a wrapper

`hyprctl reload` works, but typing it (plus knowing the exact disable
syntax) is friction. The script wraps both operations in
single-command mnemonics and makes the target monitor explicit
(`HDMI-A-1` is hardcoded).

### Caveats

- `monitor off` is **session state**, not persistent. After a Hyprland
  reload or restart, `p-monitors.conf` is re-read and the secondary
  monitor comes back. Use `monitor off` to save power on the fly; do
  not edit `p-monitors.conf` to disable a monitor.
- The script has no effect if `HDMI-A-1` is not connected. Run
  `hyprctl monitors` to confirm what is currently attached.

### Adding new bin scripts

1. Place the file in `omarchy/bin/<name>` (no extension, executable).
2. Add a symlink in `~/.local/bin` (or wherever `$PATH` resolves).
3. Document it here in a new `## <name>` section.
