# Design — ideas-implementation (revised)

## Decision

Redraw the orchestration boundary so that root `setup` is a **thin
dispatcher** (parses flags, defines/exports real paths, traps, and
invokes one env script) and each env script (e.g. `scripts/setup-omarchy`)
**owns its own full flow** — verify deps, install fonts, configure the
env. `scripts/setup-deps` **auto-detects** the host system by probing
the available package managers instead of receiving an explicit env
flag. The previously-verified dispatcher model is replaced; this is
an architectural correction, not an additive patch.

## Why this changes

`ideas.md` is unambiguous on two points that the previous design
violated:

1. "El setup script es el orquestador… también debe de encargarse
   inicial las variables necesarias para que los otros script
   funcionen correctamente." — root only orchestrates and initializes
   variables. It does **not** run a multi-step pipeline of
   `setup-deps → setup-fonts → setup-omarchy`.
2. "Los script de configuraciones deben… verificar las dependencias,
   instalar las fuentes, configurar el entorno." — the env script
   owns all three responsibilities.

The previous design treated root as a pipeline driver. This revision
moves the pipeline into the env scripts and reduces root to a
flag-to-script dispatcher plus path exporter. The change is
substantial because the existing implementation encodes the
pipeline-driving model in `setup` lines 322–412.

## Quick path — what the user runs

| Invocation | Root does | Env script does |
| --- | --- | --- |
| `./setup --omarchy` | `export` paths, `trap`, invoke `scripts/setup-omarchy`, exit 0 | verify deps, install fonts, apply env config |
| `./setup --fedora` | print "not implemented", exit 0 | — (never invoked) |
| `./setup --deps` | invoke `scripts/setup-deps` directly, exit 0 | — (auto-detects host env) |
| `./setup --fonts` | invoke `scripts/setup-fonts` directly, exit 0 | — (idempotent) |
| `./setup --omarchy --fonts` | same as `--omarchy` (env script handles fonts) | installs fonts, applies env |
| `./setup --omarchy --deps` | same as `--omarchy` (`--deps` absorbed) | installs deps, fonts, env |
| `./setup --fedora --deps` | same as `--fedora` (skip wins) | — |

## Component map

| File | Role | Net lines (delta vs. current) |
| --- | --- | --- |
| `setup` | Thin dispatcher. Parses flags; defines/exports real paths; traps cleanup; invokes ONE env script (or the top-level convenience path). | roughly −140 / +20 |
| `scripts/setup-omarchy` | Owns the full Omarchy env flow. Calls `setup-deps`, calls `setup-fonts`, then verifies and applies env config. | +60 / −5 |
| `scripts/setup-deps` | Auto-detects host env (yay/pacman → omarchy, dnf/rpm → fedora). Env flag becomes an optional override. | +50 / −20 |
| `scripts/setup-fonts` | Reads optional `DOTFILES_FONTS_DIR` override; otherwise keeps current default. | +5 / −2 |
| `tests/setup-deps.bash` | Rewrites several assertions; adds env-detection tests. | +60 / −50 |
| `docs/setup.md` | Rewrites Quick Path, dispatch matrix, Scripts table; adds env-detection section. | +30 / −25 |

No new top-level files. No new directories. The same five-file
surface as the current implementation.

## Root `setup` — thin orchestrator

### Responsibilities (only these)

1. **Resolve repo root** from `${BASH_SOURCE[0]}` (CWD-independent).
2. **Parse flags**: `--omarchy`, `--fedora`, `--fonts`, `--deps`,
   `--dry-run`, `--help` / `-h`. Mutual exclusion of env flags.
3. **Compute** the per-run backup dir path: `$REPO_ROOT/backup/<utc-ts>/`.
4. **Export** the variable contract below.
5. **`trap 'unset …' EXIT`** to clean up exported vars on every exit path.
6. **Dispatch** to exactly one of:
   - `scripts/setup-omarchy` (when `--omarchy` is set, with or without
     `--fonts` / `--deps`),
   - `scripts/setup-fonts` (when only `--fonts` is set, no env flag),
   - `scripts/setup-deps` (when only `--deps` is set, no env flag),
   - "not implemented" log + `exit 0` (when `--fedora` is set, any combo).
