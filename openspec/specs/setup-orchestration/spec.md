# Setup Orchestration Specification

## Purpose

Public contract for the root `./setup` entrypoint, the env executor
`scripts/setup-omarchy`, and the helper scripts `scripts/setup-deps`
and `scripts/setup-fonts`. The root is a thin dispatcher; env scripts
own the full env flow; `setup-deps` auto-detects the host. No base
canonical spec exists under `openspec/specs/`; this file is the full
delta for the `setup-orchestration` capability.

## Quick path

| Invocation | Root does | Env script does |
| --- | --- | --- |
| `./setup --omarchy` | export paths, trap, invoke `scripts/setup-omarchy`, exit 0 | verify deps, install fonts, apply env |
| `./setup --omarchy --fonts` | same as `--omarchy` (absorbed) | env script handles fonts |
| `./setup --omarchy --deps` | same as `--omarchy` (absorbed) | env script handles deps (auto-detect) |

| `./setup --fonts` | invoke `scripts/setup-fonts` directly, exit 0 | — (idempotent) |
| `./setup --deps` | invoke `scripts/setup-deps` directly, exit 0 | — (auto-detects host) |
| `--help` / `-h` | print usage, exit 0 | — |

On any exit path, the trap unsets the five `DOTFILES_*` variables
(see Cleanup below).

## Requirements

### Requirement: Root is a thin dispatcher

The root `./setup` script MUST be a thin dispatcher: it parses
flags, validates them, defines and exports the path variables
required by child scripts, registers an `EXIT` trap to clean those
variables, and invokes exactly one of `scripts/setup-omarchy`,
`scripts/setup-fonts`, `scripts/setup-deps`, or prints a
not-implemented message for `--fedora`. It MUST NOT execute a
multi-step `deps → fonts → env` pipeline; it MUST NOT define
`run_deps` / `run_fonts` / `run_env` helpers; it MUST NOT maintain
a `TOTAL_STEPS` counter.

#### Scenario: root invokes exactly one env script

- GIVEN `./setup --omarchy` (with or without `--fonts` / `--deps` / `--dry-run`)
- WHEN the dispatcher runs
- THEN it invokes `scripts/setup-omarchy` exactly once and exits 0

#### Scenario: root does not drive a pipeline

- GIVEN the source of `./setup`
- WHEN inspected
- THEN it contains no `run_deps`, `run_fonts`, `run_env`, or `TOTAL_STEPS` symbols, and no `deps → fonts → env` sequence

### Requirement: Flag contract and precedence

The dispatcher MUST accept `--omarchy`, `--fonts`,
`--deps`, `--dry-run`, `--help`, `-h`. Unknown flags MUST cause a
non-zero exit after printing usage to stderr. No arguments MUST
cause a non-zero exit after printing usage.

| Flag | Effect |
| --- | --- |
| `--omarchy` | Dispatch to `scripts/setup-omarchy` |

| `--fonts` | Dispatch to `scripts/setup-fonts` |
| `--deps` | Dispatch to `scripts/setup-deps` |
| `--dry-run` | Set `DOTFILES_DRY_RUN=1`; env scripts honor it |
| `--help` / `-h` | Print usage, exit 0 |

#### Scenario: --help lists every flag

- GIVEN `./setup --help`
- WHEN the dispatcher parses arguments
- THEN the output lists every flag above and the process exits 0

#### Scenario: unknown flag fails

- GIVEN `./setup --unknown-flag`
- WHEN the dispatcher validates
- THEN it prints an error to stderr and exits non-zero

#### Scenario: no arguments fails

- GIVEN `./setup` with no arguments
- WHEN the dispatcher validates
- THEN it prints usage to stderr and exits non-zero

### Requirement: Exported variable contract

The root dispatcher MUST resolve and export exactly five variables
before dispatching. Child scripts MUST read these variables and
MUST NOT re-derive repo root or the fonts directory.

| Variable | Type | Set by | Default | Consumed by |
| --- | --- | --- | --- | --- |
| `DOTFILES_ROOT` | absolute path | root | required (no fallback) | env scripts, sub-scripts |
| `DOTFILES_ENV` | `omarchy` | root | unset when no env selected | env scripts (logging); `setup-deps` (optional override) |
| `DOTFILES_DRY_RUN` | `1` or unset | root | unset (live mode) | env scripts, sub-scripts |
| `DOTFILES_BACKUP_DIR` | absolute path | root | required when env selected | env scripts (backup-before-replace) |
| `DOTFILES_FONTS_DIR` | absolute path | root | `$HOME/.local/share/fonts/autanasoft` | `setup-fonts` (install base), env scripts (pre-flight) |

