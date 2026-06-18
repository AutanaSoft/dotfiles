# Explore: omarchy-only-scope

## Change

- **Slug**: omarchy-only-scope
- **Status**: needs-clarification
- **Created**: 2026-06-17
- **Scope lock**: Omarchy + CachyOS+Omarchy + Arch+Omarchy ONLY. Fedora (and any non-Omarchy target) is OUT OF SCOPE going forward.

## Context (verbatim user intent)

> "he decidido dejar este repor de dotfiles solo para compatibilidad con omarchy, cachyOS + omarchy y Arch + omarchy. no asumas nada, si tienes dudas pregunta antes de recomendar o generar codigo"

Translation: lock this repo to three targets — stock Omarchy, CachyOS
with Omarchy layered on top, and vanilla Arch with Omarchy layered on
top. The user is explicit: no assumptions, ask before recommending or
generating code.

This exploration phase produces no code and modifies no existing repo
file. It only writes this artifact under `openspec/changes/` so the
proposal phase has a concrete surface map.

## Current state — what the repo actually contains today

The repo already has half of the removal done. There is no
`scripts/setup-fedora`. `--fedora` is a deliberate short-circuit. The
work remaining is: confirm the scope lock, retire the Fedora
scaffolding (files, branches, tests, doc mentions), and update the
spec so it reflects the locked Omarchy-only contract.

### Top-level layout

| Path | Purpose | Fedora-coupled? |
| --- | --- | --- |
| `setup` | root thin dispatcher | **Yes**: parses `--fedora`, short-circuits |
| `AGENTS.md` | AI/contributor rules | **Yes**: env table lists Fedora; shared-layer comment |
| `README.md` | root README | **Yes**: env table, setup example, doc links |
| `omarchy/` | full env config + hyprland theme | No |
| `fedora/` | minimal stub: `bin/.gitkeep`, `config/{nvim,zellij,starship.toml}` symlinks into `shared/`, `home/{.gitconfig,.wezterm.lua,.zshenv,.zshrc}`, `README.md` | **Yes — entire folder** |
| `shared/` | canonical: `nvim/` (LazyVim), `zellij/`, `starship.toml`, `home/.ssh/config` template | No (already shared-agnostic) |
| `scripts/` | `setup-omarchy`, `setup-deps`, `setup-fonts`, `cleanup-omarchy` | **Yes**: `setup` + `setup-deps` carry Fedora branches |
| `tests/setup-deps.bash` | bash TAP harness | **Yes**: T3 asserts the `--fedora` short-circuit |
| `docs/` | `conventions.md`, `setup.md`, `shared-layer.md`, tool docs, `ideas/scripts/setup.md`, `inputs/{keyboard-remap,mouse-g502}.md` | **Yes**: several files mention `fedora/README.md` or `--fedora` |
| `openspec/config.yaml` | SDD bootstrap | **Yes**: project context mentions fedora |
| `openspec/changes/archive/` | four archived changes (2026-06-14, 2026-06-16, 2026-06-17 ×2) | Historical refs — **do not modify per archive rule** |
| `openspec/specs/setup-orchestration/spec.md` | main spec for the dispatcher | **Yes**: documents `--fedora` not-implemented behavior as a requirement |
| `openspec/specs/omarchy-preinstall-cleanup/spec.md` | cleanup script spec | No (clean) |

### Fedora surface area (factual, no opinion yet)

**Files / dirs (whole folder + scripts):**

- `fedora/` — 9 tracked entries: `bin/.gitkeep`, `config/nvim` (symlink → `../../shared/nvim`), `config/zellij` (symlink → `../../shared/zellij`), `config/starship.toml` (symlink → `../../shared/starship.toml`), `home/.gitconfig`, `home/.wezterm.lua`, `home/.zshenv`, `home/.zshrc`, `README.md`.
- `scripts/setup` — 17 Fedora references: parser flag (`--fedora`), `DOTFILES_ENV=fedora`, short-circuit block at `setup:234-238`, usage text (lines 86, 102, 121), validation, dispatch table, mutual-exclusion check, and the `--fedora --fonts` / `--fedora --deps` absorption rules.
- `scripts/setup-deps` — 24 Fedora references: `FEDORA_PACKAGES` array (5 packages: `lsof`, `hunspell`, `hunspell-en-US`, `hunspell-es`, `trash-cli`), `--fedora` flag parsing, `detect_env()` fedora branch (`dnf` → fedora, `rpm` → fedora+warn), `pkg_installed()` fedora branch (`rpm -q` / `dnf list installed`), `install_batch()` fedora branch (`sudo dnf install -y`), `main()` fedora case in the package list dispatch, and the help text.
- `tests/setup-deps.bash` — T3 (`test_fedora_short_circuit_exits_zero`) with two sub-cases (A: `--fedora` alone; B: `--fedora --fonts --deps --dry-run`); T8 sub-case D asserts Fedora substring array unchanged.
- `openspec/specs/setup-orchestration/spec.md` — `Requirement: --fedora not-implemented behavior` (line 195) with two scenarios (`--fedora exits 0 and skips work`); multiple cross-references throughout (Flag Contract, Quick Path, mutual exclusion, setup-deps auto-detect, override, batch install, single-pass install coalesces sudo, input-devices packages).

