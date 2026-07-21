# Hyprland

User-managed Hyprland configuration for Omarchy. Lives under
`omarchy/home/config/hypr/`; the repo is the source of truth and live
files in `~/.config/hypr/` are symlinks into the repo.

Reference: <https://wiki.hypr.land/Configuring/>

## Reload and verify

After any edit:

```bash
hyprctl reload && hyprctl configerrors
```

The reload must report no errors before continuing.

## Tracked files

| File                | Purpose                                          |
| ------------------- | ------------------------------------------------ |
| `hyprland.conf`     | Main entry; sources Omarchy defaults + `p-index`. |
| `p-index.conf`      | Sources the `p-` files in order.                 |
| `p-monitors.conf`   | Monitor layout and resolutions.                  |
| `p-looknfeel.conf`  | Gaps, border, rounding, dim, animations.         |
| `p-bindings.conf`   | Custom keybindings (unbinds + `bindd`).          |
| `p-rules.conf`      | Window rules per class/title.                    |
| `hypridle.conf`     | Idle and lock behavior.                          |

Default-identical files (`autostart.conf`, `envs.conf`, `input.conf`,
`hyprlock.conf`, `hyprsunset.conf`, `xdph.conf`) are not tracked. See
[`docs/shared-layer.md`](shared-layer.md#tracking-policy) for the inclusion
policy.

## The `p-` prefix convention

Files prefixed with `p-` are user-personal customizations and survive
`omarchy update`. They are sourced by `p-index.conf` after Omarchy's
defaults. To add a new one, name it `p-*.conf` and append a
`source =` line to `p-index.conf`.

**Never edit files under `~/.local/share/omarchy/`** — they are
overwritten by `omarchy update`. Put personal customizations in
`p-` files only.

## Key customizations

The `.conf` files are the source of truth; this is a quick index of
the non-obvious decisions.

### Window rules — `p-rules.conf`

Most app windows are floated at **1043×587** (a personal 16:9 size).
Calculator opens at its natural size. PiP windows are forced to
1043×587 and a 2 px border instead of Omarchy's `apps/pip.conf`
defaults (600×338, no border) — see the inline rationale in the
file.

| App                                       | Size     |
| ----------------------------------------- | -------- |
| Nautilus, Spotify, Cliamp, Nvim           | 1043×587 |
| Alacritty (any window), Discord           | 1043×587 |
| WhatsApp, YouTube (webapps)               | 1043×587 |
| Netflix                                   | 1043×587 (PiP, pinned) |
| Calculator                                | natural  |

### Keybindings — `p-bindings.conf`

`unbind` entries at the top remove Omarchy defaults; `bindd` entries
below add the personal set. The file is self-documenting — refer to
it for the full list. Notable reassignments:

| Key                  | Action                  |
| -------------------- | ----------------------- |
| `SUPER RETURN`       | Terminal (Zellij)       |
| `SUPER ALT RETURN`   | Terminal (Zellij Work)  |
| `SUPER SHIFT B`      | Browser (private)       |
| `SUPER SHIFT C`      | Calculator              |
| `SUPER SHIFT D`      | Discord                 |
| `SUPER SHIFT E`      | Editor                  |
| `SUPER SHIFT N`      | Netflix                 |
| `SUPER SHIFT R`      | Raadio TUI              |
| `SUPER SHIFT S`      | Spotify                 |
| `SUPER SHIFT T`      | Tmux                    |
| `SUPER SHIFT W`      | WhatsApp                |
| `SUPER SHIFT Y`      | YouTube                 |
| `SUPER SHIFT CTRL D` | Docker (lazydocker)     |

## See also

- [`omarchy/README.md`](../omarchy/README.md) — managed paths and setup.
- [`AGENTS.md`](../AGENTS.md) — repo conventions.
