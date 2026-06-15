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
| `./setup --fedora` (any combo) | print "not implemented", exit 0; never invokes sub-scripts | — |
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

The dispatcher MUST accept `--omarchy`, `--fedora`, `--fonts`,
`--deps`, `--dry-run`, `--help`, `-h`. `--omarchy` and `--fedora`
MUST be mutually exclusive. Unknown flags MUST cause a non-zero
exit after printing usage to stderr. No arguments MUST cause a
non-zero exit after printing usage.

| Flag | Effect |
| --- | --- |
| `--omarchy` | Dispatch to `scripts/setup-omarchy` |
| `--fedora` | Print "not implemented", exit 0 |
| `--fonts` | Dispatch to `scripts/setup-fonts` |
| `--deps` | Dispatch to `scripts/setup-deps` |
| `--dry-run` | Set `DOTFILES_DRY_RUN=1`; env scripts honor it |
| `--help` / `-h` | Print usage, exit 0 |

#### Scenario: --help lists every flag

- GIVEN `./setup --help`
- WHEN the dispatcher parses arguments
- THEN the output lists every flag above and the process exits 0

#### Scenario: mutual exclusion of env flags

- GIVEN `./setup --omarchy --fedora`
- WHEN the dispatcher validates
- THEN it exits non-zero with a usage message naming the conflict

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

### Requirement: --fedora not-implemented behavior

`./setup --fedora` (in any combination, including `--deps`,
`--fonts`, `--dry-run`) MUST print a clear "not implemented"
message, exit 0, and MUST NOT invoke `setup-deps`, `setup-fonts`,
or `setup-omarchy`. No `scripts/setup-fedora` exists yet; this is
explicitly a TODO. The dispatcher's `--fedora` path is a complete
short-circuit: it returns before any sub-process call.

#### Scenario: --fedora exits 0 and skips work

- GIVEN `./setup --fedora` (any combination with `--deps`, `--fonts`, `--dry-run`)
- WHEN the dispatcher runs
- THEN it prints a not-implemented message, exits 0, and no `scripts/setup-fedora`, `setup-deps`, or `setup-fonts` invocation appears in any log

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
| `command -v dnf` | `fedora` | DNF is the canonical Fedora package manager |
| `command -v rpm` | `fedora` | Warn that `dnf` is missing |
| none | (fail) | Clear error: "Could not detect a supported package manager (yay, pacman, dnf, rpm). Install one and re-run." |

Detection is purely a probe — no install side effects, no
recursive self-install. When detection fails, the script MUST
exit non-zero with the message above.

#### Scenario: yay present resolves to omarchy

- GIVEN `yay` is on `PATH` and no env flag is passed
- WHEN `scripts/setup-deps` runs
- THEN it uses the Omarchy package list and the `pacman -Q`/`pacman -S` commands

#### Scenario: dnf present resolves to fedora

- GIVEN `dnf` is on `PATH` (and no `yay`/`pacman`) and no env flag is passed
- WHEN `scripts/setup-deps` runs
- THEN it uses the Fedora package list and the `rpm -q`/`dnf install` commands

#### Scenario: pacman without yay resolves to omarchy with warning

- GIVEN `pacman` is on `PATH` and `yay` is not
- WHEN `scripts/setup-deps` runs
- THEN it uses the Omarchy package list and emits a warning that `yay` is missing

#### Scenario: no package manager fails clearly

- GIVEN no `yay`, `pacman`, `dnf`, or `rpm` is on `PATH` and no env flag is passed
- WHEN `scripts/setup-deps` runs
- THEN it exits non-zero with the "Could not detect a supported package manager" message

### Requirement: setup-deps explicit override

`--omarchy` and `--fedora` MUST remain valid arguments to
`scripts/setup-deps` and act as an explicit override of the auto-
detection. When passed, the probe is skipped and the env is forced.
The override is useful for non-standard hosts, ambiguous chroots,
and deterministic test fixtures.

#### Scenario: --omarchy overrides detection

- GIVEN `dnf` is on `PATH` and `scripts/setup-deps --omarchy` runs
- WHEN the script processes flags
- THEN it skips detection, uses the Omarchy package list, and does not consult `dnf`

#### Scenario: --fedora overrides detection

- GIVEN `yay` is on `PATH` and `scripts/setup-deps --fedora` runs
- WHEN the script processes flags
- THEN it skips detection, uses the Fedora package list, and does not consult `pacman`

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

### Requirement: Documentation and test coverage

`docs/setup.md` MUST be functional user documentation for the
`./setup` entrypoint. It MUST summarize, at minimum: what the script
does, how to invoke it, the accepted flags, what the script does NOT
do (e.g. `--fedora` is not implemented), and how to verify behavior
(including the test command). The detailed implementation contract —
the exact set of exported variables, the dispatcher-vs-env-script
boundary, the flag precedence table, the auto-detection behavior in
`setup-deps`, and the `setup-deps` override flag — lives in OpenSpec
and the scripts themselves; user-facing documentation MUST NOT
contradict the code or omit documented flags. `tests/setup-deps.bash`
MUST cover: root invokes
`setup-omarchy` once; root absorbs `--omarchy --fonts` / `--omarchy
--deps`; `--fedora` (any combo) exits 0 and skips work; `--fonts`
runs only `setup-fonts`; `--deps` runs only `setup-deps`; env
pre-flight blocks on missing fonts; `DOTFILES_*` cleanup fires on
success and on child failure; `setup-deps` auto-detects
`yay`/`pacman` → omarchy, `dnf`/`rpm` → fedora, fails clearly with
no managers; `setup-deps` override flags skip detection. Minimum
`TEST_PLAN=7`.
