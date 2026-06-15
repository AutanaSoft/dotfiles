# Setup

`./setup` prepares this dotfiles repo for a target environment. It is the
recommended entrypoint for new-machine setup because it chooses the right helper
script, passes the expected paths, and cleans up its temporary environment
variables when it exits.

## Quick Path

```bash
./setup --omarchy  # configure Omarchy / CachyOS + Omarchy
```

## Accepted Flags

| Flag        | Result                                                                     |
| ----------- | -------------------------------------------------------------------------- |
| `--omarchy` | Runs the Omarchy setup flow: dependencies, fonts, then environment config. |
| `--fedora`  | Prints a not-implemented message and exits successfully.                   |
| `--fonts`   | Installs Nerd Fonts only. Does not configure an environment.               |
| `--deps`    | Installs OS dependencies only. The dependency script detects the system.   |
| `--dry-run` | Shows the distro setup actions without mutating the system.                |
| `--help`    | Prints usage help.                                                         |

## Valid Combinations

- Use one environment flag at a time: `--omarchy` or `--fedora`, not both.
- `--fonts` and `--deps` can run alone.

## Dependency Detection

`./setup --deps` delegates to `scripts/setup-deps`, which detects the local
system by checking package managers on `PATH`:

| Found             | Environment        |
| ----------------- | ------------------ |
| `yay` or `pacman` | Arch-like system   |
| `dnf` or `rpm`    | Fedora-like system |

If detection is wrong for an unusual host, run the helper directly with an
explicit override:

```bash
scripts/setup-deps --omarchy
scripts/setup-deps --fedora
```

## Verification

Run the repo-native setup tests:

```bash
bash tests/setup-deps.bash
```

The tests use temporary directories and command stubs, so they do not install
packages or modify your real home configuration.

## Related Files

- `setup` — root entrypoint.
- `scripts/setup-omarchy` — Omarchy setup flow.
- `scripts/setup-deps` — OS package dependency installer.
- `scripts/setup-fonts` — Nerd Fonts installer.
- `tests/setup-deps.bash` — behavior tests.
