# Fedora pi-dev contract alignment

## Objective

Align Fedora WSL2 setup tests and documentation with the intentional `pi-dev` development profile
path `~/.pi/dev`, preserving the existing launcher behavior.

## Scope and constraints

- `fedora-wsl2/home/config/bash/functions` is intentionally simple: `pi-dev` sets only
  `PI_CODING_AGENT_DIR="$HOME/.pi/dev"`, forwards arguments, and does not define `pi-ext` or manage
  authentication/session links. Do not alter it without fresh evidence and approval.
- Update only `tests/fedora-wsl2/setup-contract.sh` and `docs/setup.md` for behavior and
  documentation; existing user changes in all other paths remain untouched. The user subsequently
  authorized aligning their stale Herdr 0.8.2 references with the committed `latest` configuration,
  without changing `fedora-wsl2/home/config/mise/config.toml`.
- Avoid asserting a default session storage path that cannot be established from the installed Pi
  0.87.1 documentation. If an explicit `PI_CODING_AGENT_SESSION_DIR` is present, the launcher
  inherits it unchanged.
- The separate Omarchy monitor plugin commit `8a762c6` remains intact on the current branch. The
  pre-existing untracked `.codegraph/` stays excluded. The user requested review and commit
  preparation for this work unit; no push is authorized.

## Tasks

- [x] P1: Rewrite the obsolete Fedora Pi launcher contract to reflect `~/.pi/dev`, inherited session
      override, argument forwarding, parent environment preservation, and absence of obsolete
      `pi-ext`/auth-link setup. Route: delegated writer (multi-file with docs); observe existing RED
      and focused GREEN.
- [x] P2: Document the Fedora `pi-dev` usage and isolation boundary in `docs/setup.md`; run Prettier
      before markdownlint and independently verify Fedora and full profile suites. Route: delegated
      writer plus independent verifier if native assessment requires it.
- [x] P3: Align the Herdr test assertion and documentation with the existing `herdr = "latest"`
      configuration, without editing the configuration. Route: delegated writer for the same two
      scoped files; observe the existing Herdr RED and rerun both suites.
- [x] P4: Align two further stale Mise test selectors with the committed config: Python `latest`
      instead of fixed `3.14.7`, and unqualified `markdownlint-cli2 = "latest"` instead of the
      npm-qualified key. Route: delegated writer within the test file; keep Mise config untouched.
- [x] P5: Replace the Fedora Bash PATH test's exact equality with prefix/relative-order validation
      while retaining presence and uniqueness under active Mise. Route: delegated writer on the test
      file, expressly authorized; do not modify Bash config.

## Acceptance and checks

- Fedora test no longer requires shared sessions/auth links or `pi-ext` and still guards the live
  `pi-dev` contract with a nonempty positive test.
- Documentation explains `PI_CODING_AGENT_DIR=~/.pi/dev`, no forced session/auth sharing, and makes
  no unsupported claims about Pi defaults.
- `./tests/run.sh fedora-wsl2`, `./tests/run.sh`, Bash syntax, Markdown formatting/lint, and diff
  check pass; record any failure or skipped check honestly.

## Forecast and delivery

Approximately 130 changed lines of test cleanup and concise documentation. One reviewable work unit.
The user approved its local commit; no push authorized.

## Progress

- 2026-09-28: Explored launcher, stale test block, setup docs, installed Pi 0.87.1 configuration and
  session documentation.
- P1/P2: The delegated writer updated the Fedora Pi test block and added a `pi-dev` paragraph in
  `docs/setup.md`; launcher unchanged. Original Fedora suite failed at the shared-session assertion
  (RED). After edits, the new Pi assertions pass sequentially but the suite exits later at a
  pre-existing Herdr `0.8.2` assertion (Mise declares `latest`), so suite GREEN was not observed.
  Independent verifier reproduced the same ordering. `bash -n`, Prettier, markdownlint on docs, and
  `git diff --check` passed. Assessment was unassessable due to untracked files and routed to
  independent verification.
- P3: The user approved updating only the stale Herdr test/docs expectation to `latest`; the Mise
  configuration remains unchanged. Writer made those two changes; Fedora suite advanced past Herdr
  but failed on the stale Python 3.14.7 assertion, so GREEN was not observed. The writer stopped
  without running remaining checks; they are pending.
- P4: Read-only mapping found exactly two remaining Mise selector mismatches in the current test:
  Python fixed `3.14.7` versus committed `latest` and npm-qualified `markdownlint-cli2` versus the
  committed unqualified key. The user explicitly approved aligning only those two assertions with
  existing config; no manifest changes authorized. The writer changed only those assertions; the
  suite advanced to a Bash PATH equality failure. Syntax passed; other checks were not run after the
  failure.
- P5: Independent read-only reproduction showed three configured home paths present, unique, and
  first in order, followed by extra entries from `mise activate bash`. The exact five-component PATH
  assertion is environment-sensitive; user approved a test-only relative-order/prefix correction.
  After the prefix correction, independent verification found that the original global replacement
  could hide duplicate PATH entries. A synthetic duplicate passed the old check (RED), then failed
  the single-occurrence removal check (GREEN). Fedora and full suites both passed afterward.
- Closure: Independent verification passed Bash syntax, `./tests/run.sh fedora-wsl2`,
  `./tests/run.sh`, Prettier, markdownlint-cli2 (two files), and `git diff --check`. The parent
  repeated `git diff --check` successfully. No launcher, Mise config, or unrelated files changed. A
  live Fedora setup was not performed; the Pi default session path without an override remains
  untested. A subsequent independent pre-commit review found no concrete issue and repeated all
  applicable checks successfully.

## Next step

The Fedora docs/test and this task document form one local work-unit commit; the commit identity is
recorded in the feature's Engram mirror after creation. No push or PR authorization. Live Fedora
setup and Pi's default session path without a caller override remain unverified.
