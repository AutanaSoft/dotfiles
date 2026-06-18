# Design: input-devices-config (keyd + piper, Omarchy-only)

## Technical Approach

Three layers of work, in order of dependency. (1) Add the three new
packages to `OMARCHY_PACKAGES` and extend the T8 C substring array
so the bash TAP contract still passes; `FEDORA_PACKAGES` is
untouched. (2) Author the keyd v2.6 config under
`omarchy/home/.config/keyd/default.conf`, then teach
`scripts/setup-omarchy` to `install` it to `/etc/keyd/default.conf`
and `systemctl enable --now keyd ratbagd` — this is the first sudo
service-enable touchpoint in the env flow, and the design
documents the precedent. (3) Ship the two runbooks in
`docs/inputs/` and the new shared-layer exception in
`docs/shared-layer.md`. The Omarchy-only scope is locked; no
Fedora-side changes are made. The full delta spec at
`openspec/changes/input-devices-config/specs/setup-orchestration/spec.md`
is the contract; this design explains HOW the 5 requirements and 17
scenarios are realised in code and docs.

## Architecture Decisions

### Decision: keyd config file location

**Choice**: `omarchy/home/.config/keyd/default.conf` (env folder, not `shared/`).

**Why**: keyd runs as root and reads only from `/etc/keyd/`. The
tracked repo source lives under the env folder because the change
is Omarchy-only; `shared/` is for canonical configs that BOTH
envs use. The setup step copies the file to `/etc/keyd/default.conf`
with `install -m 644`. No `~/.config/keyd/` symlink is created —
keyd does not read that path.

**`omarchy update` interaction**: the file lives under the
user-owned `omarchy/home/` tree (same as the existing
`omarchy/home/.bashrc`). The Omarchy source tree it touches on
update is `~/.local/share/omarchy/default/`, `~/.local/share/omarchy/config/`,
and `~/.local/share/omarchy/bin/`. The user's `omarchy/home/`
folder is repo-local, not under the Omarchy source, so it survives
`omarchy update` automatically. The local file at
`/etc/keyd/default.conf` may be overwritten by the package on a
keyd upgrade; the env script's install step is idempotent and
runs every `./setup --omarchy`, so the next run restores it.

### Decision: first sudo service-enable in the env flow

**Choice**: a single coalesced `sudo systemctl enable --now keyd ratbagd`
in `scripts/setup-omarchy`, no `sudo -v` upfront.

**Why**: sudo's default timestamp cache (5 min) already coalesces
the two sudo calls in the new step (`install` + `systemctl`) into
one password prompt. An explicit `sudo -v` is unnecessary and would
add latency. **Precedent for future env flows**: any future env
executor that needs a privileged service-enable can use the same
pattern (rely on sudo timestamp caching; do not add `sudo -v`).
This is documented in the `scripts/setup-omarchy` block comment
above the new step.

### Decision: new step placement in `setup-omarchy`

**Choice**: Step 4/5, after symlinks, before validate. `TOTAL_STEPS`
bumps from 4 to 5.

**Why**: symlinks must be applied first so the user has a
consistent state; the keyd config install runs while the
symlink-map is fresh; the validate step (now Step 5) can then
verify `keyd -V` and `ratbagd` are alive in the new total.

**Order within the step**: `install` (config) → `systemctl enable --now`
(services). The daemon starts with the correct config already in
place. Reversing the order risks a daemon restart loop on a
fresh host that has no `/etc/keyd/default.conf` yet.

### Decision: keyd v2.6 silenced-key action

**Choice**: `noop` for `volumeup` and `volumedown`.

**Why**: keyd v2.6 man page Example 8 (`Disables the esc and end
keys`) uses `esc = noop; end = noop` as the canonical disable
pattern, and the ACTIONS section defines `noop` as "Do nothing".
`clear()` is a different action: it "clears any toggled or
oneshot layers" — not a way to silence a key. `noop` is the
right primitive here. Source of truth:
`https://raw.githubusercontent.com/rvaiya/keyd/refs/heads/master/docs/keyd.scdoc`
(sections ACTIONS and Example 8).

### Decision: Piper profiles are NOT in the repo

**Choice**: only the recipe runbook is tracked. Profiles are
authored in Piper and pushed to the G502 firmware by `ratbagd`
over DBus; there is no on-disk artefact to version.

**Why**: ratbagd uses DBus to call into libratbag's device
backends; the profile bytes are written to the device's onboard
EEPROM. The user's claim that "ratbagd stores profiles in
SQLite" was verified false against the libratbag source (no
SQLite in the project; profiles live on firmware). The
`docs/inputs/mouse-g502.md` runbook is the recovery path.

