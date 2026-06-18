# Proposal: omarchy-only-scope — collapse the dotfiles repo to one environment

> **Scope lock** (user-confirmed 2026-06-17): this repo targets
> Omarchy-family hosts ONLY — stock Omarchy, CachyOS+Omarchy, and
> Arch+Omarchy. The second environment layer is being removed.
> The Omarchy installer handles all distribution-specific
> configuration; this repo's only AUR-helper concern is `yay`
> (the Omarchy default).

## Why

The repo currently carries a second environment layer that has
never shipped value. The root dispatcher parses a flag for it,
`scripts/setup-deps` carries a parallel install path, the TAP
harness asserts the short-circuit, and the spec documents the
not-implemented behavior as a requirement. None of it materializes:
the layer is a TODO that has been "out of scope" in practice for
months, and the Omarchy installer owns distribution-specific
config by design. The scope lock clarifies the contract: this
repo is for personal dots on Omarchy-family hosts only.

## What Changes

| Kind | Path | Notes |
| --- | --- | --- |
| Removed | `fedora/` | `git rm -r`; no local trace. Historical surface stays recoverable from git history if ever needed. |
| Modified | `setup` | Eliminate the second env from the dispatcher. The removed flag now hits the existing unknown-flag branch and exits 2. Mutual-exclusion check is dropped (no second flag to exclude). |
| Modified | `scripts/setup-deps` | `git rm` of `FEDORA_PACKAGES` and every env-conditional install branch in `detect_env`, `pkg_installed`, `install_batch`, and `main`. Auto-detection collapses to `yay` → Omarchy; `pacman` → Omarchy with a `yay` warning; else fail. `--omarchy` stays as an explicit override; the removed flag becomes an unknown arg. |
| Modified | `tests/setup-deps.bash` | Eliminate T3 (the env-only short-circuit test). Drop T7 sub-case B and T8 sub-case D (their code paths are removed; downstream of the env-specific requirements collapse). `TEST_PLAN` drops to 5. |
| Modified (delta) | `openspec/specs/setup-orchestration/spec.md` | Eliminate all env-specific requirements. See "Capabilities" below. |
| Modified | `openspec/config.yaml` | Rewrite the `context:` block to a one-env statement. Update the `rules:` examples that cite the env pair. |
| Modified | `README.md`, `AGENTS.md`, `docs/setup.md`, `docs/conventions.md`, `docs/shared-layer.md`, `docs/git.md`, `docs/wezterm.md`, `docs/ssh.md`, `docs/starship.md` | Scrub env-2 references. Tools that appear in both envs (Starship, nvim, Zellij, Git, SSH) keep their entries; only the second-env column / row / link is dropped. |
| Removed | `docs/ideas/scripts/setup.md` | Eliminate the obsolete env-specific design note alongside the scope cut. |
| Untouched | `openspec/changes/archive/*` | Preserved per SDD archive policy. The scope cut is recorded in THIS change's verify-report, not retroactively. |

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `setup-orchestration`: the env-conditional surface collapses to
  Omarchy. The flag contract, the auto-detect probe, the package
  lists, the test plan, and the spec's env-specific requirements
  all become single-env.

## Approach