**Doc mentions (non-exhaustive, all factual):**

- `README.md` — env table row "Fedora | `fedora/` | WezTerm, Zellij, nvim, Zsh, Starship, Git, SSH"; `./setup --fedora --fonts` example; link to `fedora/README.md`.
- `AGENTS.md` — env table (line 13-15); line 27 "shared/ content is signed from omarchy; fedora follows".
- `docs/setup.md` — `--fedora` row in Accepted Flags table; "Valid Combinations" line; dep detection table (yay/pacman → Arch-like, dnf/rpm → Fedora-like); example `scripts/setup-deps --fedora`.
- `docs/conventions.md` — references `fedora/README.md` as an example of a per-env runbook.
- `docs/shared-layer.md` — "or any future env added at repo root" (line 4); keyd exception "Fedora is out of scope" (line 54).
- `docs/git.md`, `docs/wezterm.md`, `docs/ssh.md`, `docs/starship.md` — cross-link to `fedora/README.md`.
- `docs/ideas/scripts/setup.md` — Spanish-language original notes with `--fedora` examples.
- `openspec/config.yaml` — `context:` block names `fedora/` as an env.

### CachyOS+Omarchy and Arch+Omarchy — what we know vs what we need to ask

**What we know without further verification** (factual, in the repo):

- `scripts/setup-omarchy` preamble (lines 9-11): "Supports installs created from the Omarchy ISO, Arch + Omarchy layer, and CachyOS minimal + Omarchy layer. This script does NOT install Omarchy; it only connects an existing install to the dotfiles in this repository."
- The Omarchy upstream installer (omarchy.org / `omarchy` command) is the same target surface on all three base distros; the env script pre-flights `omarchy` and `hyprctl` on `PATH` and otherwise treats the three as one env.
- `OMARCHY_PACKAGES` in `setup-deps` is the same list for all three; the install command (`yay -S --needed`) requires `yay` on `PATH`, which is what Omarchy's bootstrap installs on top of any Arch-family base.
- The "CachyOS + Omarchy" variant differs from "Arch + Omarchy" only at the Omarchy bootstrap step (CachyOS ships its own kernel and `pacman` config); from the dotfiles' perspective both look like a stock Omarchy install once the layer is on top.

**What we need the user to confirm before designing**:

- Whether the user wants the repo to treat the three bases as **one** env (current behavior: same `omarchy/` folder, same `scripts/setup-omarchy`, no branching) or whether there is any per-base divergence the user wants to encode (CachyOS-specific tweaks, Arch kernel vs CachyOS kernel, custom AUR packages). **The current code shows the three are already one env — we should treat that as the locked answer unless the user objects.**

## Fedora surface area — what would be removed or archived

Per the repo's removal policy (`docs/conventions.md` line 43,
`AGENTS.md` line 28): "Comment out with `# Reason:` instead of
deleting." That policy applies to **content inside tracked config
files** (e.g. removing a block from a bash array). It does **not**
obviously extend to "remove an entire env folder" — that is a
structural decision the user must make. Two viable paths:

**Path A — Comment-out / mark deprecated inside tracked files** (fits
existing policy):

- `fedora/` folder: leave in place, prefix every entry with a
  deprecation comment (or `README.md` only) stating "Reason: out of
  scope as of 2026-06-17".
- `scripts/setup` `--fedora` branch: keep parsing `--fedora`, but make
  it print an explicit "Fedora is out of scope" error and exit
  non-zero. The test `test_fedora_short_circuit_exits_zero` gets
  inverted to assert non-zero exit + the out-of-scope message.
- `scripts/setup-deps` `FEDORA_PACKAGES` array: comment out with
  `# Reason:`; the fedora branch in `install_batch` /
  `collect_missing` / `pkg_installed` stays for the `--fedora` flag
  override path (now used only for error reporting, not real install).
- Spec delta: change `Requirement: --fedora not-implemented behavior`
  to a new requirement — e.g. `Requirement: --fedora out-of-scope
  behavior` — that locks the rejection.

**Path B — Hard removal** (cleanest, but heavier diff):

