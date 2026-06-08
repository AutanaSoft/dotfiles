# Starship Guide

This prompt is organized by module groups, but keeps the original behavior intact.

## Quick Path

1. Install `starship`.
2. Copy `config/starship.toml` to `~/.config/starship.toml`.
3. Open a new shell.

## File

| File | Purpose |
| --- | --- |
| `config/starship.toml` | Prompt configuration |

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
