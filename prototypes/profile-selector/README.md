# Bash Profiles selector demo

Run the isolated Bash + ANSI prototype from the repository root:

```bash
bash prototypes/profile-selector/demo.sh
```

It needs an interactive Bash 5 terminal, `stty`, UTF-8 and ANSI support. The application has no Python, TUI,
package-manager or installer runtime dependency. Python's standard-library PTY harness is used only by the tests.

## Keyboard and safety

| Key       | Profiles                                       | Simulated destination          | Availability check |
| --------- | ---------------------------------------------- | ------------------------------ | ------------------ |
| Up / Down | Bounded navigation; skips unavailable profiles | —                              | Ignored            |
| Enter     | Open a fictitious destination                  | —                              | Ignored            |
| Esc       | Exit immediately                               | Return to Profiles and recheck | Exit immediately   |

The destination only states which fixture was selected. It never opens Components or sources, reads, evaluates or
executes a `setup` path. A real filesystem check is available for demonstration, but it only tests `[[ -f && -x ]]`.

## Scenarios

Set `PROFILE_DEMO_SCENARIO` to choose a reproducible fixture state. The default is `normal`.

| Scenario            | Expected state                                                                               |
| ------------------- | -------------------------------------------------------------------------------------------- |
| `normal`            | Both registered fixtures are simulated as available.                                         |
| `first-unavailable` | Omarchy is dimmed and skipped; Fedora WSL2 receives initial focus.                           |
| `all-unavailable`   | Both remain visible and dimmed, with the compatibility message below the panel.              |
| `empty`             | The panel says `No profiles available.`; only Esc is active.                                 |
| `error`             | A red, wrapped error detail replaces the list; there is no retry.                            |
| `long`              | Two registered profiles plus 24 fictitious, non-installable fixtures for scrolling.          |
| `return-change`     | Fedora WSL2 becomes unavailable after returning from its simulated destination.              |
| `filesystem`        | The declared paths are checked for a regular file and executable permission; no file is run. |

Examples:

```bash
PROFILE_DEMO_SCENARIO=first-unavailable bash prototypes/profile-selector/demo.sh
PROFILE_DEMO_SCENARIO=long PROFILE_DEMO_DELAY=2 bash prototypes/profile-selector/demo.sh
PROFILE_DEMO_SCENARIO=filesystem bash prototypes/profile-selector/demo.sh
```

`PROFILE_DEMO_DELAY` defaults to `0.7` seconds and accepts values from 0 to 30 seconds. The initial check displays an
animated blue Braille spinner inside the panel. A return check retains the list and focused row while showing the
spinner below the panel. During either check only Esc is active. For `return-change`, select Fedora WSL2, press Esc in
the mock destination, then wait for the recheck to move focus to Omarchy. The selected fixture becomes unavailable.

The filesystem scenario resolves the TSV setup paths relative to this directory and checks only `-f` and `-x`. The
harness can point those checks at isolated fixtures with `PROFILE_DEMO_SETUP_ROOT` and use a temporary registry with
`PROFILE_DEMO_FIXTURE_FILE`; both are test hooks. No setup file is executed.

## Registry format

`fixtures.tsv` is the central, ordered registry. Its tab-separated columns are `order`, `id`, `name`, `description` and
`setup`. The explicit order is Omarchy followed by Fedora WSL2. TSV replaces the former `fixtures.json`: order is now a
required consecutive integer starting at 1, and the error detail and scenario names live in the Bash demo rather than
the registry. Each row has five nonempty tab-separated fields; setup paths are repository-relative references beginning
with `../../`, resolved from the prototype directory. The Bash application and tests use TSV directly without JSON
tooling or Python. Rows are read literally: they are never sourced or evaluated, malformed rows and terminal control
characters are rejected, and displayed values use literal string formatting. Availability is a scenario override in the
demo logic, not a production `available` field in the registry. Long-list fixture records are generated only for the
`long` scenario and use non-installable path labels.

## Visual review checklist

Use an interactive terminal and verify each item manually:

1. **First load:** run with `PROFILE_DEMO_DELAY=2`; confirm the spinner animates inside the panel and Esc exits while
   arrows and Enter remain inactive.