7. **`exit 0`** on success; non-zero on validation errors and on
   env-script failure (let the env script's own `exit` propagate).

### Non-responsibilities (explicitly NOT in root)

- No multi-step counter for a `deps → fonts → env` pipeline.
- No `run_deps`, `run_fonts`, `run_env` helpers.
- No Fedora skip-without-deps branch (the entire `--fedora` path
  short-circuits; deps and fonts are never invoked for fedora).
- No package-manager detection, no command pre-flight.

### Precedence

| Input | Root behavior |
| --- | --- |
| `--help` / `-h` | print usage, exit 0 |
| `--fedora` (any combo) | print "Fedora env executor is not implemented", exit 0. **Never** invokes `setup-deps` or `setup-fonts` or any env script. |
| `--omarchy` (alone or with `--fonts` and/or `--deps`) | invoke `scripts/setup-omarchy` once. `setup-omarchy` is responsible for deps and fonts. |
| `--fonts` only | invoke `scripts/setup-fonts` directly. |
| `--deps` only | invoke `scripts/setup-deps` directly. |
| `--omarchy --fedora` | non-zero exit + usage (mutually exclusive). |
| Unknown flag | non-zero exit + usage to stderr. |
| Nothing | non-zero exit + usage. |

`--omarchy --fonts` and `--omarchy --deps` are convenience inputs the
user may type. Root absorbs them — the env script does the real work.
A redundant `--fonts` is cheap because `setup-fonts` is idempotent
(re-run overwrites). A redundant `--deps` is a no-op because the env
script calls `setup-deps` anyway.

## Exported variable contract

Root `setup` exports these names. They are the **only** mechanism
child scripts use to learn the real paths; sub-scripts MUST NOT
re-resolve repo root when `DOTFILES_ROOT` is set, and MUST NOT
re-derive the fonts dir when `DOTFILES_FONTS_DIR` is set.

| Variable | Type | Set by | Default if not in root | Consumed by |
| --- | --- | --- | --- | --- |
| `DOTFILES_ROOT` | absolute path | root `setup` | required (no fallback at root) | env scripts, sub-scripts |
| `DOTFILES_ENV` | `omarchy` | root `setup` | unset (no env selected) | env scripts (logging); `setup-deps` (optional override) |
| `DOTFILES_DRY_RUN` | `1` or unset | root `setup` | unset (live mode) | env scripts, sub-scripts |
| `DOTFILES_BACKUP_DIR` | absolute path | root `setup` | required when env selected | env scripts (backup-before-replace) |
| `DOTFILES_FONTS_DIR` | absolute path (NEW) | root `setup` | `$HOME/.local/share/fonts/autanasoft` | env scripts (pre-flight), `setup-fonts` (install base) |

### Why `DOTFILES_FONTS_DIR` is exported

The current code hardcodes `$HOME/.local/share/fonts/autanasoft` in
**two** places (`scripts/setup-fonts:40` and the pre-flight in
`scripts/setup-omarchy:390`). Centralizing via a root export turns
two literals into one source of truth. Root computes it once and
exports; env scripts and the fonts script read it. This stays inside
the "root only exports real paths" rule because the value is a real,
user-visible target the env config depends on.

### Cleanup trap

```bash
trap 'unset DOTFILES_ROOT DOTFILES_ENV DOTFILES_DRY_RUN DOTFILES_BACKUP_DIR DOTFILES_FONTS_DIR' EXIT
```

Fires on every exit path: success, `fail`, parse error, env-script
non-zero. Strict superset of the previous spec.

## Env script flow — `scripts/setup-omarchy`

`scripts/setup-omarchy` is the canonical env script. Future
`scripts/setup-fedora` follows the same shape.

### Call chain inside `main()`

```text
1. log banner (repo root, env, mode)
2. require_command omarchy
3. require_command hyprctl
4. Step 1/N: invoke scripts/setup-deps
   - pass through $DOTFILES_DRY_RUN
   - let it auto-detect; $DOTFILES_ENV is informational only
5. Step 2/N: invoke scripts/setup-fonts
   - pass through $DOTFILES_DRY_RUN
   - idempotent; safe to always invoke
6. Pre-flight: verify $DOTFILES_FONTS_DIR exists and is non-empty
   (defense-in-depth for direct invocation without step 5)
7. Step 3/N: apply_symlinks $stamp
   (uses $DOTFILES_ROOT for repo paths, $HOME for target paths,
   $DOTFILES_BACKUP_DIR for backup)
8. Step 4/N: validate_system
   (omarchy theme, hyprctl reload + configerrors, zellij version)
9. log "Setup complete."
```

N is dynamic: 3 (no fonts) or 4 (with fonts). When root invokes
with `--fonts`, the env script still runs `setup-fonts` once. When
root invokes without `--fonts`, the env script still runs it (the
user wants the env configured; fonts are part of that). This keeps
the env script deterministic: every env run does the full flow.

### Why the env script invokes sub-scripts via exec, not source

`scripts/setup-omarchy` invokes `scripts/setup-deps` and
`scripts/setup-fonts` as **subprocesses** (matching the current
`run_deps` / `run_fonts` pattern in `setup:242-288`). The exported
`DOTFILES_*` vars cross the process boundary automatically; the
sub-scripts inherit them. No `source` is needed and would be
incorrect (it would conflate error handling and trap scope).

### Pre-flight on `$DOTFILES_FONTS_DIR`

Preserved from the current design (`scripts/setup-omarchy:390-393`):

```bash
if [[ ! -d "$DOTFILES_FONTS_DIR" ]] \
    || [[ -z "$(ls -A -- "$DOTFILES_FONTS_DIR" 2>/dev/null)" ]]; then
    fail "Nerd Fonts not installed under $DOTFILES_FONTS_DIR. Run './setup --fonts' first."
fi
```

Non-mutating. Runs in dry-run too. Defends the direct-invocation
case (user runs `scripts/setup-omarchy` without going through root
and without a fonts install).

## Env detection in `scripts/setup-deps`

### Detection order

`detect_env()` runs once, after argument parsing and `DOTFILES_DRY_RUN`
promotion:

| Probe | Resulting env | Notes |
| --- | --- | --- |
| `command -v yay` | `omarchy` | Yay is the documented Omarchy AUR helper. |
| else `command -v pacman` | `omarchy` (with `yay` not-found warning) | Pacman alone means Arch without AUR. Suggest installing yay. |
| else `command -v dnf` | `fedora` | DNF is the canonical Fedora package manager. |
| else `command -v rpm` | `fedora` (with `dnf` not-found warning) | RPM alone means a Fedora-derived system without DNF. |
| else | — (fail) | Clear error: "Could not detect a supported package manager (yay, pacman, dnf, rpm). Install one and re-run." |

Detection is **purely a probe** — no probing in dry-run is still a
probe. The script must never call `command -v` on a tool it then
needs to install (e.g. installing yay during detection would be
self-referential).

### Override flag

`--omarchy` and `--fedora` remain valid arguments to `setup-deps`
and act as an **explicit override** of the detected env. The
override is useful when:

- The user wants to install Omarchy packages on a non-standard system.
- The detection is ambiguous (e.g. both `yay` and `dnf` are on PATH
  in a chroot).
- A test wants to assert a specific package list.

If `--omarchy` / `--fedora` is passed, the env is forced and the
probe is skipped. This is a strict superset of the old behavior
(where the flag was required).

### New validation rule

When **no** env flag is passed and **detection fails**, fail with
the clear message above and exit 2 (usage error). When **no** env
flag is passed and **detection succeeds**, proceed silently. The
script no longer exits 2 with "choose an environment" — the user
isn't choosing, the system is.

### Compatibility with orchestrator

The root `setup` no longer passes `--omarchy` / `--fedora` to
`setup-deps` — but the script still accepts them. The override is
documented in the env script's own `usage()` and on `docs/setup.md`.

## Implementation delta per file

### `setup` (root)

| Action | Why |
| --- | --- |
| Delete `run_deps`, `run_fonts`, `run_env` helpers. | Pipeline lives in env scripts now. |
| Delete `TOTAL_STEPS` / `current_step` counter. | Root runs one script; the env script owns its own counter. |
| Delete the `if [[ "$DOTFILES_ENV" == "fedora" ]]` short-circuit block (root `setup:329-334`). | Replaced by a single top-level dispatch case. |
| Add `DOTFILES_FONTS_DIR` export (default `$HOME/.local/share/fonts/autanasoft`). | Centralize the convention. |
| Update `trap` to include `DOTFILES_FONTS_DIR`. | Cleanup. |
| Refactor main into a single `case` dispatch on the parsed flags. | One direct invocation per run. |
| Keep usage() text but trim the "Precedence" wording to match the new model. | Doc consistency. |

Expected net: roughly −140 / +20 lines (~−120 net).

### `scripts/setup-omarchy`

| Action | Why |
| --- | --- |
| Add internal helpers `invoke_setup_deps`, `invoke_setup_fonts` that match the old `run_deps` / `run_fonts` style but live in this script. | The pipeline moves here. |
| Add own `TOTAL_STEPS` / `current_step` counter for the env flow. | Step labels `1/N` … `N/N` come from this script now. |
| Update pre-flight check to read `$DOTFILES_FONTS_DIR` instead of hardcoding the path. | Honor the new variable contract. |
| Keep all existing symlink map, backup helper, SSH seed, validate_system. | Behavior preserved. |

Expected net: roughly +60 / −5 lines.

### `scripts/setup-deps`

| Action | Why |
| --- | --- |
| Add `detect_env()` function with the probe table above. | Self-detect. |
| Make `--omarchy` / `--fedora` optional overrides. | New contract. |
| Replace the "choose an environment" hard error with the "could not detect" hard error. | New contract. |
| Update `usage()` to document auto-detection. | Doc consistency. |
| Keep all package lists, `pkg_installed`, `install_package`, `pm_install_cmd`. | Behavior preserved. |

Expected net: roughly +50 / −20 lines.

### `scripts/setup-fonts`

| Action | Why |
| --- | --- |
| Read `$DOTFILES_FONTS_DIR` if set; fall back to current default. | Honor the new variable contract. |
| Keep install + cache-refresh logic unchanged. | Behavior preserved. |

Expected net: roughly +5 / −2 lines.

### `tests/setup-deps.bash`

The test file must be rewritten to reflect the new call chain. The
following table maps the six current tests to their new assertions.

| Old test | New behavior |
| --- | --- |
| 1. `--omarchy` dry-run runs deps before env | Rewritten: assert `setup-omarchy` is invoked and that the env script itself (not root) runs `setup-deps` and `setup-fonts`. Assert all three sub-scripts appear in the stub log in order. |
| 2. `--fedora` skip-without-deps | Preserved: short-circuit, no sub-scripts invoked. |
| 3. `--fonts` dry-run does not run deps | Preserved: root invokes `setup-fonts` directly; `setup-deps` not in log. |
| 4. `--deps` runs only `setup-deps` | Preserved: root invokes `setup-deps` directly; no `setup-fonts` and no env script. |
| 5. `--deps --omarchy` pre-flight (fonts present / missing) | Rewritten: with `--deps --omarchy` the root calls the env script; the env script internally calls `setup-deps` (auto-detect → omarchy), then `setup-fonts`, then runs its pre-flight. The two sub-cases (fonts present, fonts missing) become tests of the env script's own behavior, observable via the stub log. |
| 6. `DOTFILES_*` env vars unset | Preserved + extended: add `DOTFILES_FONTS_DIR` to the unset list. |

**New test 7** (env detection in `setup-deps`):
- Sub-case A: stub `yay` on PATH, run `scripts/setup-deps` directly,
  assert it uses the Omarchy package list and `pacman -Q` for
  verification.
- Sub-case B: stub `dnf` on PATH, run `scripts/setup-deps` directly,
  assert it uses the Fedora package list and `rpm -q` for
  verification.
- Sub-case C: no package managers on PATH, run `scripts/setup-deps`,
  assert non-zero exit with the "Could not detect" message.

`TEST_PLAN=7`.

### `docs/setup.md`

| Section | Change |
| --- | --- |
| Quick Path | Rewrite: root dispatches to one script; each script's flow is described. |
| Flags table | Keep flag definitions, but rewrite the "Precedence" prose to match the new model. |
| Dispatch matrix | Replace with the new "Root does / Env script does" table from above. |
| Cleanup | Add `DOTFILES_FONTS_DIR` to the unset list. |
| Scripts | Update roles: `setup-omarchy` now owns the full env flow; `setup-deps` auto-detects; `setup-fonts` reads the new env var. |
| Notes | Add a note on env auto-detection and the override flag. |

## Consequences for downstream artifacts

The previously-verified implementation and the artifacts derived from
it need to be regenerated. The list below is **explicit** so the
user can decide the next step.

| Artifact | Status | Reason |
| --- | --- | --- |
| `proposal.md` | **Regenerate** via `sdd-propose` | The "Problema" lists three small gaps. The actual problem is the entire dispatch model. Section "Alcance" and the rules table are now wrong. |
| `specs/setup-orchestration/spec.md` | **Regenerate** via `sdd-spec` | Requirement "Explicit `--deps` Mode" semantics shift. Requirement "Pre-Flight Verification" expands to "Env scripts own the full env flow". Precedence rule changes. New requirement: env auto-detection. New requirement: `DOTFILES_FONTS_DIR` export and cleanup. |
| `tasks.md` | **Regenerate** via `sdd-tasks` | The 4-task plan is no longer accurate. The 550 net lines applied previously reflect a different design. New tasks include: root shrink, env-script expansion, `setup-deps` auto-detect, fonts-dir override, test rewrite, doc rewrite. |
| `verify-report.md` | **Re-verify** after re-apply | The current verify report documents behavior of a design being replaced. The 6/6 tests, the spec-compliance matrix, and the deviation list all describe the deprecated architecture. The previous report should be archived (renamed with a `.deprecated-YYYYMMDD.md` suffix) and a new verify report produced after the re-apply. |
| `setup`, `scripts/setup-deps`, `scripts/setup-omarchy`, `scripts/setup-fonts` | **Re-apply** via `sdd-apply` | Code changes described in the "Implementation delta per file" sections above. Strict TDD is preserved: red tests first, then green implementation, then refactor. |
| `tests/setup-deps.bash` | **Re-apply** as part of the apply phase | Test rewrite is part of the new work units. |
| `docs/setup.md` | **Re-apply** as part of the apply phase | Doc rewrite is part of the new work units. |
| Engram observation #1369 (`sdd/ideas-implementation/design`) | **Upserted** by this design revision | The topic key is preserved; the content is replaced. |
| Engram observations #1377, #1378 | **Already present, referenced as inputs** | This design revision is the architectural answer to both decisions. |

## Risks

| Risk | Mitigation |
| --- | --- |
| Auto-detection picks the wrong env (e.g. `yay` from a chroot, `dnf` on a Fedora toolbox running on Arch) | `--omarchy` / `--fedora` override flag still works. Document the override prominently. |
| Env script invokes `setup-fonts` even when fonts are already installed, doubling the visible work in the step counter | `setup-fonts` is idempotent and the labels are deterministic. The step counter shows the full plan. If cosmetic, ignore. If blocking, the env script can probe `$DOTFILES_FONTS_DIR` and skip with a "fonts already present" log line. |
| Loss of the "Step 1/2" / "Step 2/2" labels in root output for env runs | The env script emits its own labels. Users see a "Step 1/N: install OS dependencies" line followed by the actual `setup-deps` output. Acceptable; the contract moves to the env script. |
| The thin root may feel under-used; maintainers might re-introduce pipeline logic | Add a one-paragraph comment at the top of `setup` explaining the boundary and pointing at `scripts/setup-omarchy` as the canonical env-script template. |
| Spec regeneration may introduce churn in OpenSpec delta | Acceptable; the delta spec exists precisely to track changes. The previous spec is archived on `sdd-archive`. |
| Re-apply breaks the test suite mid-flight (the test file is rewritten before the implementation matches) | Strict TDD: red tests land with the new test file, then green implementation, then refactor. The `sdd-apply` skill enforces this. |
| `DOTFILES_FONTS_DIR` env var conflict with anything else | Unlikely; `DOTFILES_*` namespace is repo-private. Document in `usage()`. |
| Verifier confidence in the new design is harder to build (previous report is invalidated) | New `verify-report.md` produced after re-apply. The old one is archived, not deleted, so the audit trail is preserved. |

## Out of scope

- No new env executors beyond the pattern. `scripts/setup-fedora`
  is still a future TODO; the design is ready for it but does not
  implement it.
- No change to symlink strategy, backup strategy, or SSH seeding.
- No change to the `tests/setup-deps.bash` framework itself
  (stubs, sandbox helpers, assertion helpers stay).
- No change to `AGENTS.md`, `README.md`, or `docs/conventions.md`.

## Acceptance — checklist for re-apply

- [ ] Root `setup` contains no `run_deps`, `run_fonts`, `TOTAL_STEPS`,
      `run_env`, or fedora short-circuit block.
- [ ] Root `setup` exports `DOTFILES_ROOT`, `DOTFILES_ENV`,
      `DOTFILES_DRY_RUN`, `DOTFILES_BACKUP_DIR`, `DOTFILES_FONTS_DIR`.
- [ ] Root `setup` `trap` unsets all five `DOTFILES_*` vars on EXIT.
- [ ] `./setup --omarchy` invokes `scripts/setup-omarchy` exactly once.
- [ ] `scripts/setup-omarchy` invokes `scripts/setup-deps` and
      `scripts/setup-fonts` as sub-scripts before applying the env.
- [ ] `scripts/setup-deps` auto-detects `yay`/`pacman` → omarchy,
      `dnf`/`rpm` → fedora, fails clearly otherwise.
- [ ] `scripts/setup-fonts` reads `$DOTFILES_FONTS_DIR` if set.
- [ ] `bash tests/setup-deps.bash` is 7/7 green.
- [ ] `docs/setup.md` describes the new boundary, the variable
      contract, and the auto-detection behavior.
- [ ] Previous `verify-report.md` is archived with a `.deprecated-…` suffix.
- [ ] New `verify-report.md` is produced from a re-apply run.

## Next step

Run `sdd-spec` to regenerate `specs/setup-orchestration/spec.md`
from this revised design. Then `sdd-tasks` to produce a fresh task
plan. Then `sdd-apply` (after archiving the previous verify report).
