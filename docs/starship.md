# Starship Guide

This prompt is organized by module groups, but keeps the original behavior intact. The same
`shared/starship.toml` is used in both `omarchy/` and `wsl2-fedora/` via the shared layer
(omarchy-canonical). See [`docs/shared-layer.md`](shared-layer.md) for the mapping.

## Quick Path

1. Install `starship`.
2. The dotfiles symlink `~/.config/starship.toml` to `shared/starship.toml` (already set up
   by `omarchy refresh` on Omarchy, or by following the WSL2 setup in
   [`wsl2-fedora/README.md`](../wsl2-fedora/README.md#setup-on-a-new-machine)).
3. Open a new shell.

## File

| File | Purpose |
| --- | --- |
| `shared/starship.toml` | Prompt configuration (canonical, used by both envs) |

## Organization

| Section | Purpose |
| --- | --- |
| `Schema` | Editor schema support |
| `Prompt` | Global prompt behavior |
| `Core Modules` | User, host, shell, status, time |
| `Cloud And Containers` | AWS, Azure, Docker, Kubernetes, and similar contexts |
| `Git And VCS` | Branch, status, commit, metrics |
| `Environments And Toolchains` | `mise`, shells, env managers |
| `Languages And Frameworks` | Language-specific version modules |

## Notes

- The config standardizes `format` strings across many modules.
- The file is intentionally grouped for readability, not minimalism.
- If you want to change how the prompt looks, start with `character`, `git_branch`, `git_status`, `username`, and `time`.

## Related Files

- `config/starship.toml`
- `home/.zshrc`