## Shared-vs-Env Boundary (per project rules)

| Path | Lives in | Why | Survives `omarchy update`? |
| --- | --- | --- | --- |
| `omarchy/home/.config/keyd/default.conf` | `omarchy/home/.config/` (env folder) | Omarchy-only; daemon config outside the symlink contract; the env script copies it to `/etc/keyd/default.conf` | Yes — same precedent as `omarchy/home/.bashrc`. The Omarchy source tree is `~/.local/share/omarchy/{default,config,bin}/`; the user's `omarchy/home/` is repo-local. |
| `docs/inputs/keyboard-remap.md` | `docs/inputs/` (repo-level) | Runbook for the Omarchy env; placed at repo level because it is doc, not config, and Omarchy's env README links out to it | Yes — `docs/` is not touched by `omarchy update`. |
| `docs/inputs/mouse-g502.md` | `docs/inputs/` (repo-level) | Runbook for the Omarchy env (Piper is not installed on Fedora) | Yes — same as above. |
| `docs/shared-layer.md` (modified) | `docs/` (repo-level) | Adds a new exception paragraph for the keyd install; documented exceptions live in shared-layer.md | Yes — same as above. |

**No `shared/` content is added or modified.** All input-devices
content is either env-local (`omarchy/home/.config/keyd/`) or
repo-level docs (`docs/`). The `shared/` layer remains unchanged.

## Module / Component Breakdown

### 3.1 `scripts/setup-deps` — Modify

**Path**: `scripts/setup-deps` (lines 61-76).

**Change type**: Modify.

**Approach**: append three entries to `OMARCHY_PACKAGES=(...)`:
`keyd`, `piper`, `libratbag` (with the existing `# command: ...`
comment style — `libratbag` provides `ratbagd`, so no comment is
strictly needed, but a `# provides: ratbagd` clarifies the
contract). Place at the END of the array to minimise the diff
and keep alphabetical-ish ordering intact. `FEDORA_PACKAGES=(...)`
is untouched (Omarchy-only, locked).

**Verification**: `bash tests/setup-deps.bash` passes all 8 tests
(T8 sub-case C now asserts the three new names as substrings of
the single `yay -S --needed` line). Dry-run preview contains the
three new packages.

### 3.2 `tests/setup-deps.bash` — Modify

**Path**: `tests/setup-deps.bash` (T8 sub-case C substring array, line 1194).

**Change type**: Modify.

**Approach**: extend the `omarchy_pkgs=(...)` array with
`keyd piper libratbag`. Add a comment above the array pointing to
the source of truth in `scripts/setup-deps` (e.g. `# Mirrors
OMARCHY_PACKAGES in scripts/setup-deps (line ~N). Edit both in
lockstep.`). Sub-case D (Fedora) is unchanged.

**Verification**: `bash tests/setup-deps.bash` reports
`8/8 passed`. Sub-case C asserts each of the three new names is
a substring of the single yay line.

### 3.3 `omarchy/home/.config/keyd/default.conf` — New

**Path**: `omarchy/home/.config/keyd/default.conf`.

**Change type**: New.

**Approach**: author a keyd v2.6 config. Header comment explaining
the file (purpose, reload command, VID:PID migration pointer).
Body:

```ini
[ids]
*

[main]
volumeup    = noop
volumedown  = noop
up          = pagedown
```

Each line documented inline. `[ids] *` is the universal scope for
a single keyboard. The remap of `up` → `pagedown` covers the
broken key. The `noop` action on VolUp/VolDown silences the
unwanted keys at the kernel level (per keyd v2.6 man page
Example 8).

**Verification**: `keyd -c omarchy/home/.config/keyd/default.conf
check` returns 0 (keyd v2.6 ships `check` to validate config
syntax; verify the exact flag spelling on the live host during
apply — the design recommends reading `man keyd` first).

### 3.4 `scripts/setup-omarchy` — Modify

**Path**: `scripts/setup-omarchy` (new step at Step 4/5; bump
`TOTAL_STEPS` at line 426 from 4 to 5).

**Change type**: Modify.

**Approach**: introduce a new function `install_input_devices` and
call it as Step 4/5 between `apply_symlinks` (now Step 3) and
`validate_system` (now Step 5). Pseudocode:

