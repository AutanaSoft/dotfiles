# Hyprland configuration

User-managed Hyprland configuration for Omarchy. Every file under
`omarchy/config/hypr/` overrides the Omarchy defaults sourced in
`hyprland.conf`. Defaults live in `~/.local/share/omarchy/default/hypr/`
and must not be edited from this repo.

Reference: <https://wiki.hypr.land/Configuring/>

## Files

| File | Purpose | Symlinked to |
| --- | --- | --- |
| `hyprland.conf` | Main entry point. Sources defaults and user files in order. | `~/.config/hypr/hyprland.conf` |
| `monitors.conf` | Monitor layout and resolutions. | `~/.config/hypr/monitors.conf` |
| `bindings.conf` | Custom keybindings (app launchers, webapps, Logitech MX Keys). | `~/.config/hypr/bindings.conf` |
| `looknfeel.conf` | Visual overrides (gaps, border, rounding, dim). | `~/.config/hypr/looknfeel.conf` |
| `rules.conf` | Window rules per class/title (float, center, size). | `~/.config/hypr/rules.conf` |
| `hypridle.conf` | Idle and lock behavior. | `~/.config/hypr/hypridle.conf` |

Other Hyprland files (`autostart.conf`, `envs.conf`, `input.conf`,
`hyprlock.conf`, `hyprsunset.conf`, `xdph.conf`) exist in the system
but are not tracked here because they match the Omarchy defaults. See
[symlinks.md](symlinks.md) for the inclusion policy.

## Hyprland version

