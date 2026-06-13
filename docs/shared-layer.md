# `shared/` — config layer shared across environments

This directory holds config files that are **identical (or canonical-resolved to omarchy)** across both `omarchy/` and `wsl2-fedora/` environments. Per-env copies at `omarchy/config/...` and `wsl2-fedora/config/...` are **relative symlinks** into this directory.

The live `~/.config/...` paths in the omarchy env are also symlinks into the per-env repo path, which in turn symlinks into `shared/`. The repo is the source of truth; the live copy is never edited.

## Canonical source rule

For any file in `shared/`, the **omarchy content is the source of truth** (refined rev 2, 2026-06-10). If the wsl2 working copy of a shared file ever diverges from omarchy, the shared file is authored from the omarchy version; wsl2-specific content is either folded in (and recorded in the PR description) or kept as a per-env override outside the symlink chain.

## Symlink chain

```
~/.config/<x>/<f>  →  <env-repo>/config/<x>/<f>  →  ../shared/<x>/<f>
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

| Env path                                                                      | Shared path                                  | Mechanism | Notes                                       |
| ----------------------------------------------------------------------------- | -------------------------------------------- | --------- | ------------------------------------------- |
| `omarchy/config/zellij/config.kdl`                                            | `shared/zellij/config.kdl`                   | symlink   | canonical (post-`pane_frames` decision)     |
| `omarchy/config/zellij/themes/tokyo-night.kdl`                                | `shared/zellij/themes/tokyo-night.kdl`       | symlink   | bit-identical                               |
| `omarchy/config/zellij/themes/tokyo-night-storm.kdl`                          | `shared/zellij/themes/tokyo-night-storm.kdl` | symlink   | bit-identical                               |
| `omarchy/config/zellij/layouts/autanasoft.kdl`                                | `shared/zellij/layouts/autanasoft.kdl`       | symlink   | bit-identical                               |
| `omarchy/config/zellij/plugins/{zellij_forgot,zjframes,zjstatus}.wasm`        | `shared/zellij/plugins/<name>.wasm`          | symlink   | md5 parity preserved                        |
| `wsl2-fedora/config/zellij/...`                                               | `shared/zellij/...`                          | symlink   | same targets as omarchy                     |
| `omarchy/config/starship.toml`                                                | `shared/starship.toml`                       | symlink   | bit-identical                               |
| `wsl2-fedora/config/starship.toml`                                            | `shared/starship.toml`                       | symlink   | same target as omarchy                      |
| `omarchy/config/nvim/stylua.toml`                                             | `shared/nvim/stylua.toml`                    | symlink   | omarchy canonical                           |
| `wsl2-fedora/config/nvim/stylua.toml`                                         | `shared/nvim/stylua.toml`                    | symlink   | same target as omarchy                      |
| `omarchy/config/nvim/init.lua`                                                | `shared/nvim/init.lua`                       | symlink   | omarchy canonical                           |
| `wsl2-fedora/config/nvim/init.lua`                                            | `shared/nvim/init.lua`                       | symlink   | same target as omarchy                      |
| `omarchy/config/nvim/lazyvim.json`                                            | `shared/nvim/lazyvim.json`                   | symlink   | omarchy canonical; extras identical         |
| `wsl2-fedora/config/nvim/lazyvim.json`                                        | `shared/nvim/lazyvim.json`                   | symlink   | same target as omarchy                      |
| `omarchy/config/nvim/lazy-lock.json`                                          | `shared/nvim/lazy-lock.json`                 | symlink   | **shared lockfile** — no per-env duplicates |
| `wsl2-fedora/config/nvim/lazy-lock.json`                                      | `shared/nvim/lazy-lock.json`                 | symlink   | same target as omarchy                      |
| `omarchy/config/nvim/.neoconf.json`                                           | `shared/nvim/.neoconf.json`                  | symlink   | omarchy canonical                           |
| `wsl2-fedora/config/nvim/.neoconf.json`                                       | `shared/nvim/.neoconf.json`                  | symlink   | same target as omarchy                      |
| `omarchy/config/nvim/LICENSE`                                                 | `shared/nvim/LICENSE`                        | symlink   | Apache 2.0 (LazyVim attribution)            |
| `wsl2-fedora/config/nvim/LICENSE`                                             | `shared/nvim/LICENSE`                        | symlink   | same target as omarchy                      |
| `omarchy/config/nvim/plugin/after/transparency.lua`                           | `shared/nvim/plugin/after/transparency.lua`  | symlink   | makes highlight groups transparent          |
| `wsl2-fedora/config/nvim/plugin/after/transparency.lua`                       | `shared/nvim/plugin/after/transparency.lua`  | symlink   | same target as omarchy                      |
| `omarchy/config/nvim/lua/config/{lazy,autocmds,keymaps,lint,options}.lua`     | `shared/nvim/lua/config/<name>.lua`          | symlink   | omarchy canonical                           |
| `wsl2-fedora/config/nvim/lua/config/{lazy,autocmds,keymaps,lint,options}.lua` | `shared/nvim/lua/config/<name>.lua`          | symlink   | same target as omarchy                      |
| `omarchy/config/nvim/lua/plugins/*.lua`                                       | `shared/nvim/lua/plugins/<name>.lua`         | symlink   | omarchy canonical                           |
| `wsl2-fedora/config/nvim/lua/plugins/*.lua`                                   | `shared/nvim/lua/plugins/<name>.lua`         | symlink   | same target as omarchy                      |
| `omarchy/config/nvim/markdownlint.json`                                       | `shared/nvim/markdownlint.json`              | symlink   | read by `nvim-lint` via `stdpath('config')` |
| `wsl2-fedora/config/nvim/markdownlint.json`                                   | `shared/nvim/markdownlint.json`              | symlink   | same target as omarchy                      |

For the zellij-specific mapping (which includes the procedure for adding a new theme or layout), see [`docs/zellij.md`](zellij.md#maintenance).