```bash
install_input_devices() {
    local src="$REPO_ROOT/omarchy/home/.config/keyd/default.conf"
    local target="/etc/keyd/default.conf"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        log "[dry-run] would run: install -m 644 $src $target"
        log "[dry-run] would run: systemctl enable --now keyd ratbagd"
        return 0
    fi
    require_command install
    require_command systemctl
    log "Installing keyd config: $src -> $target (mode 644)"
    sudo install -m 644 "$src" "$target"
    log "Enabling and starting keyd + ratbagd services"
    sudo systemctl enable --now keyd ratbagd
}
```

`TOTAL_STEPS=5` (was 4). The step counter at line 426 is bumped
accordingly. The block comment above the new function records
the precedent (first sudo service-enable in the env flow).

**Verification**: on a live host, `./setup --omarchy` invokes the
new step, `/etc/keyd/default.conf` exists with mode 0644, and
`systemctl is-enabled keyd ratbagd` returns `enabled`. In dry-run
mode, the two preview lines are emitted, no mutation occurs.

### 3.5 `docs/inputs/keyboard-remap.md` — New

**Path**: `docs/inputs/keyboard-remap.md`.

**Change type**: New.

**Approach**: follow the cognitive-doc-design shape (Quick Path →
Details → Checklist → Next step). Cover: (1) config file location
(repo + daemon), (2) how to edit and reload (`sudo keyd reload`),
(3) how to check active bindings (`sudo keyd monitor`,
`sudo keyd -V`), (4) the VID:PID migration path (`keyd monitor`
to discover device IDs, then `[ids] usb:VID:PID` instead of `*`).

**Verification**: the doc contains the three required topics
(config location, reload flow, VID:PID migration) and follows the
shape from the cognitive-doc-design skill.

### 3.6 `docs/inputs/mouse-g502.md` — New

**Path**: `docs/inputs/mouse-g502.md`.

**Change type**: New.

**Approach**: same shape. Cover: (1) the two Piper profiles
(Default + Game) with exact button bindings in a table, (2) why
profiles are NOT in the repo (firmware via DBus, no on-disk
artefact), (3) manual recreation steps in Piper for a fresh
host, (4) Piper install notes (`yay -S piper` — installed as
part of `OMARCHY_PACKAGES`; the GUI app `piper` is launched
per-user).

**Verification**: the doc contains the two profiles with
bindings, the explicit "profiles are NOT version-controlled"
caveat, and the recreation steps.

### 3.7 `docs/shared-layer.md` — Modify

**Path**: `docs/shared-layer.md`.

**Change type**: Modify.

**Approach**: add a new exception paragraph under the
`## SSH template exception` section, titled
`### Exception: /etc/keyd/default.conf install pattern`. Mirror
the SSH template's wording and scope. Justify: keyd runs as
root and reads only from `/etc/keyd/`; the user-level path is
unused. The repo source is `omarchy/home/.config/keyd/default.conf`
(Omarchy-only — Fedora is out of scope). `scripts/setup-omarchy`
copies it to `/etc/keyd/default.conf` with `install -m 644`; this
is the second tracked-on-repo-but-not-live-symlink exception
(the first being the SSH config template).

**Verification**: the new paragraph is present, scoped to Omarchy
only, and follows the existing SSH template's tone.

### 3.8 `openspec/specs/setup-orchestration/spec.md` — Delta (already authored)

**Path**: `openspec/changes/input-devices-config/specs/setup-orchestration/spec.md`
(merge target at archive:
`openspec/specs/setup-orchestration/spec.md`).

**Change type**: Delta (already written). Archive phase will merge
the 5 added requirements and 17 added scenarios into the main
spec.

**Verification**: archive phase is gated on this; the design
references the delta but does not re-derive it.

## Sequence: fresh Omarchy host setup

1. User runs `./setup --omarchy` from the repo root.
2. `setup` dispatches to `scripts/setup-omarchy`.
3. Step 1/5 — `scripts/setup-deps` installs `keyd`, `piper`,
   `libratbag` (and the existing six packages) in a single
   `yay -S --needed` batch.
4. Step 2/5 — `scripts/setup-fonts` installs Nerd Fonts.
5. Pre-flight checks the fonts dir.
6. Step 3/5 — `apply_symlinks` links the existing tracked files
   into `~/.config/...` and `~/.bashrc`. SSH config is seeded if
   missing.
7. Step 4/5 (NEW) — `install_input_devices` copies
   `omarchy/home/.config/keyd/default.conf` to
   `/etc/keyd/default.conf` (mode 644) and runs
   `sudo systemctl enable --now keyd ratbagd`. Sudo prompts
   once for the timestamp; both commands run without re-prompting.
