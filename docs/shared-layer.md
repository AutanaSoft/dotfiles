# `src/home/config/` layer

Canonical config for the Omarchy environment, tracked in
`src/home/config/`. The folder is the single source of truth for every
managed `~/.config/<tool>/` symlink. No `<env>/` or `shared/` indirection —
the env is the layout.

## Symlink model

```
~/.config/<x>/<f>  →  src/home/config/<x>/<f>
```

Symlinks are absolute paths into the repo (created by
`src/utils/bash/setup-dots` via `ln -sfn`); the repo is the source of
truth; live files are never edited.

## Tracking policy

Only files that diverge from upstream defaults are tracked. A file in
`src/home/config/` MUST differ from its tool's default; default-identical
files are not added.

## Mapping

| Repo path                                  | Live path                       | Notes                                |
| ------------------------------------------ | ------------------------------- | ------------------------------------ |
| `src/home/config/zellij/`                  | `~/.config/zellij`              | config, themes, layouts, `.wasm` plugins |
| `src/home/config/nvim/`                    | `~/.config/nvim`                | LazyVim config, lockfile, runtime files |
| `src/home/config/starship.toml`            | `~/.config/starship.toml`       |                                      |
| `src/home/config/hypr/<name>.conf`         | `~/.config/hypr/<name>.conf`    | per-file symlinks; omarchy defaults stay intact |
| `src/home/config/waybar/config.jsonc`      | `~/.config/waybar/config.jsonc` | only the config file is tracked; omarchy owns the rest of `~/.config/waybar/` |
| `src/home/config/alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` |                                  |
| `src/home/config/omarchy/themes/tokyo-night-autana/` | `~/.config/omarchy/themes/tokyo-night-autana/` | personal theme variant         |

## Adding a new tool to the layer

1. Add the file or folder under `src/home/config/<tool>/`.
2. Extend `apply_symlinks()` in `src/utils/bash/setup-dots` to symlink
   the new path into `~/.config/<tool>/`.
3. Update the mapping table above.

## SSH template exception

`src/home/.ssh/config` is the one tracked file under `src/home/.ssh/`.
It is a **safe placeholder template** (no secrets, no real hostnames)
that setup copies to `~/.ssh/config` only when the target is missing.
The local file always wins — it is never overwritten and never
symlinked. See [`docs/ssh.md`](ssh.md).

### Exception: /etc/keyd/default.conf install pattern

`src/etc/keyd/default.conf` is the repo source for the keyd daemon
config. It is **Omarchy only** (Piper and keyd are Omarchy-only; there
is no shared layer). The keyd daemon runs as root and reads only from
`/etc/keyd/`; the user-level path (`~/.config/keyd/`) is unused, so
no `~/.config/keyd/` symlink is created. `src/utils/bash/setup-dots`
copies the tracked file to `/etc/keyd/default.conf` with
`install -m 644` (root-owned, daemon config — not a symlink) on every
env run. This is the second tracked-on-repo-but-not-live-symlink
exception, modeled on the SSH template above. See
[`docs/inputs/keyboard-remap.md`](inputs/keyboard-remap.md) for the
edit-and-reload flow and the VID:PID migration path.

## Forbidden content

Do not place any of the following in `src/home/config/`:

- Omarchy source — `~/.local/share/omarchy/` is overwritten by
  `omarchy update`.
- Per-host secrets — SSH private keys, `known_hosts`, machine tokens,
  per-host git user/email.
- Per-shell or per-terminal config that legitimately differs
  (`.zshrc` vs `.bashrc`, Alacritty vs WezTerm, shell completion).
- Omarchy-only tools — Hyprland, Mako, Waybar, Walker, custom
  Omarchy theme assets (only the per-host overrides above are tracked).

## See also

- [`docs/ssh.md`](ssh.md) — SSH template and per-host rules.
- [`docs/zellij.md`](zellij.md) — daily Zellij usage and keybindings.
- [`AGENTS.md`](../AGENTS.md) — repo conventions.