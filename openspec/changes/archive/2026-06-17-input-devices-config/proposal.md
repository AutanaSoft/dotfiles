# Proposal: input-devices-config (keyd + piper)

> **Scope note (locked, user-confirmed 2026-06-17): this change
> applies to Omarchy ONLY. No package, config file, or service
> change is made on the Fedora side. Fedora users get nothing
> from this change.**

## Why

The user has a damaged keyboard (the `Up` arrow key is broken)
and needs a stable remap. The `VolUp` and `VolDown` keys are
unwanted and need to be silenced. The Logitech G502 Hero needs
a reproducible two-profile setup (Default + Game) for the extra
buttons to be useful outside of games. Both must live in the
dotfiles repo so a fresh Omarchy host re-creates them via
`./setup --omarchy`.

## What Changes

| Kind | Path | Notes |
| --- | --- | --- |
| Modified | `scripts/setup-deps` | `OMARCHY_PACKAGES+=` `keyd`, `piper`, `libratbag` (the `libratbag` package provides `ratbagd` on Arch; `ratbagd` would conflict). `FEDORA_PACKAGES` is unchanged — see scope note. |
| Modified | `tests/setup-deps.bash` | T8 sub-case C adds the new package names to the hardcoded substring array for Omarchy. Sub-case D (Fedora) is unchanged. |
| New | `omarchy/home/.config/keyd/default.conf` | keyd v2.6 config. Uses `noop` (per keyd v2.6 man page Example 8) to silence `volumeup` / `volumedown`; remaps `up` → `pagedown`. Section `[ids] *` (universal scope) for now. |
| Modified | `scripts/setup-omarchy` | (a) Run `sudo install -m 644 "$REPO_ROOT/omarchy/home/.config/keyd/default.conf" /etc/keyd/default.conf`. (b) Run `sudo systemctl enable --now keyd ratbagd`. Both honor `--dry-run` (preview only). Precedent: first sudo service-enable in env flow (design phase documents it). No `~/.config/keyd/` symlink — keyd reads `/etc/keyd/default.conf` only, the user-level path is unnecessary. |
| New | `docs/inputs/keyboard-remap.md` | Runbook: config layout, how to edit and reload (`sudo keyd reload`), how to migrate to `usb:VID:PID` scoping if a second keyboard is added. |
| New | `docs/inputs/mouse-g502.md` | Piper profile recipe: 2 profiles, exact button bindings per profile, why profiles are NOT in the repo (ratbagd writes them to firmware via DBus — no on-disk persistence). |
| Modified | `docs/shared-layer.md` | Add a new exception section: `omarchy/home/.config/keyd/default.conf` is the repo source; `scripts/setup-omarchy` `install`s it to `/etc/keyd/default.conf` (root-owned, daemon config). This is the second tracked-on-repo-but-not-live-symlink exception, analogous to the `shared/home/.ssh/config` template. |
| Modified (delta) | `openspec/specs/setup-orchestration/spec.md` | Merged target at archive. New requirement covers the input-devices packages and the Omarchy service-enable + keyd install step. |

No new capability. `setup-orchestration` is the only modified one.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `setup-orchestration`: `setup-deps` package list grows (Omarchy: `keyd`, `piper`, `libratbag`). Env flow gains a new tracked config (`omarchy/home/.config/keyd/default.conf`) and a privileged `install` + `systemctl enable --now` step (keyd, ratbagd) that runs as part of `scripts/setup-omarchy`.

## Approach

1. Add packages to the `OMARCHY_PACKAGES` array in `scripts/setup-deps`; keep order / comments consistent with existing entries. `FEDORA_PACKAGES` untouched.
2. Add the new package names to the hardcoded substring array in `tests/setup-deps.bash` T8 sub-case C (Omarchy). Sub-case D (Fedora) untouched.
3. Author `omarchy/home/.config/keyd/default.conf` from the keyd v2.6 vocabulary. `[ids] *` is the documented default; docs explain the VID:PID migration path.
4. In `scripts/setup-omarchy`, add a new step that (a) `sudo install -m 644` the keyd config, (b) `sudo systemctl enable --now keyd ratbagd`. Both honor `--dry-run`. Coalesce with the first sudo call (one sudo burst, not two). No `sudo -v` standalone.
5. Add the shared-layer exception paragraph to `docs/shared-layer.md` (root-owned daemon config; copy pattern, not symlink; local `/etc/keyd/default.conf` wins).
6. Author the two runbooks with the cognitive-doc-design shape (quick path → details → checklist → next step).

## Affected Areas

| Area | Impact | Description |
| --- | --- | --- |
| `scripts/setup-deps` | Modified | 3 new Omarchy packages. `FEDORA_PACKAGES` unchanged. |
| `tests/setup-deps.bash` | Modified | T8 sub-case C substring array extended. Sub-case D unchanged. |
| `scripts/setup-omarchy` | Modified | New step: keyd `install` + `systemctl enable --now keyd ratbagd`. |
| `omarchy/home/.config/keyd/default.conf` | New | keyd v2.6 remap; `noop` for VolUp/VolDown (disable); `up`→`pagedown`. |
| `docs/inputs/keyboard-remap.md` | New | keyd runbook. |
| `docs/inputs/mouse-g502.md` | New | Piper two-profile recipe. |
| `docs/shared-layer.md` | Modified | New exception for `/etc/keyd/default.conf` install. |
| `openspec/specs/setup-orchestration/spec.md` | Delta | Adds input-devices requirement; archive merges it. |

