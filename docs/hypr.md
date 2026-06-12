# Hyprland configuration

User-managed Hyprland configuration for Omarchy. Customizations live
under `omarchy/config/hypr/` and follow the [p- prefix
convention](#the-p--prefix-convention). The repo is the source of
truth; live files are symlinks into the repo.

Reference: <https://wiki.hypr.land/Configuring/>

## Files

| File | Purpose |
| --- | --- |
| `hyprland.conf` | Main entry point. Sources Omarchy defaults, then `p-index.conf`. |
| `p-index.conf` | Personal config index. Sources the 4 `p-` files in order. |
| `p-monitors.conf` | Monitor layout and resolutions. |
| `p-looknfeel.conf` | Visual overrides (gaps, border, rounding, dim, animations). |
| `p-bindings.conf` | Custom keybindings (unbinds + binds). |
| `p-rules.conf` | Window rules per class/title (float, center, size). |
| `hypridle.conf` | Idle and lock behavior. |

Other Hyprland files (`autostart.conf`, `envs.conf`, `input.conf`,
`hyprlock.conf`, `hyprsunset.conf`, `xdph.conf`) match Omarchy
defaults and are not tracked. See [AGENTS.md](../AGENTS.md) for the
general inclusion policy.

## The `p-` prefix convention

Files prefixed with `p-` are user-personal customizations that
survive `omarchy update` and are sourced by `p-index.conf` after
Omarchy's defaults. To add a new one, name it `p-*.conf` and add a
`source =` line to `p-index.conf`.

## Customizations

For each customized file, the WHY (decisions and tradeoffs) and the
non-obvious footguns. The actual config lives in the `.conf` — open
it for the WHAT.

### Look and feel — `p-looknfeel.conf`

Tighter spacing, thicker border, mild rounding. Commented entries
in the file are values that were tested and rejected — see the file
for the decision log.

### Window rules — `p-rules.conf`

Floating windows (1043×587, user-preferred 16:9 size):

| App | Size |
| --- | --- |
| Nautilus (file manager) | 1043×587 |
| Calculator | natural |
| Spotify | 1043×587 |
| Cliamp (Omarchy radio) | 1043×587 |
| Nvim (Omarchy editor wrapper) | 1043×587 |
| Alacritty (any window) | 1043×587 |
| Discord (desktop app) | 1043×587 |
| Netflix (webapp) | 1043×587 |
| WhatsApp (webapp) | 1043×587 |
| YouTube (webapp) | 1043×587 |

**Two non-obvious overrides in this file**: Calculator has no
explicit size (opens at natural dimensions), and the bottom
5 lines tag PiP windows and force `size 1043 587` instead of
Omarchy's `apps/pip.conf` default. See `p-rules.conf` for the
inline rationale.

### Keybindings — `p-bindings.conf`

The file has `unbind` entries at the top (defaults removed) and
`bindd` entries below (custom adds).

**Customized bindings:**

| Key | App | Status |
| --- | --- | --- |
| SUPER RETURN | Terminal (Zellij) | Reassigned (was default terminal) |
| SUPER ALT RETURN | Terminal (Zellij Work) | Reassigned (was Terminal) |
| SUPER SHIFT B | Browser (private) | Reassigned (was Browser) |
| SUPER SHIFT C | Calculator | Reassigned (was Calculator) |
| SUPER SHIFT D | Discord | New |
| SUPER SHIFT E | Editor | Reassigned (was Editor) |
| SUPER SHIFT N | Netflix | Reassigned |
| SUPER SHIFT R | Raadio TUI | Reassigned (was print-screen) |
| SUPER SHIFT S | Spotify | New |
| SUPER SHIFT T | Tmux | New |
| SUPER SHIFT W | WhatsApp | Reassigned |
| SUPER SHIFT Y | YouTube | New |
| SUPER SHIFT CTRL D | Docker (lazydocker) | Reassigned (was SUPER SHIFT D) |

**Removed defaults** (original Omarchy app not always recoverable
from this repo — see `p-bindings.conf` for the `unbind` lines):

| Key | App | Status |
| --- | --- | --- |
| SUPER RETURN | Terminal | Reassigned → Terminal (Zellij) |
| SUPER ALT RETURN | Terminal | Reassigned → Terminal (Zellij Work) |
| SUPER SHIFT A | — | Removed |
| SUPER SHIFT ALT A | — | Removed |
| SUPER SHIFT B | Browser | Reassigned → Browser (private) |
| SUPER SHIFT C | Calculator | Reassigned → Calculator (corrected) |
| SUPER SHIFT D | Docker (lazydocker) | Reassigned → Discord |
| SUPER SHIFT CTRL G | — | Removed |
| SUPER SHIFT E | Editor | Reassigned → Editor |
| SUPER SHIFT G | — | Removed |
| SUPER SHIFT ALT G | — | Removed |
| SUPER SHIFT M | — | Removed |
| SUPER SHIFT N | — | Reassigned → Netflix |
| SUPER SHIFT P | — | Removed |
| SUPER SHIFT SLASH | — | Removed |
| SUPER SHIFT W | — | Reassigned → WhatsApp |
| SUPER SHIFT X | — | Removed |
| SUPER SHIFT ALT X | — | Removed |

### Idle and lock — `hypridle.conf`

No screensaver, no display-off — straight to lock on idle. See the
file for the listener details and the original Omarchy defaults
(kept commented for reference).
