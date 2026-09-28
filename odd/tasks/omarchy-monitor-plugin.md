# Omarchy monitor plugin migration

## Objective

Preserve the installed `lcardenas.monitor` widget in dotfiles, replace the obsolete monitor CLI, and
make activation reproducible without overwriting the user's shell layout.

## Scope and constraints

- Source: snapshot the existing three files in `~/.config/omarchy/plugins/lcardenas.monitor/`,
  without changing their behavior.
- Link the plugin directory from `omarchy/dots-manifest`; remove its obsolete monitor script and
  manifest entry.
- Enable the widget on fresh Omarchy sessions without changing an already enabled widget's position
  or settings; do not manage the entire `shell.json`.
- Preserve the existing live plugin directory with the setup helper's backup behavior. Remove the
  old live monitor symlink only when it still points to the removed repo file.
- Keep the unrelated untracked `.codegraph/` untouched. The user separately authorized a commit for
  the Omarchy migration; Fedora WSL2 work is deferred to a following step.
- Installed Omarchy version: 4.0.4. Source claims checked against
  `/usr/share/omarchy/shell/README.md` and installed CLI scripts.

## Tasks

- [x] T1: Snapshot and validate the plugin in
      `omarchy/home/config/omarchy/plugins/lcardenas.monitor/`; link it with
      `omarchy/dots-manifest`; remove the obsolete script and manifest entry. Route: delegated
      writer (multi-file write); inspect exact copy and validate manifest.
- [x] T2: Make activation idempotent in the setup flow, preserving enabled widgets and defining
      behavior when the shell service is unavailable. Route: delegated writer (behavior change);
      observe RED/GREEN with a deterministic test if feasible, otherwise record why and perform
      functional checks.
- [x] T3: Document the new plugin lifecycle and verify focused syntax, validator, setup dry-run, and
      active-shell behavior where available; account for the old live symlink safely. Route:
      delegated writer for documentation, independent verifier per native assessment; record blocked
      live checks.
- [ ] T4: Relocate the focused monitor setup test into `tests/omarchy/` and register it in the
      normal Omarchy runner. Route: delegated writer (test file plus runner); verify the suite
      actually executes the new cases and retains existing setup contracts.
- [ ] T5: Resolve the pre-existing Fedora WSL2 contract failure in the full suite, deferred by the
      user until after the Omarchy commit. Route: pending separate work and authorization.

## Acceptance and evidence

- Repository contains the exact installed plugin files, and the manifest no longer links the legacy
  monitor command.
- Re-running setup does not duplicate or reposition an enabled widget; fresh installs can enable it
  on the right, with an explicit fallback for missing shell IPC.
- Dry-run performs no mutations. Live directory data is backed up before a replacement symlink; no
  unrelated paths change.
- Verification evidence, failures and pending checks are recorded below as observed.

## Forecast and delivery

Approximately 1100 authored lines from the existing plugin snapshot plus small setup/docs changes;
indivisible plugin source and above the ~400-line review heuristic. Avoid cosmetic splitting.
Delivery strategy: ask-on-risk; the user explicitly requested this local commit. No push or PR.
Receipt-driven development is off for this clone.

## Progress

- 2026-09-28: Explored installed plugin and setup conventions. Created feature branch
  `feat/omarchy-monitor-plugin`.
- 2026-09-28: User requested correction after identifying that `omarchy/tests/` sits outside
  `tests/run.sh omarchy`. Reopened the feature with T4; preserve completed T1–T3.
- T1: Copied the three installed plugin files without byte changes; replaced the manifest script
  entry with a plugin directory symlink entry; removed the legacy repo script. `cmp -s` on all three
  files, `omarchy plugin validate`, and `git diff --check` passed. No commit (repository requires a
  separate explicit request).
- T2: Initial implementation passed mocked cases and `bash -n`. Reopened after confirming installed
  `/usr/share/omarchy/shell/services/PluginRegistry.qml` completes rescans asynchronously: immediate
  `listPlugins` can be stale. Added bounded discovery polling (15 attempts at 0.1 s);
  delayed-discovery test failed before correction (RED), passed afterward (GREEN), and the full
  focused cases and `bash -n` passed. No commit.
- T3: Documented plugin lifecycle and ran independent verification of syntax, focused cases, source
  validator, Prettier, markdownlint, full-manifest dry-run, and live enabled-state readback. Applied
  `setup-dots`: the original live plugin was backed up under
  `backup/20260928T071251Z/.config/omarchy/plugins/lcardenas.monitor`, the live plugin path became a
  symlink to the repo snapshot, and the exact obsolete monitor link was removed. The backup's three
  files match the snapshot. No commit.
- T4: Moved the standalone script from `omarchy/tests/` to `tests/omarchy/` and registered it in
  `tests/run.sh`. Focused test, `./tests/run.sh omarchy`, `bash -n`, and `git diff --check` passed;
  suite output includes `setup-dots monitor plugin cases passed`. `./tests/run.sh` fails at an
  unrelated committed Fedora WSL2 pi-dev contract; the user explicitly deferred that issue until
  after the Omarchy commit. No Fedora files were changed.

## Checks

- Passed T1: plugin validator, source equality, `git diff --check`.
- Passed T2: mocked setup cases including dry-run, `bash -n`, `git diff --check`.
- Passed T3 documentation edit: Prettier, markdownlint-cli2 and `git diff --check` on
  `docs/hypr.md`.
- Passed T3: full manifest dry-run proposed only the intended plugin backup/link and obsolete link
  removal; live shell reports `lcardenas.monitor` enabled and built-in `omarchy.monitor` disabled;
  current bar layout retains its position. Backup file equality and link target readback passed.
- Failed extra check: `omarchy plugin validate ~/.config/omarchy/plugins/lcardenas.monitor` rejects
  the top-level symlink; the actual repo source directory validates successfully. The installed
  registry scans linked directories and reports the widget enabled, but visible panel rendering
  remains unverified. Fresh-machine setup behavior was exercised only in mocked tests.
- Native assessment: unassessable due to untracked files requiring explicit declaration (including
  unrelated `.codegraph/`); independent verifier completed. Parent spot-check `git diff --check`
  passed.
- Passed T4 focused integration: relocated test and Omarchy profile runner. Failed full suite:
  Fedora WSL2 expects `~/.pi/agent/sessions` but the committed launcher inherits
  `PI_CODING_AGENT_SESSION_DIR=normal-sessions`; neither Fedora file changed in this candidate.
  Independent verifier confirmed the committed mismatch without changing it.

## Next step

Commit the Omarchy migration and focused suite integration, excluding `.codegraph/` and Fedora
files. Address the known full-suite Fedora WSL2 failure in separate follow-up work.