`DOTFILES_ROOT` is derived from `${BASH_SOURCE[0]}` so resolution is
CWD-independent. `DOTFILES_BACKUP_DIR` is `$DOTFILES_ROOT/backup/<utc-ts>/`
per run. `DOTFILES_FONTS_DIR` is centralized in the root so the
literal `$HOME/.local/share/fonts/autanasoft` appears once, not in
multiple scripts.

#### Scenario: vars are exported before dispatch

- GIVEN `./setup --omarchy`
- WHEN the dispatcher runs
- THEN `printenv DOTFILES_ROOT`, `printenv DOTFILES_FONTS_DIR`, and the other three return non-empty values, and the invoked env script sees them in its environment

#### Scenario: DOTFILES_FONTS_DIR default is computed once

- GIVEN `$HOME/.local/share/fonts/autanasoft` does not yet exist
- WHEN the dispatcher runs with no override
- THEN `DOTFILES_FONTS_DIR` equals `$HOME/.local/share/fonts/autanasoft` and child scripts use that path

### Requirement: Cleanup of exported variables

The dispatcher MUST register `trap 'unset …' EXIT` that unsets all
five `DOTFILES_*` variables on every exit path: success, child
script failure, validation error, and interrupt.

```bash
trap 'unset DOTFILES_ROOT DOTFILES_ENV DOTFILES_DRY_RUN DOTFILES_BACKUP_DIR DOTFILES_FONTS_DIR' EXIT
```

#### Scenario: vars are unset after a successful run

- GIVEN a parent shell invokes `./setup`
- WHEN `./setup` exits 0
- THEN `printenv | grep '^DOTFILES_'` returns no `DOTFILES_*` line set by the dispatcher

#### Scenario: vars are unset after a child-script failure

- GIVEN the dispatched env script exits non-zero
- WHEN the dispatcher returns
- THEN `printenv | grep '^DOTFILES_'` returns no `DOTFILES_*` line set by the dispatcher

### Requirement: --omarchy dispatch and env-script ownership

`./setup --omarchy` (alone or combined with `--fonts` and/or
`--deps`) MUST invoke `scripts/setup-omarchy` exactly once. The
`--fonts` and `--deps` flags are absorbed by the dispatcher; the
env script decides whether to invoke `setup-fonts` and `setup-deps`
internally. The env script MUST:

1. Verify `omarchy` and `hyprctl` are on `PATH` (non-mutating).
2. Invoke `scripts/setup-deps` as a sub-process, passing
   `$DOTFILES_DRY_RUN`.
3. Invoke `scripts/setup-fonts` as a sub-process, passing
   `$DOTFILES_DRY_RUN`.
4. Pre-flight `$DOTFILES_FONTS_DIR` (non-mutating: directory exists
   and is non-empty); fail with a clear message if absent.
5. Apply symlinks, validate the system, and emit "Setup complete".
6. Maintain its own `TOTAL_STEPS` / `current_step` counter for
   `Step 1/N` … `N/N` labels.

The env script MUST invoke sub-scripts as subprocesses (not
`source`) so the exported `DOTFILES_*` variables cross the process
boundary cleanly and the trap scope stays local to the dispatcher.

#### Scenario: --omarchy invokes setup-omarchy once

- GIVEN `./setup --omarchy` (with or without `--fonts`, `--deps`, `--dry-run`)
- WHEN the dispatcher runs
- THEN `scripts/setup-omarchy` is invoked exactly once, and its own sub-script log shows `setup-deps` and `setup-fonts` invocations in that order

#### Scenario: --omarchy --fonts is absorbed

- GIVEN `./setup --omarchy --fonts`
- WHEN the dispatcher runs
- THEN root invokes `scripts/setup-omarchy` once and does not invoke `scripts/setup-fonts` itself; the env script decides whether to call `setup-fonts`

#### Scenario: pre-flight blocks env config on missing fonts

- GIVEN `scripts/setup-omarchy` runs directly (bypassing the dispatcher) and `$DOTFILES_FONTS_DIR` is missing or empty
- WHEN the env script reaches the pre-flight
- THEN it exits non-zero with a message naming the missing fonts directory, and no symlink under `$HOME/.config/` is created or replaced

#### Scenario: pre-flight is non-mutating

- GIVEN the pre-flight check executes
- WHEN observed
- THEN it performs no install, copy, download, or `pacman`/`dnf` invocation; it only checks directory existence and contents

### Requirement: --fonts and --deps direct dispatch

