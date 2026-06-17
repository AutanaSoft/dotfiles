# Delta for setup-orchestration

## Purpose

Delta spec for `setup-deps-batch-install`. Refactors
`scripts/setup-deps` from a per-package install loop into a
single-pass batch install: collect every missing package, invoke
the env's package manager exactly once with all of them as
positional arguments. Adds an all-present early-exit, a final
`installed` / `present` / `missing` summary, and a single coalesced
install call per env. Symmetric for both envs.

## ADDED Requirements

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

### Requirement: Fedora single-pass install coalesces sudo

When the resolved env is `fedora`, `scripts/setup-deps` MUST
invoke `sudo dnf install -y <pkgs...>` once with all missing
packages as positional args. The script MUST NOT perform any
upfront `sudo -v` validation; the single `dnf` invocation MUST
be the only point at which a sudo password prompt can appear.

#### Scenario: fedora invokes sudo dnf once with all missing packages

- GIVEN the env resolves to fedora and N >= 2 packages are missing
- WHEN `scripts/setup-deps` runs (real or dry-run mode)
- THEN the install log shows exactly one `sudo dnf install -y` line listing every missing package as a positional argument
- AND no `sudo` invocation appears before that line

## MODIFIED Requirements

### Requirement: Documentation and test coverage

`docs/setup.md` MUST document the `./setup` entrypoint,
accepted flags, and the not-implemented `--fedora` case; the
implementation contract lives in OpenSpec. `docs/setup.md` MUST
also describe `setup-deps` as a single-pass batch installer per env.
`tests/setup-deps.bash` MUST additionally cover the new
single-pass install flow: one `yay` line and one `sudo dnf` line
per batch, all-present skips the PM, failure aborts. Minimum
`TEST_PLAN=8`.

(Previously: per-package install implicit; single-pass test
contract is new.)
