# Delta for setup-orchestration

## Purpose

Delta spec for `input-devices-config`. Adds the `keyd` keyboard
remap, the `piper` / `ratbagd` mouse-tooling pair, and their
Omarchy-only install/serve flow to the setup-orchestration
capability. Scope is locked to Omarchy: no package, config file,
or service change is made on the Fedora side. The Fedora
package list, the `--fedora` dispatch path, and the Fedora
runbook remain exactly as they are.

The change introduces a tracked keyd config file at
`omarchy/home/.config/keyd/default.conf`, a privileged `install`
step in `scripts/setup-omarchy` that copies it to
`/etc/keyd/default.conf` (root-owned, daemon config — not a
symlink), a `systemctl enable --now` step for the keyd and
ratbagd services, and two runbook docs in `docs/inputs/`. The
`docs/shared-layer.md` file gets a new exception paragraph
analogous to the existing `shared/home/.ssh/config` template
exception.

## ADDED Requirements

### Requirement: Input-devices packages (Omarchy only)

The `OMARCHY_PACKAGES` array in `scripts/setup-deps` MUST
include `keyd`, `piper`, and `libratbag`. The `libratbag` Arch
package is the canonical install name (it provides `ratbagd`;
installing the standalone `ratbagd` package would conflict).
The `FEDORA_PACKAGES` array MUST NOT include any of
`keyd`, `piper`, or `libratbag` (or any Fedora-only equivalent
such as `libratbag-ratbagd`). This asymmetry is locked by
user-confirmed scope: this change is Omarchy-only; Fedora users
get nothing from it.

#### Scenario: Omarchy package list contains the three input-device packages

- GIVEN `scripts/setup-deps` is on disk
- WHEN the `OMARCHY_PACKAGES` array is read
- THEN it MUST contain `keyd`, `piper`, and `libratbag` as entries
- AND the standalone `ratbagd` package MUST NOT be present (it conflicts with `libratbag` on Arch)

#### Scenario: Fedora package list is unchanged

- GIVEN `scripts/setup-deps` is on disk
- WHEN the `FEDORA_PACKAGES` array is read
- THEN it MUST NOT contain `keyd`, `piper`, `libratbag`, or `ratbagd`

#### Scenario: Omarchy dry-run emits a single yay line with all three packages

- GIVEN `scripts/setup-deps --omarchy --dry-run` is invoked and at least one of the new packages is missing
- WHEN the install phase runs
- THEN the output contains exactly one `yay -S --needed` line
- AND that line lists `keyd`, `piper`, and `libratbag` as positional arguments

#### Scenario: Fedora dry-run is unchanged

- GIVEN `scripts/setup-deps --fedora --dry-run` is invoked
- WHEN the install phase runs
- THEN the output contains exactly one `sudo dnf install -y` line
- AND that line does NOT list `keyd`, `piper`, `libratbag`, or `ratbagd` in its args

### Requirement: TAP test coverage for the input-devices packages

`tests/setup-deps.bash` test T8 sub-case C substring array
MUST include `keyd`, `piper`, and `libratbag` as substring
assertions against the single `yay -S --needed` line. Sub-case
D's Fedora substring array MUST remain unchanged — no new
packages on the Fedora path. The minimum `TEST_PLAN=8` is
preserved (no new top-level test required; the contract is
extended inside an existing sub-case).

#### Scenario: T8 sub-case C substring array contains all three new packages

- GIVEN `tests/setup-deps.bash` T8 sub-case C substring array
- WHEN the test executes
- THEN `keyd`, `piper`, and `libratbag` MUST each appear as a substring assertion against the yay line
- AND any of them missing from the substring array causes the sub-case to fail

#### Scenario: T8 sub-case D Fedora substring array is unchanged

- GIVEN `tests/setup-deps.bash` T8 sub-case D substring array
- WHEN the test executes
- THEN it MUST equal the pre-change array (no new packages added)

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