`./setup --fonts` MUST invoke `scripts/setup-fonts` directly, and
nothing else. `./setup --deps` MUST invoke `scripts/setup-deps`
directly, and nothing else. The dispatcher MUST NOT run a
pre-flight of its own for these convenience paths; the sub-scripts
are responsible for their own checks.

#### Scenario: --fonts runs only setup-fonts

- GIVEN `./setup --fonts` (with or without `--dry-run`)
- WHEN the dispatcher runs
- THEN `scripts/setup-fonts` is invoked exactly once, and `setup-deps` and `scripts/setup-omarchy` are not invoked

#### Scenario: --deps runs only setup-deps

- GIVEN `./setup --deps` (with or without `--dry-run`)
- WHEN the dispatcher runs
- THEN `scripts/setup-deps` is invoked exactly once, and `setup-fonts` and `scripts/setup-omarchy` are not invoked

### Requirement: --dry-run propagation

`--dry-run` MUST cause the dispatcher to set `DOTFILES_DRY_RUN=1`
in the exported contract. Env scripts and sub-scripts MUST honor
this variable: when set, they print the actions they would take
without mutating the system. The pre-flight checks (command
existence, fonts directory contents) are non-mutating and therefore
MUST run in dry-run mode too.

#### Scenario: dry-run does not mutate

- GIVEN `./setup --omarchy --dry-run`
- WHEN the dispatcher and env script run
- THEN no package install, no font copy, no symlink creation, and no backup write occurs, and the trap still unsets the five `DOTFILES_*` vars

### Requirement: setup-deps auto-detection

`scripts/setup-deps` MUST auto-detect the host environment by
probing package managers in a fixed order, when no explicit env
flag is passed.

| Probe | Resolved env | Notes |
| --- | --- | --- |
| `command -v yay` | `omarchy` | Yay is the documented Omarchy AUR helper |
| `command -v pacman` | `omarchy` | Warn that `yay` is missing |
| none | (fail) | Clear error: "Could not detect a supported package manager (yay, pacman). Install one and re-run." |

Detection is purely a probe — no install side effects, no
recursive self-install. When detection fails, the script MUST
exit non-zero with the message above.

#### Scenario: yay present resolves to omarchy

- GIVEN `yay` is on `PATH` and no env flag is passed
- WHEN `scripts/setup-deps` runs
- THEN it uses the Omarchy package list and the `pacman -Q`/`pacman -S` commands

#### Scenario: pacman without yay resolves to omarchy with warning

- GIVEN `pacman` is on `PATH` and `yay` is not
- WHEN `scripts/setup-deps` runs
- THEN it uses the Omarchy package list and emits a warning that `yay` is missing

#### Scenario: no package manager fails clearly

- GIVEN no `yay` or `pacman` is on `PATH` and no env flag is passed
- WHEN `scripts/setup-deps` runs
- THEN it exits non-zero with the "Could not detect a supported package manager" message

### Requirement: setup-deps explicit override

`--omarchy` MUST remain a valid argument to `scripts/setup-deps`
and acts as an explicit override of the auto-detection. When
passed, the probe is skipped and the Omarchy env is forced. The
override is useful for non-standard hosts, ambiguous chroots,
and deterministic test fixtures. No other env override is
recognized: any other env name is rejected as an unknown
argument and exits 2 with the usage text.

#### Scenario: --omarchy overrides detection

- GIVEN a non-Omarchy package manager (or none) is on `PATH` and `scripts/setup-deps --omarchy` runs
- WHEN the script processes flags
- THEN it skips detection, uses the Omarchy package list, and does not consult any other package manager

### Requirement: setup-deps single-pass batch install

`scripts/setup-deps` MUST collect every missing package, then
invoke the env's package manager exactly once with all missing
packages as positional arguments. Per-package `[ok]` / `[miss]`
lines MUST be preserved, a consolidated batch log line
(e.g. `Installing N missing: ...`) emitted before the call, and
a final `installed` / `present` / `missing` summary line.

#### Scenario: all packages present logs "all present" and skips the install command

- GIVEN every declared package is already installed
- WHEN `scripts/setup-deps` runs (real or dry-run mode)
- THEN it logs one line containing the words "all present" and exits 0
- AND the env's install command is NOT invoked

#### Scenario: missing packages trigger exactly one install call

- GIVEN one or more declared packages are not installed
- WHEN `scripts/setup-deps` runs
- THEN the env's package manager is invoked exactly once with every missing package as a positional argument
- AND per-package `[ok]` and `[miss]` lines are still emitted

#### Scenario: install failure aborts with non-zero exit

- GIVEN the single install call exits non-zero
- WHEN `scripts/setup-deps` runs
- THEN the script exits non-zero on that first failure
- AND no further install attempts are made
- AND the final summary line is not emitted

