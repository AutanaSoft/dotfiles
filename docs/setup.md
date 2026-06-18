# Setup

`./setup` prepares this dotfiles repo for a target environment. It is the
recommended entrypoint for new-machine setup because it chooses the right helper
script, passes the expected paths, and cleans up its temporary environment
variables when it exits.

## Quick Path

```bash
./setup --dots  # configure Omarchy / CachyOS + Omarchy
```

## Accepted Flags

| Flag        | Result                                                                     |
| ----------- | -------------------------------------------------------------------------- |
| `--dots`    | Runs the Omarchy setup flow: dependencies, fonts, then environment config. |
| `--fonts`   | Installs Nerd Fonts only. Does not configure an environment.               |
| `--deps`    | Installs OS dependencies only. The dependency script detects the system.   |
| `--dry-run` | Shows the distro setup actions without mutating the system.                |
| `--help`    | Prints usage help.                                                         |

## Dependency Detection

`./setup --deps` delegates to `src/utils/bash/setup-deps`, which detects the local
system by checking package managers on `PATH`:

| Found             | Environment        |
| ----------------- | ------------------ |
| `yay` or `pacman` | Omarchy-family     |

If detection is wrong for an unusual host, run the helper directly with an
explicit override:

```bash
src/utils/bash/setup-deps --omarchy
```

Dependencies are installed in a single batch. A single `yay` invocation
produces one install confirmation for the whole batch.

## Verification

Run the repo-native setup tests:

```bash
bash tests/setup-deps.bash
```

The tests use temporary directories and command stubs, so they do not install
packages or modify your real home configuration.

## Related Files

- `setup` — root entrypoint.
- `src/utils/bash/setup-dots` — Omarchy setup flow.
- `src/utils/bash/setup-deps` — OS package dependency installer.
- `src/utils/bash/setup-fonts` — Nerd Fonts installer.
- `src/utils/bash/cleanup` — selectively remove Omarchy preinstalls.
- `tests/setup-deps.bash` — behavior tests.