- `git rm -r fedora/` and add a note in `openspec/changes/archive/<date>-fedora-removal/`.
- `setup`: remove `--fedora` parsing, dispatch, validation, usage text, mutual-exclusion (since there is only one env now).
- `setup-deps`: remove `--fedora` parsing, `FEDORA_PACKAGES`, fedora branches in `detect_env` / `pkg_installed` / `install_batch` / `main`. The auto-detect probe collapses to `yay` → omarchy (with `pacman` warning), else fail.
- `tests/setup-deps.bash`: remove T3, remove T8-D fedora substring array. Add a regression test that `--fedora` is now an unknown flag (or that any two env flags are mutually exclusive, if we keep only one).
- `openspec/specs/setup-orchestration/spec.md`: delete the `--fedora not-implemented behavior` requirement and every cross-reference; delete `Requirement: Fedora single-pass install coalesces sudo`; delete `--fedora` row from Flag Contract; delete `--fedora` line from setup-deps override scenarios; delete `--fedora` line from auto-detect probe table; delete the input-devices "Fedora package list is unchanged" / "Fedora dry-run is unchanged" scenarios; delete `--fedora` substring from "Documentation and test coverage".
- `openspec/config.yaml`: rewrite the `context:` block to a one-env statement.
- All `docs/*` files: scrub mentions of `fedora/`, `fedora/README.md`, `--fedora`, WezTerm, Zsh, dnf, rpm from `git.md`, `wezterm.md`, `ssh.md`, `starship.md`, `setup.md`, `conventions.md`, `shared-layer.md`. Delete `docs/ideas/scripts/setup.md` (it is a Spanish-language precursor of the now-superseded flag list).
- `README.md` and `AGENTS.md`: rewrite env table to one row; rewrite shared-layer line; remove Fedora setup example.

**Tradeoff**: Path A keeps the historical surface visible (good for
archival traceability; matches the user's stated "no asumas nada" by
preserving the option to restore Fedora later). Path B is a cleaner
end state but produces a larger diff (~500 lines net) and is
non-reversible without restoring from git history.

## OpenSpec impact