#### Scenario: final summary reports installed/present/missing

- GIVEN the install phase completed successfully
- WHEN `scripts/setup-deps` reaches the end of its main flow
- THEN it emits a summary line with `installed`, `present`, and `missing` counts
- AND the `missing` count is 0

### Requirement: setup-fonts honors DOTFILES_FONTS_DIR

`scripts/setup-fonts` MUST read `$DOTFILES_FONTS_DIR` when set by
the parent process. When unset, it MUST fall back to the current
default (`$HOME/.local/share/fonts/autanasoft`). The script MUST
remain idempotent: re-running it is a no-op when the target
directory already has the expected files.

#### Scenario: DOTFILES_FONTS_DIR overrides default

- GIVEN `DOTFILES_FONTS_DIR=/custom/fonts` is exported and the directory exists
- WHEN `scripts/setup-fonts` runs (with or without `--dry-run`)
- THEN it installs to `/custom/fonts`, not `$HOME/.local/share/fonts/autanasoft`

#### Scenario: unset DOTFILES_FONTS_DIR uses default

- GIVEN `DOTFILES_FONTS_DIR` is not set
- WHEN `scripts/setup-fonts` runs
- THEN it installs to `$HOME/.local/share/fonts/autanasoft`

### Requirement: Input-devices packages (Omarchy only)

The `OMARCHY_PACKAGES` array in `scripts/setup-deps` MUST
include `keyd`, `piper`, and `libratbag`. The `libratbag` Arch
package is the canonical install name (it provides `ratbagd`;
installing the standalone `ratbagd` package would conflict).

#### Scenario: Omarchy package list contains the three input-device packages

- GIVEN `scripts/setup-deps` is on disk
- WHEN the `OMARCHY_PACKAGES` array is read
- THEN it MUST contain `keyd`, `piper`, and `libratbag` as entries
- AND the standalone `ratbagd` package MUST NOT be present (it conflicts with `libratbag` on Arch)

#### Scenario: Omarchy dry-run emits a single yay line with all three packages

- GIVEN `scripts/setup-deps --omarchy --dry-run` is invoked and at least one of the new packages is missing
- WHEN the install phase runs
- THEN the output contains exactly one `yay -S --needed` line
- AND that line lists `keyd`, `piper`, and `libratbag` as positional arguments

### Requirement: TAP test coverage for the input-devices packages

`tests/setup-deps.bash` test T8 sub-case C substring array
MUST include `keyd`, `piper`, and `libratbag` as substring
assertions against the single `yay -S --needed` line. Minimum
`TEST_PLAN=5`.

#### Scenario: T8 sub-case C substring array contains all three new packages

- GIVEN `tests/setup-deps.bash` T8 sub-case C substring array
- WHEN the test executes
- THEN `keyd`, `piper`, and `libratbag` MUST each appear as a substring assertion against the yay line
- AND any of them missing from the substring array causes the sub-case to fail

### Requirement: keyd config file in the Omarchy repo layer

`omarchy/home/.config/keyd/default.conf` MUST exist in the
repo and MUST be authored with the keyd v2.6 vocabulary. The
config MUST use the `noop` action (per keyd v2.6 man page
Example 8: `esc = noop; end = noop`, the documented disable
pattern) to silence the `volumeup` and `volumedown` keys. The
config MUST remap the broken `up` key to `pagedown`. The
scope section MUST be `[ids] *` (universal) so a single
keyboard works without device-specific IDs; the VID:PID
migration path is documented in the runbook.

#### Scenario: VolUp is silenced at the kernel level