1. `git rm -r fedora/`. No local trace; historical surface is recoverable from `git log` if ever needed.
2. `setup`: drop the env-flag branch in the parser; drop the mutual-exclusion check; drop the "not implemented" short-circuit; drop the env-flag row from the usage text; drop the env-flag from the dispatch table. The existing unknown-flag branch already covers the rejection.
3. `scripts/setup-deps`: drop the `FEDORA_PACKAGES` array, drop the removed-flag parser branch, drop the `dnf`/`rpm` rows in `detect_env`, drop the env-conditional branches in `pkg_installed` / `install_batch` / `main`. `OMARCHY_PACKAGES`, the `yay` install path, and the `--omarchy` override stay.
4. `tests/setup-deps.bash`: drop T3 entirely; drop T7 sub-case B and T8 sub-case D (downstream of the env-specific requirements collapse). Leave the rest of the TAP harness unchanged. `TEST_PLAN` drops to 5.
5. `openspec/specs/setup-orchestration/spec.md` (delta): drop the env-only requirement, drop the env-conditional single-pass install requirement, drop the `dnf`/`rpm` rows in the auto-detect probe, drop cross-references in mutual exclusion / setup-deps override / input-devices cross-tests / doc coverage. No historical note added.
6. `openspec/config.yaml`: rewrite the `context:` block to a one-env statement (Omarchy + CachyOS+Omarchy + Arch+Omarchy).
7. `README.md`, `AGENTS.md`, `docs/*.md`: scrub env-2 references. Tools that appear in both envs (Starship, nvim, Zellij, Git, SSH) keep their entries; only the second-env column / row / link is dropped.
8. `docs/ideas/scripts/setup.md`: `git rm` alongside the scope cut.
9. `openspec/changes/archive/*`: untouched. Verify-report of this change records the scope cut; no retroactive edits to historical artifacts.

CachyOS+Omarchy and Arch+Omarchy are treated identically from
this repo's perspective — the Omarchy installer owns the
distribution-specific config. This repo's only AUR-helper concern
is `yay` (the Omarchy default).

## Affected Areas

| Area | Impact | Description |
| --- | --- | --- |
| `setup` | Modified | Single-env dispatcher. |
| `scripts/setup-deps` | Modified | Single-env install + detection. |
| `tests/setup-deps.bash` | Modified | T3, T7-B, T8-D removed; `TEST_PLAN` to 5. |
| `openspec/specs/setup-orchestration/spec.md` | Modified (delta) | Env-specific requirements removed. |
| `openspec/config.yaml` | Modified | One-env context block. |
| `README.md`, `AGENTS.md`, `docs/*` | Modified | Env-2 references scrubbed. |
| `fedora/` | Removed | Hard removal. |
| `docs/ideas/scripts/setup.md` | Removed | Hard removal. |
| `openspec/changes/archive/*` | Untouched | Archive policy. |

## Risks

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| A user with a partial setup from before the lock has stale references in muscle memory or scripts. | Med | The removed flag is rejected via the existing unknown-flag path (exit 2 + usage). The error is loud enough to be caught. |
| The auto-detect probe loses its `dnf`/`rpm` rows and an unexpected host now fails where it used to silently route. | Med | Intended behavior. The failure message lists the supported PMs. |
| Archived changes still mention the second-env surface; future readers may misread the current contract. | Low | The scope cut is recorded in the verify-report of this change with a one-paragraph note explaining what the archived references are. |
| The delta spec touches many small sections of one big spec — hard to review. | Med | Group the spec edits under a single "Omarchy-only scope" delta header; one PR, one review pass. |
| `TEST_PLAN` decrement forgotten. | Low | Drop the constant in the same commit as the test removals. |

## Rollback Plan

Revert the change as a single commit (or a small sequence). The
removed env folder is recoverable from `git log` / `git revert`. The
spec delta is reverted the same way. No data-loss risk beyond the
working tree.

## Dependencies

None. The Omarchy installer (`omarchy` command) is the only
external runtime dependency, and it is unchanged.

## Success Criteria

- [ ] `git rm -r fedora/` leaves the working tree clean.
- [ ] `./setup --omarchy`, `./setup --fonts`, `./setup --deps` still work; `--help` is unchanged in shape.
- [ ] `./setup --<removed-flag>` and `scripts/setup-deps --<removed-flag>` both exit 2 with the existing unknown-flag message.
- [ ] `bash tests/setup-deps.bash` passes with the decremented `TEST_PLAN`.
- [ ] No remaining references to the second env exist in tracked source, scripts, tests, docs, or specs (the `openspec/changes/archive/` exception is the only place the env name still appears, per the recorded scope cut).
- [ ] `docs/ideas/scripts/setup.md` is gone.
- [ ] Archived change folders under `openspec/changes/archive/` are byte-identical to before the change.
