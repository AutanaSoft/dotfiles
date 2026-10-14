# Backup mirror

## Objective

Implement a guarded, configurable personal-folder mirror to the Backup NTFS volume.

## Scope and constraints

- One self-contained `mirror.conf`: destination, UUID, folders and exclusions; no external includes.
- Preserve existing backup scripts/configuration and unrelated user changes.
- Dry-run by default; explicit `--apply`; never mount, use sudo, or copy real personal data in
  tests.
- Expected UUID: `7AA6431BA642D6F3`. Mount automation is out of scope.
- Exclusions protect destination entries; no `--delete-excluded`.
- Commit explicitly approved by the user for this feature; no push is authorized.

## Tasks

- [x] T1: Implement script, configuration, focused test-first coverage, usage docs and linkage.
- [x] T2: Independently verify safety, focused and repository tests; resolve confirmed defects.
- [x] T3: Simplify folder/exclusion entries to presence-only lists with parser tests.
- [x] T4: Verify simplified grammar and preserved mirror safety.

## Acceptance and checks

- Declarative configuration and safe relative folders; no source/eval.
- Folder/exclusion lists use bare lines, with comments/blanks; destination stays key-value.
- Remove redundant boolean assignments and preserve duplicate/path validation.
- Correct mounted UUID, safe destination/source validation and exclusive lock.
- Real rsync tests in temporary trees cover preview/apply, scoped deletion and exclusions.
- Missing sources, wrong/unmounted device, overlapping paths and transfer failures abort honestly.
- Document NTFS limitations and non-atomic updates; preserve existing scripts.
- Run bash syntax, focused tests, repository tests, Markdown formatting/lint and diff checks.

## Progress and evidence

- Presence-only list change: writer `muui2orv-8-0hki` observed RED (malformed bare entry), then
  GREEN for focused tests; full suites, syntax, docs format/lint and diff checks passed.
- ASSESS still unassessable for untracked scope; independent verifier `muuiclp0-9-01xu` passed
  grammar fixtures, all focused/full tests, syntax, docs Prettier/lint and diff checks.
- Bare entries, comments/whitespace and spaces accepted; duplicates, malformed destination, obsolete
  assignments and invalid exclusion references rejected without transfers.
- Root/prerequisite/deletion/UUID/path/concurrency safety retained; real volume untouched.
- List assignments now reject clearly; destination keeps key-value grammar.

- Read-only plan approved; user explicitly requested implementation.
- T1 writer returned six implementation/integration surfaces with 528 new lines plus two integration
  lines.
- Writer observed RED from missing implementation after harness correction, then focused GREEN and
  repository suites passing.
- Writer bash syntax, docs Prettier/Markdownlint and diff checks passed; ShellCheck/shfmt
  unavailable.
- ASSESS was unassessable due undeclared untracked files: independent verification required.
- Independent verifier confirmed four blockers: preview omits deletions; missing rsync mutates
  destination; root not rejected; alternate XDG runtime bypasses lock.
- Six standard verification commands passed, but temporary extra regressions reproduced all four
  blockers.
- Correction writer `muuh9wf4-6-3uu4` fixed all four defects; focused tests, syntax, repository
  suites and diff checks passed.
- Preview/apply now share --delete; preview adds --dry-run. Prerequisites and --mkpath capability
  checked before mutation; root refused; lock uses UUID under canonical /run/user/UID.
- Writer separately observed RED for preview and missing-rsync; independent verifier pre-correction
  evidence supplies root/lock failing behavior (writer fail-fast did not separately reproduce those
  REDs).
- Corrected artifacts total 587 lines plus two integration lines; cohesive feature/tests/docs,
  increased review workload disclosed.
- Independent verifier confirmed Markdownlint actually processed both docs: summary counts
  issue-bearing files, not analyzed files. Both passed lint.
- Fresh independent regressions passed: preview/apply deletion parity, prerequisite/capability
  no-mutation, root rejection, cross-runtime and same-UUID alias locking.
- Focused tests, syntax, full suites, docs Prettier and diff checks passed independently.
- Task-document Prettier wrapping initially failed; parent formatted it and reran focused spot
  tests, both-doc Prettier/Markdownlint and diff checks successfully.
- Real Backup/NTFS, physical disconnect races, ShellCheck/shfmt unavailable checks and native
  RDD-off review are explicitly not performed.
- Nested findmnt mount detection and child symlink outside-sentinel checks passed; no defect claimed
  there.
- Settled independent revalidation `muuhqoy2-7-7x13` passed all regressions; no remaining
  implementation blockers. Final task formatting checked by parent, not rerun independently.
- Real volume untouched; initial installation and real-volume preview remain user next steps.
- Baseline dirty: mise/config.toml, nvim spell file and untracked .codegraph; preserve all.
- RDD clone-local off; no native review will be started.
- rsync and Markdown tools available; shellcheck and shfmt unavailable on PATH.
- Commit authorized: `feat(omarchy): add guarded backup mirror command` on `feat/backup-mirror`.
- Commit identity is recorded in the delivery response and feature memory after Git creates it.

## Next step

Review configured folders/exclusions before the next authorized real-volume preview. Real-volume
preview/apply and mounting automation remain separate.