- **Archived changes that referenced Fedora** (must not be modified per
  `openspec/config.yaml` archive rule: "Never delete or modify archived
  change folders"):
  - `openspec/changes/archive/2026-06-14-ideas-implementation/` — defines the `--fedora` short-circuit contract.
  - `openspec/changes/archive/2026-06-16-cleanup-omarchy/` — references `fedora/` in `apply-progress.md` and `archive-report.md`.
  - `openspec/changes/archive/2026-06-17-input-devices-config/` — references fedora package list, the not-implemented message, and the dnf dry-run line; the verify report asserts T3 (`--fedora short-circuits`).
  - `openspec/changes/archive/2026-06-17-setup-deps-batch-install/` — covers `scripts/setup-deps --dry-run --fedora` and the `Fedora single-pass install coalesces sudo` requirement.
  These are historical context and **stay as-is**.
- **Main spec** `openspec/specs/setup-orchestration/spec.md` will need
  a new delta in the change folder: remove the `--fedora
  not-implemented behavior` requirement, remove `Requirement: Fedora
  single-pass install coalesces sudo`, drop `--fedora` from Flag
  Contract / mutual-exclusion scenarios / auto-detect probe table /
  override scenarios / input-devices cross-tests / doc coverage
  scenarios. During archive, this delta is merged into
  `setup-orchestration/spec.md` and removed from the change folder.
- **Main spec** `openspec/specs/omarchy-preinstall-cleanup/spec.md`:
  clean. No edits needed.
- **config.yaml**: rewrite the `context:` block to "one env,
  Omarchy-family" (Omarchy + CachyOS+Omarchy + Arch+Omarchy); update
  the `rules:` block examples that reference `<env>/` symlink targets
  (currently cites `omarchy/README.md` and `fedora/README.md`).
- **Spec changes via delta**: the proposal phase will write
  `openspec/changes/omarchy-only-scope/specs/setup-orchestration/spec.md`
  describing only the delta (additions / removals) over the current
  main spec.

## Tradeoffs and unknowns

1. **Path A (comment-out) vs Path B (hard removal)** — see the "Fedora
   surface area" section above. This is the main fork.
2. **`setup-deps` auto-detect simplification** — once Fedora is gone,
   the probe table collapses to `yay` → omarchy, `pacman` →
   omarchy+warn, else fail. Removing the `dnf`/`rpm` rows is part of
   Path B. Path A keeps the rows but with `# Reason:` comments.
3. **`--fedora` as unknown flag vs explicit rejection** — if we keep
   the flag for traceability (Path A), should `--fedora` still exit 0
   or exit non-zero? The current behavior is exit 0 with a "not
   implemented" message. After scope lock, exit non-zero with an
   explicit "out of scope" message is more honest. Path B removes the
   flag entirely (so it would naturally be rejected as "unknown flag"
   and exit 2, matching the existing unknown-flag contract).
4. **Removal policy for the `fedora/` folder** — the repo's
   `docs/conventions.md` rule is "comment out with `# Reason:` instead
   of deleting." That rule is written for **content inside files**,
   not for whole folders. We need the user's call.
5. **Test scope after removal** — does the user want the test harness
   to retain coverage of "distro other than Omarchy-family is
   rejected" (positive behavioral contract), or is removing T3
   entirely acceptable?
6. **`docs/ideas/scripts/setup.md`** — old Spanish-language notes
   predating the current dispatcher. Currently untouched for months.
   Worth deleting alongside the scope cut, or leave as historical
   notes?
7. **Archived changes** — even though we won't modify them, the
   proposal/verify reports will continue to mention `--fedora`. That
   is correct archival behavior; we should call it out in the
   proposal so the user knows historical refs survive.

## Clarifying questions for the user (MUST ASK — user said do not assume)

The user explicitly said "no asumas nada, si tienes dudas pregunta
antes de recomendar o generar codigo". The exploration cannot proceed
to a complete recommendation without answers to these. Each question
is a single decision point; the user can answer them in any order.

1. **Estrategia de remoción para la carpeta `fedora/`**: ¿la dejás
   como carpeta "deprecated" con un `README.md` que explique que está
   fuera de alcance a partir de 2026-06-17 (camino conservador, sigue
   la política de `# Reason:` ya documentada en `docs/conventions.md`),
   o preferís `git rm -r fedora/` y dejarla solo en el historial de
   git (camino limpio pero más invasivo)?

2. **Comportamiento del flag `--fedora` en `./setup` y
   `scripts/setup-deps`**: ¿lo eliminás por completo (rechazado como
   flag desconocido, exit 2), o lo dejás parseado pero rechaza con un
   mensaje explícito "Fedora is out of scope for this repo" y exit
   distinto de cero (más informativo, mantiene un punto de falla
   claro)?

3. **Lista `FEDORA_PACKAGES` y ramas fedora en `scripts/setup-deps`**:
   ¿comentás todo con `# Reason: Fedora out of scope (2026-06-17)` y
   dejás el código como recordatorio histórico, o eliminás la rama
   fedora de `detect_env`, `pkg_installed`, `install_batch` y `main`
   para que la auto-detección colapse a `yay`/`pacman` → omarchy?

4. **Test T3 (`test_fedora_short_circuit_exits_zero`) en
   `tests/setup-deps.bash`**: ¿lo eliminás, o lo invertís para
   afirmar que `--fedora` ahora sale con código distinto de cero y
   muestra el mensaje "out of scope"? Esto define si queremos
   mantener una cobertura de regresión para "distro fuera de alcance
   es rechazada".

5. **Spec delta**: ¿la propuesta debe eliminar el requirement
   `--fedora not-implemented behavior` y `Fedora single-pass install
   coalesces sudo` de `openspec/specs/setup-orchestration/spec.md` y
   agregar un nuevo requirement `Omarchy-family scope lock` que
   declare explícitamente los tres targets soportados
   (Omarchy + CachyOS+Omarchy + Arch+Omarchy), o preferís que la
   propuesta conserve alguna referencia histórica a fedora solo en
   las notas / out-of-scope del spec?

6. **CachyOS+Omarchy y Arch+Omarchy como un solo env**: el comentario
   en `scripts/setup-omarchy` líneas 9-11 ya dice que el script
   soporta los tres. ¿Confirmás que los tres se tratan idénticamente
   (mismo `omarchy/`, mismo `OMARCHY_PACKAGES`, misma
   auto-detección), o hay alguna divergencia por base
   (kernel CachyOS, paquetes AUR extra, config de pacman) que
   querés codificar como variante? Por defecto voy a asumir que son
   idénticos salvo que digas lo contrario.

7. **Doc `docs/ideas/scripts/setup.md`**: es una nota vieja en
   español con ejemplos de `--fedora`. ¿La eliminás junto con el
   scope cut, o la dejás como rastro histórico (no se actualiza
   más)?

8. **Referencias históricas en cambios archivados**: los cuatro
   cambios en `openspec/changes/archive/` contienen menciones a
   `--fedora` y al `setup-fedora` que nunca existió. La regla de
   archive dice "never delete or modify archived change folders", así
   que esas menciones van a sobrevivir. ¿Confirmás que está bien
   dejarlas tal cual (son contexto histórico correcto), o querés que
   la propuesta agregue una nota al inicio de cada verify-report
   afectado diciendo "predates the Omarchy-only scope lock"?