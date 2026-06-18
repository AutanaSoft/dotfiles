# Delta for setup-orchestration — omarchy-only-scope

## Purpose

Delta spec for the `omarchy-only-scope` change. Collapses the
dotfiles repo to Omarchy-family hosts only: stock Omarchy,
CachyOS with the Omarchy layer on top, and Arch with the Omarchy
layer on top. All three variants are treated identically from
this repo's perspective. The Omarchy installer owns
distribution-specific configuration; this repo's only AUR-helper
concern is `yay` (the Omarchy default).

The second environment layer is removed entirely (no local
trace, no comment-out scaffolding, no historical note). The
removed CLI flag is no longer recognized and falls through to
the existing unknown-flag branch (exit 2 with usage on stderr).
`scripts/setup-deps` auto-detection collapses to
`yay` → Omarchy, `pacman` → Omarchy with a `yay`-missing
warning, else fail. `--omarchy` remains as the explicit override
for `scripts/setup-deps`. The auto-detect path covers all three
Omarchy-family variants in one branch; no distribution-specific
logic is encoded in this repo.

CachyOS+Omarchy and Arch+Omarchy are functionally identical
from this repo's perspective. The Omarchy installer handles
the base-distribution differences (kernel, `pacman` config,
bootstrap). This repo's only AUR-helper concern is `yay`.

`tests/setup-deps.bash` is reduced to five tests (T1, T2, T4,
T5, T6). T3 (the env-only short-circuit), T7 (the
auto-detect/override probe), and T8 (the single-pass batch
install per env) are removed entirely. `TEST_PLAN` drops from
8 to 5. The Omarchy-relevant behaviors these tests exercised
remain described in the spec; their automated coverage is
deferred to a future change if needed.

This delta is a single grouped edit under "Omarchy-only scope"
so the change reads as one review pass. No historical notes
are added to the modified text.

## Omarchy-only scope

All edits below belong to the same scope cut. They are grouped
here so a reviewer can walk the whole change in one pass. No
new requirements are added; the change is a removal + a
narrowing of the existing surface to one env.

## MODIFIED Requirements

### Quick path

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

### Requirement: Root is a thin dispatcher

The root `./setup` script MUST be a thin dispatcher: it parses
flags, validates them, defines and exports the path variables
required by child scripts, registers an `EXIT` trap to clean
those variables, and invokes exactly one of
`scripts/setup-omarchy`, `scripts/setup-fonts`, or
`scripts/setup-deps`. Unknown flags MUST cause a non-zero exit
after printing usage to stderr. It MUST NOT execute a multi-step
`deps → fonts → env` pipeline; it MUST NOT define
`run_deps` / `run_fonts` / `run_env` helpers; it MUST NOT
maintain a `TOTAL_STEPS` counter.

#### Scenario: root invokes exactly one env script

- GIVEN `./setup --omarchy` (with or without `--fonts` / `--deps` / `--dry-run`)
- WHEN the dispatcher runs
- THEN it invokes `scripts/setup-omarchy` exactly once and exits 0

#### Scenario: root does not drive a pipeline

- GIVEN the source of `./setup`
- WHEN inspected
- THEN it contains no `run_deps`, `run_fonts`, `run_env`, or `TOTAL_STEPS` symbols, and no `deps → fonts → env` sequence

### Requirement: Flag contract and precedence

The dispatcher MUST accept `--omarchy`, `--fonts`, `--deps`,
`--dry-run`, `--help`, `-h`. Unknown flags MUST cause a
non-zero exit after printing usage to stderr. No arguments
MUST cause a non-zero exit after printing usage.

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
`source`) so the exported `DOTFILES_*` variables cross the
process boundary cleanly and the trap scope stays local to the
dispatcher.

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
- THEN it performs no install, copy, download, or package-manager invocation; it only checks directory existence and contents

### Requirement: setup-deps auto-detection