Pinned by Omarchy. Verified compatible with **0.55.2** running in
hyprlang compatibility mode (the new lua syntax `hl.config({...})` is
not used here). See [Syntax compatibility](#syntax-compatibility) below.

## Monitors (`monitors.conf`)

Dual-monitor desk setup. Primary on `HDMI-A-1` (27" 2560x1440 @ 144Hz),
secondary on `DP-2` (24" 1920x1080 @ 165Hz) positioned to the right
with vertical centering.

```ini
monitor = HDMI-A-1, 2560x1440@143.91, 0x0, 1
monitor = DP-2, 1920x1080@165, 2560x180, 1
```

Vertical offset `180` for the 1080p display is `(1440 - 1080) / 2`.
This is the only monitor layout used at the desk. See
[bin.md](bin.md#monitor) for the helper that toggles the secondary
monitor on/off.

## Look and feel (`looknfeel.conf`)

Conservative overrides over Omarchy defaults. Every default kept
commented for traceability.

```ini
general {
    gaps_in        = 2
    gaps_out       = 4
    border_size    = 2
    # layout = master                  # tested, kept default (dwindle)
}

decoration {
    rounding = 6
}
```

| Variable | Value | Default | Reason |
| --- | --- | --- | --- |
| `general.gaps_in` | `2` | `5` | Tighter spacing between windows. |
| `general.gaps_out` | `4` | `20` | Tighter spacing to monitor edges. |
| `general.border_size` | `2` | `1` | Slightly thicker border. |
| `decoration.rounding` | `6` | `0` | Mild rounded corners. |
| `decoration.dim_inactive` | `false` | `false` | Default; no dim on inactive windows. |
| `decoration.dim_strength` | `0.15` | `0.5` | No effect while `dim_inactive` is `false`. |
| `animations.enabled` | `true` | `true` | Default. Animations on. |
| `scrolling.column_width` | `0.5` | `0.5` | Default. Only used if `general.layout = scrolling`. |

Variables tested but kept commented (no functional change):
- `general.layout = master` — tested, returned to `dwindle`.
- `layout.single_window_aspect_ratio = 4 3` — tested, default `-1 -1` is preferred.

For more on these variables see:
<https://wiki.hypr.land/Configuring/Basics/Variables/#general> and
<https://wiki.hypr.land/Configuring/Basics/Variables/#layout>.

## Window rules (`rules.conf`)

Per-class window behavior. In Hyprland 0.55+ the unified `windowrule`
keyword is used (`windowrulev2` is deprecated). Effect flags that take
no argument in older versions (e.g. `center`) now require an explicit
value (`center 1`).

```ini
windowrule = float on, center 1, size 1152 648, match:class org.gnome.Nautilus
windowrule = float on, match:class org.gnome.Calculator
windowrule = float on, center 1, size 1152 648, match:class ^Spotify$
windowrule = float on, center 1, size 1152 648, match:class ^org\.omarchy\.cliamp$
windowrule = float on, center 1, size 1152 648, match:class ^org\.omarchy\.nvim$
windowrule = float on, center 1, size 1152 648, match:class ^Alacritty$
windowrule = float on, center 1, size 1152 648, match:class ^chrome-www\.netflix\.com__-Default$
windowrule = float on, center 1, size 1152 648, match:class ^chrome-web\.whatsapp\.com__-Default$
windowrule = float on, center 1, size 1152 648, match:class ^chrome-www\.youtube\.com__-Default$
```

| Class | Float | Center | Size | Notes |
| --- | --- | --- | --- | --- |
| `org.gnome.Nautilus` | yes | yes | 1152x648 | File manager. |
| `org.gnome.Calculator` | yes | no | default | User preference: snap to layout. |
| `^Spotify$` | yes | yes | 1152x648 | Official Spotify Linux client. |
| `^org\.omarchy\.cliamp$` | yes | yes | 1152x648 | Omarchy internet radio/stream player. |
| `^org\.omarchy\.nvim$` | yes | yes | 1152x648 | Omarchy editor wrapper. |
| `^Alacritty$` | yes | yes | 1152x648 | All Alacritty windows (with or without zellij). |
| `^chrome-www\.netflix\.com__-Default$` | yes | yes | 1152x648 | Netflix webapp. |
| `^chrome-web\.whatsapp\.com__-Default$` | yes | yes | 1152x648 | WhatsApp webapp. |
| `^chrome-www\.youtube\.com__-Default$` | yes | yes | 1152x648 | YouTube webapp (also covers `youtube.com` without www). |

### Size rationale

`1152 648` is **60% of the smallest monitor** (1920x1080). The
remaining 40% preserves breathing room and lets the floating window
feel "anchored" without dominating the screen.

### Why all Alacritty windows (no zellij differentiation)

A previous attempt to differentiate Alacritty by zellij session using
`match:title ^[^|]+$` did not work. `initialTitle` is `Alacritty` for
every window regardless of whether zellij is running; zellij updates
the title after Hyprland has already evaluated the rule. Treating all
Alacritty windows the same is the only reliable approach without
introducing a hook or wrapper.

### Webapp class detection

Omarchy webapps use the Chrome PWA launcher with class
`chrome-<domain>__-Default`. To detect the class of an open webapp:

```bash
hyprctl clients -j | python3 -c "import json,sys; [print(f\"class={c['class']} title='{c['title']}'\") for c in json.load(sys.stdin) if 'chrome' in c.get('class','').lower()]"
```

To list installed webapps: `ls ~/.local/share/applications/ | grep -i webapp`.

## Keybindings (`bindings.conf`)

Custom bindd entries. The file is ordered by modifier (SUPER < SUPER
ALT < SUPER SHIFT < SUPER ALT SHIFT), then alphabetically by key.
Disabling a default is done by overriding the key — Omarchy's defaults
sourced from `~/.local/share/omarchy/default/hypr/bindings/*.conf`
remain available for anything not listed here.

Reference: <https://wiki.hypr.land/Configuring/Basics/Binds/>

### App launchers

| Key | Description | Command |
| --- | --- | --- |
| SUPER RETURN | Terminal | `uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)"` |
| SUPER ALT RETURN | Zellij terminal | Same shell with `exec zellij attach --create AutanaSoft` |
| SUPER SHIFT RETURN | Browser | `omarchy-launch-browser` |
| SUPER SHIFT F | File manager | `uwsm-app -- nautilus --new-window` |
| SUPER ALT SHIFT F | File manager (cwd) | Same, in the current terminal's directory |
| SUPER SHIFT ALT B | Browser (private) | `omarchy-launch-browser --private` |
| SUPER SHIFT S | Spotify | `omarchy-launch-or-focus spotify` |
| SUPER SHIFT R | Raadio TUI | `omarchy-launch-or-focus-tui cliamp` |
| SUPER SHIFT N | Editor | `omarchy-launch-editor` |
| SUPER SHIFT D | Docker | `omarchy-launch-tui lazydocker` |
| SUPER SHIFT G | Signal | `omarchy-launch-or-focus ^signal$ "uwsm-app -- signal-desktop"` |
| SUPER SHIFT O | Obsidian | `omarchy-launch-or-focus ^obsidian$ "uwsm-app -- obsidian"` |
| SUPER SHIFT Z | Tmux | Terminal with `exec tmux attach \|\| exec tmux new -s Work` |
| SUPER SHIFT C | Calculator | `omarchy-launch-or-focus Calculator gnome-calculator` |
| SUPER SHIFT SLASH | Passwords | `uwsm-app -- 1password` |

### Webapps

| Key | Description | Command |
| --- | --- | --- |
| SUPER SHIFT Y | YouTube | `omarchy-launch-webapp "https://www.youtube.com/"` |
| SUPER SHIFT V | Netflix | `omarchy-launch-webapp "https://www.netflix.com/"` |
| SUPER SHIFT W | WhatsApp | `omarchy-launch-or-focus-webapp WhatsApp "https://web.whatsapp.com/"` |

Removed webapps (no longer used): ChatGPT, Grok, Calendar, Email,
Google Messages, Google Photos, X.

### Logitech MX Keys (hardware keys)

Plain `bind` (no description) for the dedicated keys on the MX Keys
keyboard.

| Key | Description | Command |
| --- | --- | --- |
| SUPER H | Dictation | `voxtype record toggle` |
| SUPER PERIOD | Emoji picker | `omarchy-launch-walker -m symbols` |

The print-screen key was previously bound here (`SUPER SHIFT R` →
`omarchy-capture-screenshot`) but was removed because the same key is
already used for "Raadio TUI" in the app launchers section above.
Re-add it on a different key if a dedicated screenshot shortcut is
needed.

### `omarchy-launch-or-focus` caveats

`omarchy-launch-or-focus <window-pattern> <launch-command>` matches
`<window-pattern>` as a regex on `class` or `title`. Two footguns:

1. The pattern is regex. `org.gnome.Calculator` is interpreted as
   "any char" between every letter. Use the simple word
   `Calculator` instead.
2. The second arg is a **binary command**, not a class. Use
   `gnome-calculator`, not `org.gnome.Calculator`.

The Calculator bind in this file follows the correct pattern:
`omarchy-launch-or-focus Calculator gnome-calculator`.

## Idle and lock (`hypridle.conf`)

Custom: no screensaver, no display-off after idle. The screen goes
straight to lock when triggered, then unlock on wake.

```ini
general {
    lock_cmd = omarchy-system-lock
    before_sleep_cmd = OMARCHY_LOCK_ONLY=true omarchy-system-lock
    after_sleep_cmd = sleep 1 && omarchy-system-wake
    inhibit_sleep = 3
}
```

The original Omarchy listeners (screensaver at 150s, lock at 152s) are
kept commented for reference. Reason for removal: the user does not
want the screensaver behavior at all.

## Validation

After any change to a `*.conf` in this directory:

```bash
hyprctl reload
hyprctl configerrors
```

`reload` returns `ok` on success. `configerrors` must be empty.
Hyprland auto-reloads on save for most files; `reload` is still
recommended to surface errors immediately. See
[symlinks.md](symlinks.md#validating-changes) for the full workflow.

## Syntax compatibility

Hyprland 0.55+ introduced a new lua-based config syntax. The existing
hyprlang syntax used in these files (sections with `{}`, `bindd`,
`windowrule`) continues to work in 0.55.x as a compatibility mode.
Key changes that affected this config:

| Old (hyprlang) | New (0.55+) | Status in this repo |
| --- | --- | --- |
| `windowrulev2 = ...` | `windowrule = ...` | Migrated. `windowrule` is the unified keyword. |
| `center` | `center 1` | Now requires explicit bool. |
| `enabled = yes/no` | `enabled = true/false` | Idiomatically `true/false`, both still parse. |

Migration to the full lua syntax (`hl.config({...})`) is not done yet
and is not required while Omarchy stays on 0.55.x.
