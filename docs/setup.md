# Setup

`./setup` is the root entrypoint for this repo. It runs safe, repeatable setup
steps from the repo root.

## Commands

| Command | Purpose |
| --- | --- |
| `./setup --fonts` | Install fonts only. |
| `./setup --omarchy --fonts` | Install Omarchy deps, fonts, then apply Omarchy config. |
| `./setup --omarchy` | Install Omarchy deps, then apply Omarchy config. |
| `./setup --fedora` | Install Fedora deps, then warn + skip env (exits 0). |
| `./setup --fedora --fonts` | Install Fedora deps + fonts, then warn + skip env (exits 0). |
| `./setup --dry-run ...` | Preview actions without mutating the system. |
| `./setup --help` | Show all options. |

Order when an env is selected: **deps → fonts → env**. With only `--fonts`,
deps is skipped.

## Scripts

| Script | Role |
| --- | --- |
| `setup` | Root entrypoint and dispatcher. |
| `scripts/setup-deps` | Installs env OS packages (lsof, hunspell + language data, Omarchy zellij, ...). Auto-run when an env flag is passed. |
| `scripts/setup-omarchy` | Applies Omarchy symlinks, SSH seed, theme, and reload. |
| `scripts/setup-fonts` | Installs local Nerd Fonts. |

## Notes

- The dependency step runs automatically with every env flag. There is no
  separate `--deps` flag. `--fonts` alone does not install system packages.
- Fedora setup has no env executor yet. Both `--fedora` and
  `--fedora --fonts` install deps (+ fonts) and then exit 0 with a
  warning instead of failing. Use `fedora/README.md` for manual setup.
- `--dry-run` must not download files, move backups, or modify live configs.
- New env executors belong in `scripts/setup-<env>`.

## Tests

The dispatcher behavior of `./setup` (deps before env, Fedora skip,
fonts-only path) is covered by `tests/setup-deps.bash`. The script
runs the orchestrator in a temp HOME with stubbed package-manager
commands on PATH, so it never installs packages or mutates real user
config.

```bash
bash tests/setup-deps.bash
```

Output is TAP-ish (`ok N - ...` / `not ok N - ...`) and the script
exits 0 on full pass. No external test framework is required.

## Related Files

- `setup`
- `scripts/setup-deps`
- `scripts/setup-omarchy`
- `scripts/setup-fonts`
- `omarchy/README.md`
- `fedora/README.md`
