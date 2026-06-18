# Delta para Setup Orchestration — `repo-structure-omarchy-reorg`

## Propósito del delta

Delta para el reorg de layout del repo a
`src/{home/{config,local},etc/}` + `src/utils/bash/`. Solo se
actualizan referencias de path dentro de los scenarios existentes
de la spec principal; no se agregan requirements nuevos, no se
eliminan requirements, no se renombran requirements. La fila
`DOTFILES_ENV` en la tabla de variables (Requirement: "Exported
variable contract") queda **byte-idéntica** por resolución del
change `omarchy-only-scope` (2026-06-18): el valor `omarchy` de la
variable no es un path y no se ve afectado por el reorg.

El semantic del prefix `p-` en Hyprland no cambia: los archivos
`p-*.conf` viven ahora bajo `src/home/config/hypr/` pero siguen
apareciendo en `~/.config/hypr/p-*.conf` vía el symlink map
per-file de `apply_symlinks()`. El updater de Omarchy solo mira
`~/.config/hypr/`, no el path del repo. El semantic `p-` se
mantiene intacto y no se codifica ningún nuevo scenario en esta
delta.

El semantic del SSH template (`src/home/.ssh/config` →
`~/.ssh/config` con copy-only-if-missing, modo 600) se conserva:
el source path se mueve, el copy semantics queda sin cambio. No
se modifica el scenario correspondiente porque la spec solo
describe el comportamiento, no el path del template.

Las cross-refs del spec a `cleanup-omarchy` (si existen) se
renombran a `src/utils/bash/cleanup`. Una revisión del main spec
no encontró referencias directas al nombre viejo; los consumers
del script son externos a esta spec.

## Reorg a `src/{home/{config,local},etc/}`

Todas las ediciones siguientes pertenecen al mismo reorg. Se
agrupan bajo este heading para que la review pueda caminar el
cambio completo en una sola pasada. La semántica observable
para el usuario no cambia: los 14 symlinks vivos siguen
resolviendo a los mismos targets, solo que ahora viven bajo
`src/home/config/` en vez de `omarchy/config/`.

## MODIFIED Requirements

### Purpose

Contrato público del entrypoint raíz `./setup`, del ejecutor
de env `src/utils/bash/setup-dots`, y de los scripts auxiliares
`src/utils/bash/setup-deps` y `src/utils/bash/setup-fonts`.
La raíz es un dispatcher delgado; los scripts de env son dueños
del flujo completo del env; `setup-deps` auto-detecta el host.
No existe un spec canónico base bajo `openspec/specs/`; este
archivo es el delta completo para la capability
`setup-orchestration`.

(Previously: paths del ejecutor de env y de los scripts auxiliares
eran `scripts/setup-omarchy`, `scripts/setup-deps`,
`scripts/setup-fonts`; el reorg los mueve a `src/utils/bash/` y
renombra el ejecutor de env a `setup-dots`.)

### Quick path

| Invocation | Root does | Env script does |
| --- | --- | --- |
| `./setup --dots` | export paths, trap, invoke `src/utils/bash/setup-dots`, exit 0 | verify deps, install fonts, apply env |
| `./setup --dots --fonts` | same as `--dots` (absorbed) | env script handles fonts |
| `./setup --dots --deps` | same as `--dots` (absorbed) | env script handles deps (auto-detect) |
| `./setup --fonts` | invoke `src/utils/bash/setup-fonts` directly, exit 0 | — (idempotent) |
| `./setup --deps` | invoke `src/utils/bash/setup-deps` directly, exit 0 | — (auto-detects host) |
| `--help` / `-h` | print usage, exit 0 | — |

On any exit path, the trap unsets the five `DOTFILES_*` variables
(see Cleanup below).

(Previously: paths del target script eran `scripts/setup-omarchy`,
`scripts/setup-fonts`, `scripts/setup-deps`.)

### Requirement: Root is a thin dispatcher

The root `./setup` script MUST be a thin dispatcher: it parses
flags, validates them, defines and exports the path variables
required by child scripts, registers an `EXIT` trap to clean those
variables, and invokes exactly one of `src/utils/bash/setup-dots`,
`src/utils/bash/setup-fonts`, `src/utils/bash/setup-deps`, or
prints a not-implemented message for `--fedora`. It MUST NOT
execute a multi-step `deps → fonts → env` pipeline; it MUST NOT
define `run_deps` / `run_fonts` / `run_env` helpers; it MUST NOT
maintain a `TOTAL_STEPS` counter.

(Previously: ejecutor de env era `scripts/setup-omarchy`; renombrado
a `src/utils/bash/setup-dots`. Helper scripts se mueven a
`src/utils/bash/` pero conservan su nombre.)

#### Scenario: root invokes exactly one env script

- GIVEN `./setup --dots` (with or without `--fonts` / `--deps` / `--dry-run`)
- WHEN the dispatcher runs
- THEN it invokes `src/utils/bash/setup-dots` exactly once and exits 0

#### Scenario: root does not drive a pipeline

- GIVEN the source of `./setup`
- WHEN inspected
- THEN it contains no `run_deps`, `run_fonts`, `run_env`, or `TOTAL_STEPS` symbols, and no `deps → fonts → env` sequence

### Requirement: Flag contract and precedence

The dispatcher MUST accept `--dots`, `--fonts`,
`--deps`, `--dry-run`, `--help`, `-h`. Unknown flags MUST cause a
non-zero exit after printing usage to stderr. No arguments MUST
cause a non-zero exit after printing usage.

| Flag | Effect |
| --- | --- |
| `--dots` | Dispatch to `src/utils/bash/setup-dots` |
| `--fonts` | Dispatch to `src/utils/bash/setup-fonts` |
| `--deps` | Dispatch to `src/utils/bash/setup-deps` |
| `--dry-run` | Set `DOTFILES_DRY_RUN=1`; env scripts honor it |
| `--help` / `-h` | Print usage, exit 0 |

(Previously: target paths eran `scripts/setup-omarchy`,
`scripts/setup-fonts`, `scripts/setup-deps`.)

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

### Requirement: --dots dispatch and env-script ownership

`./setup --dots` (alone or combined with `--fonts` and/or
`--deps`) MUST invoke `src/utils/bash/setup-dots` exactly once.
The `--fonts` and `--deps` flags are absorbed by the dispatcher;
the env script decides whether to invoke `setup-fonts` and
`setup-deps` internally. The env script MUST:

1. Verify `omarchy` and `hyprctl` are on `PATH` (non-mutating).
2. Invoke `src/utils/bash/setup-deps` as a sub-process, passing
   `$DOTFILES_DRY_RUN`.
3. Invoke `src/utils/bash/setup-fonts` as a sub-process, passing
   `$DOTFILES_DRY_RUN`.
4. Pre-flight `$DOTFILES_FONTS_DIR` (non-mutating: directory exists
   and is non-empty); fail with a clear message if absent.
5. Apply symlinks, validate the system, and emit "Setup complete".
6. Maintain its own `TOTAL_STEPS` / `current_step` counter for
   `Step 1/N` … `N/N` labels.

The env script MUST invoke sub-scripts as subprocesses (not
`source`) so the exported `DOTFILES_*` variables cross the process
boundary cleanly and the trap scope stays local to the dispatcher.

(Previously: ejecutor de env era `scripts/setup-omarchy`;
renombrado a `src/utils/bash/setup-dots`. Helper scripts se
mueven a `src/utils/bash/`.)

#### Scenario: --dots invokes setup-dots once

- GIVEN `./setup --dots` (with or without `--fonts`, `--deps`, `--dry-run`)
- WHEN the dispatcher runs
- THEN `src/utils/bash/setup-dots` is invoked exactly once, and its own sub-script log shows `setup-deps` and `setup-fonts` invocations in that order

#### Scenario: --dots --fonts is absorbed

- GIVEN `./setup --dots --fonts`
- WHEN the dispatcher runs
- THEN root invokes `src/utils/bash/setup-dots` once and does not invoke `src/utils/bash/setup-fonts` itself; the env script decides whether to call `setup-fonts`

#### Scenario: pre-flight blocks env config on missing fonts

- GIVEN `src/utils/bash/setup-dots` runs directly (bypassing the dispatcher) and `$DOTFILES_FONTS_DIR` is missing or empty
- WHEN the env script reaches the pre-flight
- THEN it exits non-zero with a message naming the missing fonts directory, and no symlink under `$HOME/.config/` is created or replaced

#### Scenario: pre-flight is non-mutating

- GIVEN the pre-flight check executes
- WHEN observed
- THEN it performs no install, copy, download, or `pacman`/`dnf` invocation; it only checks directory existence and contents

### Requirement: --fonts and --deps direct dispatch

`./setup --fonts` MUST invoke `src/utils/bash/setup-fonts`
directly, and nothing else. `./setup --deps` MUST invoke
`src/utils/bash/setup-deps` directly, and nothing else. The
dispatcher MUST NOT run a pre-flight of its own for these
convenience paths; the sub-scripts are responsible for their own
checks.

(Previously: target paths eran `scripts/setup-fonts` y
`scripts/setup-deps`.)

#### Scenario: --fonts runs only setup-fonts

- GIVEN `./setup --fonts` (with or without `--dry-run`)
- WHEN the dispatcher runs
- THEN `src/utils/bash/setup-fonts` is invoked exactly once, and `setup-deps` and `src/utils/bash/setup-dots` are not invoked

#### Scenario: --deps runs only setup-deps

- GIVEN `./setup --deps` (with or without `--dry-run`)
- WHEN the dispatcher runs
- THEN `src/utils/bash/setup-deps` is invoked exactly once, and `setup-fonts` and `src/utils/bash/setup-dots` are not invoked

### Requirement: setup-deps auto-detection

`src/utils/bash/setup-deps` MUST auto-detect the host environment
by probing package managers in a fixed order, when no explicit
env flag is passed.

| Probe | Resolved env | Notes |
| --- | --- | --- |
| `command -v yay` | `omarchy` | Yay is the documented Omarchy AUR helper |
| `command -v pacman` | `omarchy` | Warn that `yay` is missing |
| none | (fail) | Clear error: "Could not detect a supported package manager (yay, pacman). Install one and re-run." |

Detection is purely a probe — no install side effects, no
recursive self-install. When detection fails, the script MUST
exit non-zero with the message above.

(Previously: path era `scripts/setup-deps`.)

#### Scenario: yay present resolves to omarchy

- GIVEN `yay` is on `PATH` and no env flag is passed
- WHEN `src/utils/bash/setup-deps` runs
- THEN it uses the Omarchy package list and the `pacman -Q`/`pacman -S` commands

#### Scenario: pacman without yay resolves to omarchy with warning

- GIVEN `pacman` is on `PATH` and `yay` is not
- WHEN `src/utils/bash/setup-deps` runs
- THEN it uses the Omarchy package list and emits a warning that `yay` is missing

#### Scenario: no package manager fails clearly

- GIVEN no `yay` or `pacman` is on `PATH` and no env flag is passed
- WHEN `src/utils/bash/setup-deps` runs
- THEN it exits non-zero with the "Could not detect a supported package manager" message

### Requirement: setup-deps explicit override

`--dots` MUST remain a valid argument to
`src/utils/bash/setup-deps` and acts as an explicit override of
the auto-detection. When passed, the probe is skipped and the
Omarchy env is forced. The override is useful for non-standard
hosts, ambiguous chroots, and deterministic test fixtures. No
other env override is recognized: any other env name is rejected
as an unknown argument and exits 2 with the usage text.

(Previously: path era `scripts/setup-deps`.)

#### Scenario: --dots overrides detection

- GIVEN a non-Omarchy package manager (or none) is on `PATH` and `src/utils/bash/setup-deps --dots` runs
- WHEN the script processes flags
- THEN it skips detection, uses the Omarchy package list, and does not consult any other package manager

### Requirement: setup-deps single-pass batch install

`src/utils/bash/setup-deps` MUST collect every missing package,
then invoke the env's package manager exactly once with all
missing packages as positional arguments. Per-package `[ok]` /
`[miss]` lines MUST be preserved, a consolidated batch log line
(e.g. `Installing N missing: ...`) emitted before the call, and
a final `installed` / `present` / `missing` summary line.

(Previously: path era `scripts/setup-deps`.)

#### Scenario: all packages present logs "all present" and skips the install command

- GIVEN every declared package is already installed
- WHEN `src/utils/bash/setup-deps` runs (real or dry-run mode)
- THEN it logs one line containing the words "all present" and exits 0
- AND the env's install command is NOT invoked

#### Scenario: missing packages trigger exactly one install call

- GIVEN one or more declared packages are not installed
- WHEN `src/utils/bash/setup-deps` runs
- THEN the env's package manager is invoked exactly once with every missing package as a positional argument
- AND per-package `[ok]` and `[miss]` lines are still emitted

#### Scenario: install failure aborts with non-zero exit

- GIVEN the single install call exits non-zero
- WHEN `src/utils/bash/setup-deps` runs
- THEN the script exits non-zero on that first failure
- AND no further install attempts are made
- AND the final summary line is not emitted

#### Scenario: final summary reports installed/present/missing

- GIVEN the install phase completed successfully
- WHEN `src/utils/bash/setup-deps` reaches the end of its main flow
- THEN it emits a summary line with `installed`, `present`, and `missing` counts
- AND the `missing` count is 0

### Requirement: setup-fonts honors DOTFILES_FONTS_DIR

`src/utils/bash/setup-fonts` MUST read `$DOTFILES_FONTS_DIR` when
set by the parent process. When unset, it MUST fall back to the
current default (`$HOME/.local/share/fonts/autanasoft`). The
script MUST remain idempotent: re-running it is a no-op when the
target directory already has the expected files.

(Previously: path era `scripts/setup-fonts`.)

#### Scenario: DOTFILES_FONTS_DIR overrides default

- GIVEN `DOTFILES_FONTS_DIR=/custom/fonts` is exported and the directory exists
- WHEN `src/utils/bash/setup-fonts` runs (with or without `--dry-run`)
- THEN it installs to `/custom/fonts`, not `$HOME/.local/share/fonts/autanasoft`

#### Scenario: unset DOTFILES_FONTS_DIR uses default

- GIVEN `DOTFILES_FONTS_DIR` is not set
- WHEN `src/utils/bash/setup-fonts` runs
- THEN it installs to `$HOME/.local/share/fonts/autanasoft`

### Requirement: Input-devices packages (Omarchy only)

The `OMARCHY_PACKAGES` array in `src/utils/bash/setup-deps` MUST
include `keyd`, `piper`, and `libratbag`. The `libratbag` Arch
package is the canonical install name (it provides `ratbagd`;
installing the standalone `ratbagd` package would conflict).

(Previously: path era `scripts/setup-deps`.)

#### Scenario: Omarchy package list contains the three input-device packages

- GIVEN `src/utils/bash/setup-deps` is on disk
- WHEN the `OMARCHY_PACKAGES` array is read
- THEN it MUST contain `keyd`, `piper`, and `libratbag` as entries
- AND the standalone `ratbagd` package MUST NOT be present (it conflicts with `libratbag` on Arch)

#### Scenario: Omarchy dry-run emits a single yay line with all three packages

- GIVEN `src/utils/bash/setup-deps --dots --dry-run` is invoked and at least one of the new packages is missing
- WHEN the install phase runs
- THEN the output contains exactly one `yay -S --needed` line
- AND that line lists `keyd`, `piper`, and `libratbag` as positional arguments

### Requirement: keyd config file in the Omarchy repo layer

`src/etc/keyd/default.conf` MUST exist in the repo and MUST be
authored with the keyd v2.6 vocabulary. The config MUST use the
`noop` action (per keyd v2.6 man page Example 8: `esc = noop;
end = noop`, the documented disable pattern) to silence the
`volumeup` and `volumedown` keys. The config MUST remap the
broken `up` key to `pagedown`. The scope section MUST be
`[ids] *` (universal) so a single keyboard works without
device-specific IDs; the VID:PID migration path is documented in
the runbook.

(Previously: source path era `omarchy/home/.config/keyd/default.conf`.
Por el reorg, los configs de sistema en `/etc/` ahora viven bajo
`src/etc/`. El symlink contract para `~/.config/keyd/` sigue
intencionalmente ausente: keyd solo lee `/etc/keyd/default.conf`.)

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

### Requirement: setup-dots installs the keyd config and enables input-device services

`src/utils/bash/setup-dots` MUST, on Omarchy only, run a new step
in the env flow that (a) installs the tracked keyd config
(`src/etc/keyd/default.conf`) to `/etc/keyd/default.conf` with
mode `0644` via a privileged copy (NOT a symlink — `/etc/keyd/`
is root-owned and not under the symlink contract), and (b)
enables and starts the `keyd` and `ratbagd` systemd services via
a single coalesced `sudo systemctl enable --now` call. The
service unit names SHOULD be `keyd.service` and `ratbagd.service`;
the design phase MUST verify the exact names with `pacman -Ql`
on the target host. The step MUST honor `DOTFILES_DRY_RUN=1`
(emit preview lines, no mutation). No `~/.config/keyd/` symlink
is created — keyd reads `/etc/keyd/default.conf` only.

(Previously: env script era `scripts/setup-omarchy` (ahora
`src/utils/bash/setup-dots`); source path del keyd config era
`omarchy/home/.config/keyd/default.conf` (ahora
`src/etc/keyd/default.conf`). El symlink map (`apply_symlinks`)
vive ahora en `src/utils/bash/setup-dots` y no incluye un entry
para `~/.config/keyd/`.)

#### Scenario: keyd config is installed to /etc/keyd with mode 0644

- GIVEN `src/utils/bash/setup-dots` runs in real mode on Omarchy
- WHEN the input-devices step executes
- THEN `/etc/keyd/default.conf` exists with mode `0644`
- AND its contents match the repo source at `src/etc/keyd/default.conf` (bit-identical)

#### Scenario: keyd and ratbagd services are enabled and started

- GIVEN `src/utils/bash/setup-dots` runs in real mode on Omarchy
- WHEN the input-devices step executes
- THEN the `keyd` and `ratbagd` systemd services are both enabled and started (one coalesced `sudo systemctl enable --now` call, not two)

#### Scenario: dry-run previews the install and the service enable without mutating

- GIVEN `src/utils/bash/setup-dots` runs in `--dry-run` mode on Omarchy
- WHEN the input-devices step executes
- THEN it emits preview lines naming both the install command and the service-enable command
- AND no file is written under `/etc/keyd/` and no `systemctl` call mutates the system

#### Scenario: no home symlink for keyd

- GIVEN the env-script symlink map (`apply_symlinks` in `src/utils/bash/setup-dots`)
- WHEN it is reviewed
- THEN it MUST NOT include a `~/.config/keyd/` symlink (keyd reads `/etc/keyd/default.conf` only)

## NO ADDED, NO REMOVED, NO RENAMED

Por construcción del reorg (reorganización pura del layout, sin
cambio de comportamiento observable para el usuario ni extensión
del contrato):

- **ADDED**: ninguno. El reorg es renombrado + movido, no un
  cambio de capacidad. El install path de `/etc/keyd/` ya estaba
  cubierto por el requirement
  "setup-omarchy installs the keyd config and enables input-device
  services" (renombrado aquí a "setup-dots installs...").
- **REMOVED**: ninguno. Cada requirement de la spec principal
  conserva su semántica. El único path-level removal
  (`omarchy/config/nvim` como symlink a `../../shared/nvim`) se
  cubre por la consolidación del path en
  `src/home/config/nvim` — no es un requirement removal.
- **RENAMED**: ninguno. Los nombres de los requirements no
  cambian, solo los paths referenciados dentro. El único nombre
  que se renombra a nivel de script (`setup-omarchy` →
  `setup-dots`) está capturado dentro de los requirements
  modificados.