8. Step 5/5 — `validate_system` applies the theme, reloads
   Hyprland, checks `zellij --version`.
9. Setup complete. The user is told to manually recreate the G502
   Piper profiles by following `docs/inputs/mouse-g502.md`
   (firmware-only — cannot be automated from the repo).

## Failure Modes and Recovery

| Failure | Handling | Rationale |
| --- | --- | --- |
| `install -m 644` of keyd config fails (e.g. `/etc/keyd/` is read-only on a locked-down host) | `set -e` aborts the whole env script with a clear error. `systemctl enable` is NOT run. | A running keyd daemon without its config is useless; partial state is worse than a clear failure. The user fixes `/etc/keyd/` and re-runs `./setup --omarchy`. |
| `systemctl enable --now` fails for one of the two services | `set -e` aborts after the failing `systemctl` call. The config is already in place, but the daemon is not enabled. | The env script does not roll back the config install. Recovery: re-run `./setup --omarchy`; the config install is idempotent, the `systemctl` call is retried. |
| ratbagd install fails (e.g. pacman conflict on a partial host) | `set -e` from `setup-deps` aborts the env script. keyd is not installed either. | The dep install is atomic in this repo: setup-deps runs as one batch and any install failure aborts the whole env script. |
| Host has no G502 mouse (Piper installed but never opened) | Install completes normally. Piper GUI is never auto-launched. | Piper is a GUI app the user opens on demand; no runtime check is possible. The runbook covers the recreation steps. |
| User runs `./setup --omarchy` a second time | Both steps are idempotent. The keyd config is re-installed (bit-identical), `systemctl enable --now` is a no-op (service is already enabled). | Expected re-runs are safe. |

## Out of Scope

- **Fedora**: nothing. No package, no config, no service. The
  `FEDORA_PACKAGES` array is byte-for-byte unchanged.
- **Auto profile switching per app**: keyd v2.6 supports layer
  matching by active window via the application-mapper tool, but
  the user's G502 profiles are static (Default + Game, toggled
  manually in Piper). Per-app switching is a separate future
  change.
- **`scripts/setup-fedora`**: does not exist; creating it is not
  this change's job. The Fedora path remains a
  short-circuit-and-skip in the root dispatcher.
- **Piper profile version control**: impossible — profiles live on
  the device firmware. The `docs/inputs/mouse-g502.md` runbook
  is the recovery path.
- **Commit / push / PR**: per repo rules, none of these are
  performed by the change. The apply phase implements; the user
  decides on commit, push, and PR.

## Verification Strategy

| Layer | What | How |
| --- | --- | --- |
| Bash TAP | `bash tests/setup-deps.bash` | All 8 tests pass. T8 sub-case C substring array covers `keyd`, `piper`, `libratbag`. Sub-case D unchanged. |
| Dry-run (Omarchy) | `scripts/setup-deps --dry-run --omarchy` | Emits exactly ONE `yay -S --needed` line containing all 9 packages (6 existing + 3 new). |
| Dry-run (Fedora) | `scripts/setup-deps --dry-run --fedora` | Unchanged. ONE `sudo dnf install -y` line; no `keyd`, `piper`, `libratbag`, or `ratbagd` substring. |
| Config validation | `keyd -c omarchy/home/.config/keyd/default.conf check` (or equivalent) | Returns 0. Verify the exact flag with `man keyd` on the live host during apply. |
| Live host | `./setup --omarchy` on a real Omarchy install | `/etc/keyd/default.conf` exists with mode 0644; `systemctl is-enabled keyd ratbagd` returns `enabled`; `sudo keyd reload` succeeds; the runbooks match the actual config state. |
| Manual | Piper profile recreation on a fresh host | User follows `docs/inputs/mouse-g502.md`; both profiles recreated in Piper. |

## Open Questions for sdd-tasks

- **keyd `check` subcommand spelling**: the design assumes
  `keyd -c <path> check` or `keyd check <path>`. The exact
  spelling (flag vs positional) needs confirmation on the live
  host with `man keyd` or `keyd --help`. Apply phase verifies.
- **TOTAL_STEPS wording**: the new Step 4/5 line should keep the
  `step "<verb> <object>"` style. The apply phase picks the exact
  wording (suggested: `"Install keyd config and enable input-device services"`).
- **runbook length**: both runbooks should land under the
  ~120-line root doc budget from `docs/conventions.md`. If Piper
  profile recreation steps run long, the runbook becomes a
  parent doc and the per-profile recipes become subdocs.