## Risks

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| `systemctl enable` prompts for sudo mid-flow, breaks dry-run output and the test suite. | Med | Coalesce with the new `sudo install` call (one sudo burst, not two). In dry-run, emit both preview lines. T5/T8 are dep-list tests — they don't observe systemctl. |
| Test hardcoded package array drifts from `setup-deps` array. | Med | The array in T8 C is intentionally substring-asserted. Treat it as the test contract; any future package change touches both. |
| keyd v2.6 action vocabulary drift (e.g. `clear` confused with `noop`). | Low | Use `noop` (documented in keyd v2.6 man page Example 8 as the disable pattern; `clear()` is a different action for toggled/oneshot layers). Design phase verified by reading the upstream scdoc. |
| `omarchy/home/.config/keyd/default.conf` is a daemon config, not a user app config. | Med | Documented as a shared-layer exception in `docs/shared-layer.md`; copy pattern, not symlink; `install -m 644` (root-owned). No `~/.config/keyd/` symlink (keyd doesn't read from there). |
| Piper profiles drift over time (user re-binds in the GUI). | High (inherent) | Profile recipe is in `docs/inputs/mouse-g502.md`; profiles are NOT version-controlled (live on firmware). Manual recreation is the documented recovery path. |

## Rollback Plan

Revert `scripts/setup-deps` array; revert the delta in `openspec/specs/setup-orchestration/spec.md`; remove the new `scripts/setup-omarchy` step; remove `omarchy/home/.config/keyd/default.conf` and the two runbook docs; remove the shared-layer exception paragraph. If keyd / piper / libratbag were installed on a host: `yay -Rns keyd piper libratbag` and `sudo systemctl disable --now keyd ratbagd`. Stateless at the repo level; minimal host-level cleanup. No Fedora-side rollback (no Fedora changes were made).

## Decisions already made (locked, do NOT re-litigate)

1. **Service enable IN the env script** — `scripts/setup-omarchy` runs `sudo systemctl enable --now keyd ratbagd`. First sudo service-enable touchpoint in the env flow; design phase documents the precedent.
2. **Shared-layer exception for `/etc/keyd/default.conf`** — repo-tracked source is `omarchy/home/.config/keyd/default.conf`; env script `install`s it to `/etc/keyd/default.conf` (root copy, not symlink). `docs/shared-layer.md` gets a new exception paragraph analogous to the SSH template. **Omarchy-only** (no Fedora equivalent).
3. **Fedora is OUT of scope entirely** — no package change, no config file, no service enable on the Fedora side. User-confirmed 2026-06-17. (Previous decision was to exclude only `keyd` from Fedora; the broader "no Fedora at all" interpretation supersedes that.)
4. **`[ids] *` for now** — universal keyd scope. Doc explains the `usb:VID:PID` migration path if a second keyboard is added.

## Open items for the spec / design phase

- Exact systemd unit names: `keyd.service`, `ratbagd.service` are typical; confirm via `pacman -Ql keyd libratbag` on the target host before design.
- Whether `scripts/setup-omarchy` already has a `sudo` helper or needs one added (current code uses raw `sudo` in some paths — design phase reviews the pattern).
- Whether the `tests/setup-deps.bash` T8 update needs a separate T9 (probably not — T8 is the dep-list contract; the `install` + `systemctl` step is verified manually in verify phase).
- No `~/.config/keyd/` symlink: keyd reads `/etc/keyd/default.conf` only. Verify with `man keyd` and `keyd -V` in design.

## Success Criteria

- [ ] `bash tests/setup-deps.bash` passes all 8 tests; T8 sub-case C substring array covers `keyd`, `piper`, `libratbag`. Sub-case D unchanged.
- [ ] `scripts/setup-deps --dry-run --omarchy` (with the new packages missing) emits ONE `yay -S --needed` line containing every new package as a positional arg.
- [ ] `scripts/setup-deps --dry-run --fedora` emits the same `sudo dnf install -y` line as before — no new packages.
- [ ] `omarchy/home/.config/keyd/default.conf` is in the repo and syntactically valid per keyd v2.6 (design phase validates with `keyd -c <path> check` or equivalent).
- [ ] On a live Omarchy host, `./setup --omarchy` enables `keyd.service` and `ratbagd.service` and installs the config to `/etc/keyd/default.conf`; `sudo keyd reload` succeeds.
- [ ] `docs/inputs/keyboard-remap.md` and `docs/inputs/mouse-g502.md` follow the cognitive-doc-design shape; Piper doc explicitly states profiles live on firmware and are not version-controlled.
- [ ] `docs/shared-layer.md` documents the `/etc/keyd/default.conf` exception.