- GIVEN the keyd daemon has loaded the repo config
- WHEN the `volumeup` key is held
- THEN no `volumeup` key event reaches the application (the event is no-op'd by keyd before the input layer forwards it)

#### Scenario: VolDown is silenced at the kernel level

- GIVEN the keyd daemon has loaded the repo config
- WHEN the `volumedown` key is held
- THEN no `volumedown` key event reaches the application

#### Scenario: broken Up key is remapped to PageDown

- GIVEN the keyd daemon has loaded the repo config
- WHEN the broken `up` key is pressed
- THEN the kernel-level `pagedown` event reaches the application (remap applies)

#### Scenario: scope is universal `[ids] *`

- GIVEN the keyd config file
- WHEN the `[ids]` section is read
- THEN it MUST be `*` (universal scope)
- AND the runbook MUST explain how to migrate to `usb:VID:PID` scoping if a second keyboard is added

### Requirement: setup-omarchy installs the keyd config and enables input-device services

`scripts/setup-omarchy` MUST, on Omarchy only, run a new step
in the env flow that (a) installs the tracked keyd config
(`omarchy/home/.config/keyd/default.conf`) to
`/etc/keyd/default.conf` with mode `0644` via a privileged
copy (NOT a symlink — `/etc/keyd/` is root-owned and not
under the symlink contract), and (b) enables and starts the
`keyd` and `ratbagd` systemd services via a single coalesced
`sudo systemctl enable --now` call. The service unit names
SHOULD be `keyd.service` and `ratbagd.service`; the design
phase MUST verify the exact names with `pacman -Ql` on the
target host. The step MUST honor `DOTFILES_DRY_RUN=1` (emit
preview lines, no mutation). No `~/.config/keyd/` symlink is
created — keyd reads `/etc/keyd/default.conf` only.

#### Scenario: keyd config is installed to /etc/keyd with mode 0644

- GIVEN `scripts/setup-omarchy` runs in real mode on Omarchy
- WHEN the input-devices step executes
- THEN `/etc/keyd/default.conf` exists with mode `0644`
- AND its contents match the repo source at `omarchy/home/.config/keyd/default.conf` (bit-identical)

#### Scenario: keyd and ratbagd services are enabled and started

- GIVEN `scripts/setup-omarchy` runs in real mode on Omarchy
- WHEN the input-devices step executes
- THEN the `keyd` and `ratbagd` systemd services are both enabled and started (one coalesced `sudo systemctl enable --now` call, not two)

#### Scenario: dry-run previews the install and the service enable without mutating

- GIVEN `scripts/setup-omarchy` runs in `--dry-run` mode on Omarchy
- WHEN the input-devices step executes
- THEN it emits preview lines naming both the install command and the service-enable command
- AND no file is written under `/etc/keyd/` and no `systemctl` call mutates the system

#### Scenario: no home symlink for keyd

- GIVEN the env-script symlink map (`apply_symlinks` in `scripts/setup-omarchy`)
- WHEN it is reviewed
- THEN it MUST NOT include a `~/.config/keyd/` symlink (keyd reads `/etc/keyd/default.conf` only)

### Requirement: Docs cover the input-devices workflow and the shared-layer exception

`docs/inputs/keyboard-remap.md` MUST exist and cover the keyd
config layout, the edit-and-reload flow (`sudo keyd reload`),
and the `usb:VID:PID` migration path for when a second
keyboard is added. `docs/inputs/mouse-g502.md` MUST exist and
cover the two Piper profiles (Default + Game) for the
Logitech G502 Hero, with the exact button bindings per
profile, and MUST explicitly state that Piper profiles are
written by `ratbagd` over DBus to the mouse's onboard firmware
and are therefore NOT version-controlled. `docs/shared-layer.md`
MUST include a new exception paragraph for the
`/etc/keyd/default.conf` install, modeled on the existing SSH
template exception, and MUST limit the exception to Omarchy
only.

#### Scenario: keyboard runbook covers config layout, reload, and VID:PID migration

- GIVEN `docs/inputs/keyboard-remap.md` is on disk
- WHEN it is read
- THEN it MUST describe the keyd config file location, the `sudo keyd reload` flow, and the `[ids] usb:VID:PID` migration path

#### Scenario: mouse runbook covers two profiles and the firmware-storage caveat

- GIVEN `docs/inputs/mouse-g502.md` is on disk
- WHEN it is read
- THEN it MUST describe two profiles (Default and Game) with their button bindings
- AND it MUST explicitly state that Piper profiles are written to the G502's onboard firmware via DBus and are not version-controlled

#### Scenario: shared-layer doc gets a keyd exception (Omarchy only)

- GIVEN `docs/shared-layer.md` is on disk
- WHEN it is read
- THEN it MUST include an exception paragraph for `/etc/keyd/default.conf` modeled on the existing SSH template exception
- AND the exception MUST be scoped to Omarchy only (no Fedora equivalent)

### Requirement: Documentation and test coverage

`docs/setup.md` MUST document the `./setup` entrypoint,
accepted flags, and the env-selection model; the implementation
contract lives in OpenSpec. `docs/setup.md` MUST also describe
`setup-deps` as a single-pass batch installer.
`tests/setup-deps.bash` MUST cover the thin-dispatcher contract:
root invokes `setup-omarchy` once; root absorbs `--omarchy
--fonts` / `--omarchy --deps`; `--fonts` runs only `setup-fonts`
and `--deps` runs only `setup-deps`; env pre-flight blocks on
missing fonts and honors the `DOTFILES_FONTS_DIR` override;
`DOTFILES_*` cleanup fires on success and on child failure.
Minimum `TEST_PLAN=5`.
