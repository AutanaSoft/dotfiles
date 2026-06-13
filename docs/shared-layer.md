# `shared/` — config layer shared across environments

This directory holds config files that are **identical (or canonical-resolved to omarchy)** across both `omarchy/` and `wsl2-fedora/` environments. For tools fully shared across envs (`zellij/`, `nvim/`, `starship.toml`), the per-env path at `<env>/config/<tool>/` is a **relative folder symlink** into this directory.

The live `~/.config/...` paths in the omarchy env are also symlinks into the per-env repo path, which in turn symlinks into `shared/`. The repo is the source of truth; the live copy is never edited.

## Canonical source rule

For any file in `shared/`, the **omarchy content is the source of truth** (refined rev 2, 2026-06-10). If the wsl2 working copy of a shared file ever diverges from omarchy, the shared file is authored from the omarchy version; wsl2-specific content is either folded in (and recorded in the PR description) or kept as a documented per-env override.

## Symlink model

For tools fully shared across envs (`zellij/`, `nvim/`, `starship.toml`) the symlink is at the **tool
folder** level, so one symlink per env exposes the whole tool tree:

```
~/.config/<x>/<f>  →  <env-repo>/config/<x>/      →  ../../shared/<x>/
```

Symlinks are **relative**, so the repo can be cloned or moved without breaking the chain. Tracked in git, never absolute.

## Tracking policy

The repo's standing tracking policy applies inside `shared/`: **only files that diverge from environment defaults are tracked**. A file in `shared/` MUST diverge from the upstream default of its tool; default-identical files are not added.

## Forbidden content

The following content MUST NOT be placed in `shared/`:

- **Omarchy source** — any file under `~/.local/share/omarchy/` is system-managed and overwritten by `omarchy update`.
- **Per-host secrets** — SSH private keys, `~/.ssh/known_hosts`, machine-specific tokens, per-host `~/.gitconfig` with a hardcoded user email.
- **Per-terminal / per-shell configs that legitimately differ** — `.zshrc` vs `.bashrc`, Alacritty vs WezTerm configs, shell completion scripts, env-specific keybindings.
- **Hyprland, Mako, Waybar, Walker** — these are omarchy-only and never shared.
- **Custom Omarchy theme assets** — `config/omarchy/themes/tokyo-night-autana/*` is omarchy-specific.

## Mapping table (overview)

`<env>` is one of `omarchy`, `wsl2-fedora` (or any future env added at repo root). `nvim/` and `zellij/` are
**folder symlinks** so the mapping collapses to one row per tool:

| Env path                       | Shared path          | Mechanism | Notes                                                  |
| ------------------------------ | -------------------- | --------- | ------------------------------------------------------ |
| `<env>/config/zellij/`         | `shared/zellij/`     | symlink   | canonical config, themes, layouts, and `.wasm` plugins |
| `<env>/config/nvim/`           | `shared/nvim/`       | symlink   | LazyVim config, lockfile, LICENSE, and runtime files   |
| `<env>/config/starship.toml`   | `shared/starship.toml` | symlink | bit-identical                                          |

Adding a new env (e.g. `cachyos/`) only requires:

1. Creating `cachyos/config/`.
1. Symlinking the shared tools: `ln -s ../../shared/nvim cachyos/config/nvim` (same for `zellij`,
   `starship.toml`).
1. Adding any env-specific tools to `cachyos/config/` directly.

No row-per-file updates to this table are needed because the symlink is at the **tool folder**
level, not at the file level.

## Home directory exception

The mapping table above covers `config/<tool>/` folder symlinks. `shared/home/.ssh/config` is the one exception: a safe tracked SSH template, read directly by env setup and copied to `~/.ssh/config` only when the target is missing. The local file always wins — it is never overwritten and never symlinked. See [docs/ssh.md](ssh.md).

For daily Zellij usage and keybindings, see [`docs/zellij.md`](zellij.md).