`scripts/setup-deps` MUST auto-detect the host environment by
probing package managers in a fixed order, when no explicit
override flag is passed. The probe collapses to two Omarchy
outcomes; no other env is supported.

| Probe | Resolved env | Notes |
| --- | --- | --- |
| `command -v yay` | `omarchy` | Yay is the documented Omarchy AUR helper |
| `command -v pacman` | `omarchy` | Warn that `yay` is missing |
| none | (fail) | Clear error: "Could not detect a supported package manager (yay, pacman). Install one and re-run." |

Detection is purely a probe — no install side effects, no
recursive self-install. When detection fails, the script MUST
exit non-zero with the message above.

#### Scenario: yay present resolves to omarchy

- GIVEN `yay` is on `PATH` and no override flag is passed
- WHEN `scripts/setup-deps` runs
- THEN it uses the Omarchy package list and the `pacman -Q` / `yay -S` commands

#### Scenario: pacman without yay resolves to omarchy with warning

- GIVEN `pacman` is on `PATH` and `yay` is not
- WHEN `scripts/setup-deps` runs
- THEN it uses the Omarchy package list and emits a warning that `yay` is missing

#### Scenario: no package manager fails clearly

- GIVEN no `yay` or `pacman` is on `PATH` and no override flag is passed
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

#### Scenario: an unknown env override fails

- GIVEN `scripts/setup-deps` is invoked with any other env-named override flag
- WHEN the script processes flags
- THEN it prints "Unknown argument" with usage to stderr and exits 2

### Requirement: Input-devices packages

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

### Requirement: Documentation and test coverage

`docs/setup.md` MUST document the `./setup` entrypoint, the
accepted flags, and the env-selection model. The detailed
implementation contract lives in OpenSpec. `docs/setup.md` MUST
also describe `setup-deps` as a single-pass batch installer.
`tests/setup-deps.bash` MUST cover the thin-dispatcher contract:
root invokes `setup-omarchy` once; root absorbs `--omarchy
--fonts` / `--omarchy --deps`; `--fonts` runs only `setup-fonts`
and `--deps` runs only `setup-deps`; env pre-flight blocks on
missing fonts and honors the `DOTFILES_FONTS_DIR` override;
`DOTFILES_*` cleanup fires on success and on child failure.
Minimum `TEST_PLAN=5` (T1, T2, T4, T5, T6).

## REMOVED Requirements

### Requirement: --fedora not-implemented behavior

**Reason**: The env-only short-circuit contract is no longer
reachable. The env-named CLI flag is removed; the existing
unknown-flag branch in `./setup` already covers rejection
(exit 2 with usage on stderr). The short-circuit scenarios are
removed along with the test that exercised them.

**Migration**: None. The unknown-flag contract is exercised by
the surviving T2 sub-cases (known/unknown flag patterns) and
the `unknown flag fails` scenario in the Flag Contract
requirement. No new test is required.

### Requirement: Fedora single-pass install coalesces sudo

**Reason**: The single-env cut removes the only host that used
the `sudo dnf install -y` coalesced-install contract. The
Omarchy-side single-pass behavior lives in
`Requirement: setup-deps single-pass batch install`, which is
unchanged.

**Migration**: None. The Omarchy single-pass contract is
preserved in `Requirement: setup-deps single-pass batch install`
(see also the Omarchy single-pass scenario in
`Requirement: Documentation and test coverage`).

### Requirement: TAP test coverage for the input-devices packages

**Reason**: The test group that exercised this contract (T8,
including the substring-assertion coverage of the Omarchy
install line) is removed in this change. The contract is
re-introducible as a new test in a future change if needed.

**Migration**: None. The Omarchy package-list contract lives in
`Requirement: Input-devices packages`; `OMARCHY_PACKAGES` still
lists `keyd`, `piper`, and `libratbag` in `scripts/setup-deps`.
The substring-assertion contract is a test-only detail and is
not encoded in the spec.