2. **Normal / return:** wait for the list, navigate to Fedora WSL2, press Enter then Esc; confirm the selected row and
   list remain visible while the return spinner appears below the panel, then confirm selection works again.
3. **Long list:** use `PROFILE_DEMO_SCENARIO=long`; scroll to both ends and check `↑ More` / `↓ More`, fixed header and
   footer, and preserved focus/scroll after Enter then Esc.
4. **Unavailable:** inspect `first-unavailable` and `all-unavailable`; unavailable rows are fully muted, skipped and
   never focused.
5. **Empty and error:** inspect `empty` and `error`; confirm the empty message alignment, red wrapped detail and lack of
   a retry action.
6. **Resize:** start at 32×24, resize while running, then try a very small terminal and confirm a resize notice rather
   than clipped panel content.
7. **Optional filesystem check:** run the `filesystem` scenario to see the read-only path status for this checkout.

These checks show actual terminal-cell output; they are not screenshots or pixel comparisons.

## Capture actual terminal output

Resize your emulator to 80 columns by 24 rows and verify that `stty size` prints `24 80`. If util-linux `script` is
already present, record the actual demo output under this directory:

```bash
capture_dir=$(mktemp -d prototypes/profile-selector/capture-XXXXXX)
PROFILE_DEMO_SCENARIO=normal PROFILE_DEMO_DELAY=2 \
  script --quiet --flush --log-out "$capture_dir/session.typescript" \
  --log-timing "$capture_dir/session.timing" \
  --command 'bash prototypes/profile-selector/demo.sh'
```

Take a screenshot using your emulator or desktop while the desired state is visible, before exiting with Esc. The PTY
log is real terminal output, not an image. Repeat in a fresh capture directory after resizing to 32 columns by 24 rows
(`stty size` prints `24 32`), or with `PROFILE_DEMO_SCENARIO=long` for scrolling and return checks. Do not install
capture tools for this demo if they are absent; the interactive visual checklist still works.

Before removing the superseded implementation, seven PTY comparisons produced identical ANSI-stripped, trailing-space
normalized text: normal at 80×24 and 32×24, plus first/all unavailable, empty, error and long at 80×24. This compares
real program output, not emulator rendering or colors.

## Automated checks

```bash
bash -n prototypes/profile-selector/demo.sh
python3 -B -m unittest discover -s prototypes/profile-selector -p test_demo.py
```

The 21 PTY tests launch `bash demo.sh` with the PTY attached to stdin/stdout; they do not require `/dev/tty`. They
preserve the 15 existing behavior/layout contracts and add checks for spinner animation, ANSI color fallback, read-only
filesystem availability, rejection of terminal controls, UTF-8 border alignment and a stable narrow return viewport.
Test-only filesystem and malformed-registry data is created under `prototypes/profile-selector/test-fixtures-*` and
removed by the test harness. The tests also verify terminal restoration on Esc, INT, TERM, HUP and a simulated render
failure. A non-TTY launch returns code 2 with `Profile demo requires an interactive terminal.` on stderr.

`shellcheck` was unavailable in the inspected environment and was not installed. Run it only if already present:

```bash
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck prototypes/profile-selector/demo.sh
fi
```

## Terminal limits and PRD boundary

The content block is capped at 64 cells and centered horizontally near the top. ANSI provides hierarchy through spacing,
color and bold text only; it cannot promise different font sizes or identical color rendering across emulators.
Truecolor is selected when `COLORTERM` is `truecolor` or `24bit`; otherwise the demo uses a legible 256-color
approximation.

Text measurement assumes fixture strings occupy one terminal cell per Bash character. Wide CJK characters and combining
sequences can misalign rows. Descriptions stay on one line and end with `…` when shortened. The full layout requires at
least 26 columns and 12 rows; tighter sizes show a resize notice. If a wrapped error cannot fit, enlarge the terminal to
read its full detail.

This prototype validates only Profiles. Components, installation, real selection state and production availability
policy are out of scope. The previous Profiles requirements are preserved in the
[consolidated installer document](../../docs/prd/tui/idea-instalador-perfiles.md), sections 3 and 7 of its historical
TUI reference; the new visual direction remains under discussion.
