# `shared/` layer

Canonical config shared across environments. `shared/` content is
authored from Omarchy and re-used by `fedora/` (or any future env
added at repo root). Per-env paths under `<env>/config/<tool>/` are
**relative folder symlinks** into `shared/`, so the whole tool tree
is exposed with one symlink per env.

## Symlink model

```
~/.config/<x>/<f>  →  <env>/config/<x>/  →  ../../shared/<x>/
```

Symlinks are relative, tracked in git, and never absolute. The repo
is the source of truth; live files are never edited.

## Tracking policy

Only files that diverge from upstream defaults are tracked. A file in
`shared/` MUST differ from its tool's default; default-identical
files are not added.

## Mapping

| Env path                     | Shared path            | Notes                                   |
| ---------------------------- | ---------------------- | --------------------------------------- |
| `<env>/config/zellij/`       | `shared/zellij/`       | config, themes, layouts, `.wasm` plugins |
| `<env>/config/nvim/`         | `shared/nvim/`         | LazyVim config, lockfile, runtime files |
| `<env>/config/starship.toml` | `shared/starship.toml` | bit-identical                            |

The symlink is at the **tool folder** level, not file level, so
adding a new tool to `shared/` does not require per-env changes.

## Adding a new environment

1. Create `<new-env>/config/`.
2. Symlink shared tools:
   `ln -s ../../shared/<tool> <new-env>/config/<tool>` (e.g. `nvim`,
   `zellij`, `starship.toml`).
3. Add env-specific tools under `<new-env>/config/` directly.

## SSH template exception

`shared/home/.ssh/config` is the one tracked file under `shared/home/`.
It is a **safe placeholder template** (no secrets, no real hostnames)
that setup copies to `~/.ssh/config` only when the target is missing.
The local file always wins — it is never overwritten and never
symlinked. See [`docs/ssh.md`](ssh.md).

## Forbidden content

Do not place any of the following in `shared/`:

- Omarchy source — `~/.local/share/omarchy/` is overwritten by
  `omarchy update`.
- Per-host secrets — SSH private keys, `known_hosts`, machine tokens,
  per-host git user/email.
- Per-shell or per-terminal config that legitimately differs
  (`.zshrc` vs `.bashrc`, Alacritty vs WezTerm, shell completion).
- Omarchy-only tools — Hyprland, Mako, Waybar, Walker, custom
  Omarchy theme assets.

## See also

- [`docs/ssh.md`](ssh.md) — SSH template and per-host rules.
- [`docs/zellij.md`](zellij.md) — daily Zellij usage and keybindings.
- [`AGENTS.md`](../AGENTS.md) — repo conventions.
