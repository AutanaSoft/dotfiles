#!/usr/bin/env bash
# tests/setup-deps.bash — minimal repo-native tests for the root `./setup`
# thin dispatcher.
#
# Usage:
#     bash tests/setup-deps.bash
#     # or
#     ./tests/setup-deps.bash
#
# These tests verify the dispatch behavior of the root `./setup`
# dispatcher against the new contract (root is a thin dispatcher: parse,
# export 5 DOTFILES_* vars, trap, invoke exactly one env/helper script).
# They do NOT install packages, modify the live home, or touch the repo
# on disk. Each test runs in a fresh temp HOME with stub commands on
# PATH, so the only commands ever invoked are bash builtins, POSIX
# utilities (mkdir, ln, readlink, find, etc.), and the stubs declared
# in `make_stubs` below.
#
# Output is TAP-ish: one `ok N - <name>` or `not ok N - <name>` line per
# test, followed by a summary. Exit code is 0 on full pass.
#
# Requires only Bash. No external test framework (Bats, shellcheck,
# etc.) is needed at test time.
#
# ---------------------------------------------------------------------------
# PR-2 + PR-3 (stacked-to-main) test plan
# ---------------------------------------------------------------------------
# The full spec describes 7 tests (T1–T7). PR-2 landed T1, T2, T3, T4,
# T5, and T6. PR-3 lands T7 (setup-deps auto-detect with WU-4).
#
#   PR-1               T1  --omarchy invokes setup-omarchy once
#                     T2  --omarchy --fonts/--deps are absorbed
#                     T3  --fedora (any combo) short-circuits, exit 0
#                     T4  --fonts runs only setup-fonts; --deps only setup-deps
#                     T6  DOTFILES_* (5 vars) cleanup under env -i + trap grep
#   PR-2               T5  env-script pre-flight blocks on missing
#                            $DOTFILES_FONTS_DIR; honors override (defense
#                            in depth for direct invocation).
#   PR-3 (this file)   T7  scripts/setup-deps auto-detects
#                            (yay→omarchy, dnf→fedora, none→fail)
#                            + --omarchy/--fedora override skips detection
#
# `make_sandbox_no_fonts` (defined below) is the fixture for T5's
# missing-fonts sub-case.
# `make_pm_stubs` (defined below) is the fixture for T7's selective
# package-manager PATHs.

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve repo root from this script's path (CWD-independent). All test
# invocations target `<repo>/setup` via the absolute path we capture here.
# ---------------------------------------------------------------------------
TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$TEST_DIR/.." && pwd)"
SETUP_BIN="$REPO_ROOT/setup"

if [[ ! -x "$SETUP_BIN" ]]; then
    echo "FATAL: setup script not found or not executable: $SETUP_BIN" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Test runner state
# ---------------------------------------------------------------------------
TESTS_RUN=0
TESTS_FAILED=0
# PR-3 covers T1..T7 — full contract. T7 lands with WU-4 (setup-deps
# auto-detect). Prior PRs (PR-1, PR-2) covered T1..T6.
# T8 lands with WU-6 (setup-deps single-pass batch install). The
# existing T7 sub-cases A and B still pass because the new code
# emits the same yay -S --needed / sudo dnf install -y substrings
# (one line, full command); T8 isolates the new "exactly one
# install call per env" contract with a clean name.
TEST_PLAN=8

# Single workspace for the whole run; each test creates its own
# subdir. The EXIT trap removes the whole tree, so tests do not have
# to clean up after themselves on the failure path.
TEST_WORKSPACE="$(mktemp -d -t dotfiles-setup-test.XXXXXX)"
trap 'rm -rf -- "$TEST_WORKSPACE"' EXIT

# ---------------------------------------------------------------------------
# Stubs
# ---------------------------------------------------------------------------
# Build a directory of stub commands. Every stub logs "<name> <args>"
# to the file at $STUB_LOG (passed via env to the setup child) and
# exits with a fixed status.
#
# Default exit statuses are chosen so the dry-run path looks natural:
#   - pacman / rpm: exit 1  -> the dep looks "missing", so setup-deps
#                              previews the would-be install command
#                              (this is what the tests assert on).
#   - everything else: exit 0 -> presence checks pass, no command is
#                                  actually invoked in dry-run mode.
make_stubs() {
    local stubs_dir="$1"
    mkdir -p "$stubs_dir"

    # 1-exit stubs: pacman, rpm.
    for cmd in pacman rpm; do
        cat >"$stubs_dir/$cmd" <<'EOF'
#!/usr/bin/env bash
printf '%s %s\n' "$(basename -- "$0")" "$*" >> "${STUB_LOG:-/dev/null}"
exit 1
EOF
    done

    # 0-exit stubs: commands the executors require_command-check or
    # might invoke in non-dry-run mode.
    for cmd in omarchy hyprctl yay dnf curl unzip fc-cache zellij; do
        cat >"$stubs_dir/$cmd" <<'EOF'
#!/usr/bin/env bash
printf '%s %s\n' "$(basename -- "$0")" "$*" >> "${STUB_LOG:-/dev/null}"
exit 0
EOF
    done

    chmod +x "$stubs_dir"/*
}

# ---------------------------------------------------------------------------
# Sandbox
# ---------------------------------------------------------------------------
# Create a fresh subdir under $TEST_WORKSPACE with:
#   <sandbox>/home                       — temp HOME
#   <sandbox>/home/.local/share/fonts/autanasoft/ — Nerd Fonts dir with
#                                                one stub file, so the
#                                                setup-omarchy pre-flight
#                                                passes.
#   <sandbox>/stubs                      — command stubs (chmod +x)
#   <sandbox>/stub.log                   — sentinel log the stubs append to
# Echoes the absolute path to stdout.
make_sandbox() {
    local dir
    dir="$(mktemp -d "$TEST_WORKSPACE/sandbox.XXXXXX")"
    mkdir -p \
        "$dir/home/.config" \
        "$dir/home/.ssh" \
        "$dir/home/.local/share/fonts/autanasoft"
    # A single stub font file so the pre-flight "dir is non-empty" check
    # passes. The file content does not need to be a real font.
    : >"$dir/home/.local/share/fonts/autanasoft/SymbolsNerdFont-Regular.ttf"
    : >"$dir/stub.log"
    make_stubs "$dir/stubs"
    printf '%s\n' "$dir"
}

# Variant of make_sandbox that does NOT create the Nerd Fonts dir.
# Reserved for the deferred T5 (env-script pre-flight failure case):
# setup-omarchy invoked without fonts installed must fail fast at the
# pre-flight. Land with PR-2.
make_sandbox_no_fonts() {
    local dir
    dir="$(mktemp -d "$TEST_WORKSPACE/sandbox.XXXXXX")"
    mkdir -p "$dir/home/.config" "$dir/home/.ssh" "$dir/home/.local/share"
    : >"$dir/stub.log"
    make_stubs "$dir/stubs"
    printf '%s\n' "$dir"
}

# ---------------------------------------------------------------------------
# Selective PM stubs (T7 fixture)
# ---------------------------------------------------------------------------
# Create a stubs directory with ONLY the specified commands. Used by T7
# to isolate which package managers are on PATH for auto-detect tests.
# Pacman and rpm get a "package missing" stub (exit 1); other commands
# get a "present" stub (exit 0). Same shape as make_stubs, but with a
# caller-controlled list.
#
# Args:
#   $1 = stubs dir (created if missing)
#   $2.. = list of stub names to create
make_pm_stubs() {
    local dir="$1"
    shift
    mkdir -p "$dir"

    local cmd
    for cmd in "$@"; do
        if [[ "$cmd" == "pacman" || "$cmd" == "rpm" ]]; then
            # 1-exit: simulate "package missing" so install_package runs
            # in dry-run mode and previews the would-be install command.
            cat >"$dir/$cmd" <<'EOF'
#!/usr/bin/env bash
printf '%s %s\n' "$(basename -- "$0")" "$*" >> "${STUB_LOG:-/dev/null}"
exit 1
EOF
        else
            # 0-exit: presence stub. Used for yay/dnf (probes) and any
            # other command the executor might call in non-dry-run.
            cat >"$dir/$cmd" <<'EOF'
#!/usr/bin/env bash
printf '%s %s\n' "$(basename -- "$0")" "$*" >> "${STUB_LOG:-/dev/null}"
exit 0
EOF
        fi
    done

    chmod +x "$dir"/* 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Minimal utilities dir (T7 fixture)
# ---------------------------------------------------------------------------
# Build a directory containing symlinks to the few external utilities
# setup-deps needs (dirname, cat). Used by T7 to strip the host's
# /usr/bin from PATH, so the test is not contaminated by host PMs
# (the CI/dev host is Omarchy: yay and pacman live on /usr/bin and
# would otherwise be picked up by the probe in sub-cases B, C, and D).
#
# Args:
#   $1 = parent dir (under $TEST_WORKSPACE) where the utils dir is created
# Echoes the absolute path of the new utils dir on stdout.
make_minimal_utils_dir() {
    local parent="$1"
    local dir
    dir="$(mktemp -d "$parent/utils.XXXXXX")"
    local util src
    # `bash` is needed so the script's shebang (#!/usr/bin/env bash) can
    # locate bash on the minimal PATH that env -i sets. `basename` is
    # used inside the PM stubs and root dispatcher logs. `dirname` and
    # `cat` are used by setup-deps for path resolution and the
    # "Could not detect" error block. `date` is used by root to build
    # DOTFILES_BACKUP_DIR.
    for util in bash basename dirname cat date; do
        src="$(command -v "$util" 2>/dev/null || true)"
        if [[ -n "$src" && -x "$src" ]]; then
            ln -s "$src" "$dir/$util"
        fi
    done
    printf '%s\n' "$dir"
}

# ---------------------------------------------------------------------------
# Run the setup dispatcher with an isolated environment.
# Args: $1 = sandbox dir, remaining = args forwarded to ./setup
# ---------------------------------------------------------------------------
run_setup() {
    local sandbox_dir="$1"
    shift
    HOME="$sandbox_dir/home" \
    PATH="$sandbox_dir/stubs:$PATH" \
    STUB_LOG="$sandbox_dir/stub.log" \
    LANG="${LANG:-C.UTF-8}" \
    LC_ALL="${LC_ALL:-C.UTF-8}" \
    DOTFILES_DRY_RUN="${DOTFILES_DRY_RUN_UNSET_FORCE:-}" \
    "$SETUP_BIN" "$@"
}

# ---------------------------------------------------------------------------
# Assertion helpers
# ---------------------------------------------------------------------------
# Each test function returns 0 on pass and non-zero on fail. On fail,
# a diagnostic message is written to stdout (the test runner captures
# and prints it under the `not ok` line).

# Assert that $1 (haystack) contains the regex $2.
assert_grep() {
    local haystack="$1"
    local pattern="$2"
    local label="${3:-grep}"
    if ! grep -qE -- "$pattern" <<<"$haystack"; then
        printf 'assert_grep(%s) failed; expected /%s/\n--- captured output ---\n%s\n--- end ---\n' \
            "$label" "$pattern" "$haystack" >&2
        return 1
    fi
}

# Assert that $1 (haystack) does NOT contain the regex $2.
assert_not_grep() {
    local haystack="$1"
    local pattern="$2"
    local label="${3:-not-grep}"
    if grep -qE -- "$pattern" <<<"$haystack"; then
        printf 'assert_not_grep(%s) failed; did NOT want /%s/\n%s\n' \
            "$label" "$pattern" "$haystack" >&2
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Test 1
# ---------------------------------------------------------------------------
# `./setup --dry-run --omarchy` invokes `scripts/setup-omarchy` exactly
# once and the dispatcher targets setup-omarchy (not setup-deps or
# setup-fonts). The env script now owns the full flow, so its
# subprocess calls (setup-deps, setup-fonts) appear in the output as a
# consequence of the env script's flow — that is correct PR-2 behavior.
test_root_omarchy_invokes_setup_omarchy_once() {
    local sandbox output rc
    sandbox="$(make_sandbox)"

    set +e
    output="$(run_setup "$sandbox" --dry-run --omarchy 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'expected exit 0, got %d\n%s\n' "$rc" "$output" >&2
        return 1
    fi

    # Root dispatched to setup-omarchy exactly once. The dispatcher's
    # breadcrumb is the externally observable signal that root chose
    # the omarchy target, not setup-deps or setup-fonts.
    assert_grep "$output" '\[setup\] Dispatching to: setup-omarchy' \
        'root dispatched to setup-omarchy'
    # setup-omarchy ran and finished its flow.
    assert_grep "$output" '\[setup-omarchy\]' 'setup-omarchy tag present'
    assert_grep "$output" '\[setup-omarchy\] Setup complete' \
        'setup-omarchy finished its main()'

    # Root did NOT dispatch to setup-fonts or setup-deps. The dispatcher
    # emits a single "[setup] Dispatching to: ..." line per run, so the
    # presence of any other target in that breadcrumb is a regression.
    assert_not_grep "$output" '\[setup\] Dispatching to: setup-fonts' \
        'root did not dispatch to setup-fonts'
    assert_not_grep "$output" '\[setup\] Dispatching to: setup-deps' \
        'root did not dispatch to setup-deps'

    return 0
}

# ---------------------------------------------------------------------------
# Test 2
# ---------------------------------------------------------------------------
# `./setup --omarchy --fonts` and `./setup --omarchy --deps` are
# absorbed by the dispatcher: root dispatches to `scripts/setup-omarchy`
# exactly once, and does NOT also dispatch to `setup-fonts` or
# `setup-deps`. The env script owns the full flow and calls the
# sub-scripts internally as part of its own main().
test_omarchy_with_fonts_or_deps_absorbed() {
    local sandbox output rc

    # --- Sub-case A: --omarchy --fonts.
    sandbox="$(make_sandbox)"

    set +e
    output="$(run_setup "$sandbox" --dry-run --omarchy --fonts 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case A: expected exit 0, got %d\n%s\n' "$rc" "$output" >&2
        return 1
    fi

    assert_grep "$output" '\[setup\] Dispatching to: setup-omarchy' \
        'sub-case A: root dispatched to setup-omarchy'
    assert_grep "$output" '\[setup-omarchy\]' \
        'sub-case A: setup-omarchy ran'
    assert_not_grep "$output" '\[setup\] Dispatching to: setup-fonts' \
        'sub-case A: root did not dispatch to setup-fonts'
    assert_not_grep "$output" '\[setup\] Dispatching to: setup-deps' \
        'sub-case A: root did not dispatch to setup-deps'

    # --- Sub-case B: --omarchy --deps.
    sandbox="$(make_sandbox)"

    set +e
    output="$(run_setup "$sandbox" --dry-run --omarchy --deps 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case B: expected exit 0, got %d\n%s\n' "$rc" "$output" >&2
        return 1
    fi

    assert_grep "$output" '\[setup\] Dispatching to: setup-omarchy' \
        'sub-case B: root dispatched to setup-omarchy'
    assert_grep "$output" '\[setup-omarchy\]' \
        'sub-case B: setup-omarchy ran'
    assert_not_grep "$output" '\[setup\] Dispatching to: setup-deps' \
        'sub-case B: root did not dispatch to setup-deps'
    assert_not_grep "$output" '\[setup\] Dispatching to: setup-fonts' \
        'sub-case B: root did not dispatch to setup-fonts'

    return 0
}

# ---------------------------------------------------------------------------
# Test 3
# ---------------------------------------------------------------------------
# `./setup --fedora` (alone or combined with `--fonts`, `--deps`,
# `--dry-run`) short-circuits to a "not implemented" message, exits 0,
# and does NOT invoke `setup-deps`, `setup-fonts`, or `setup-omarchy`.
# The new contract: root never reaches a sub-script call for `--fedora`.
test_fedora_short_circuit_exits_zero() {
    local sandbox output rc stub_log

    # --- Sub-case A: --fedora alone.
    sandbox="$(make_sandbox)"
    stub_log="$sandbox/stub.log"

    set +e
    output="$(run_setup "$sandbox" --fedora 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case A: expected exit 0, got %d\n%s\n' "$rc" "$output" >&2
        return 1
    fi

    assert_grep "$output" 'Fedora env executor is not implemented' \
        'sub-case A: skip warning present'
    assert_not_grep "$output" '\[setup-deps\]' 'sub-case A: no setup-deps'
    assert_not_grep "$output" '\[setup-fonts\]' 'sub-case A: no setup-fonts'
    assert_not_grep "$output" '\[setup-omarchy\]' 'sub-case A: no setup-omarchy'
    assert_not_grep "$output" '\[setup-fedora\]' 'sub-case A: no setup-fedora'
    assert_not_grep "$(cat -- "$stub_log")" '^(pacman|yay|dnf|rpm) ' \
        'sub-case A: no package-manager stubs invoked'

    # --- Sub-case B: --fedora --fonts --deps --dry-run (any combo).
    sandbox="$(make_sandbox)"
    stub_log="$sandbox/stub.log"

    set +e
    output="$(run_setup "$sandbox" --fedora --fonts --deps --dry-run 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case B: expected exit 0, got %d\n%s\n' "$rc" "$output" >&2
        return 1
    fi

    assert_grep "$output" 'Fedora env executor is not implemented' \
        'sub-case B: skip warning present'
    assert_not_grep "$output" '\[setup-deps\]' 'sub-case B: no setup-deps'
    assert_not_grep "$output" '\[setup-fonts\]' 'sub-case B: no setup-fonts'
    assert_not_grep "$output" '\[setup-omarchy\]' 'sub-case B: no setup-omarchy'
    assert_not_grep "$(cat -- "$stub_log")" '^(pacman|yay|dnf|rpm|curl|unzip|fc-cache) ' \
        'sub-case B: no env/font tool stubs invoked'

    return 0
}

# ---------------------------------------------------------------------------
# Test 4
# ---------------------------------------------------------------------------
# `./setup --fonts` (alone or with `--dry-run`) runs ONLY
# `scripts/setup-fonts`. `./setup --deps` (alone or with `--dry-run`)
# runs ONLY `scripts/setup-deps`. Root does not call the env executor
# for these convenience paths.
test_fonts_or_deps_only_direct_dispatch() {
    local sandbox output rc stub_log

    # --- Sub-case A: --fonts only.
    sandbox="$(make_sandbox)"
    stub_log="$sandbox/stub.log"

    set +e
    output="$(run_setup "$sandbox" --dry-run --fonts 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case A: expected exit 0, got %d\n%s\n' "$rc" "$output" >&2
        return 1
    fi

    assert_grep "$output" '\[setup-fonts\]' 'sub-case A: setup-fonts ran'
    assert_not_grep "$output" '\[setup-deps\]' \
        'sub-case A: setup-deps did not run'
    assert_not_grep "$output" '\[setup-omarchy\]' \
        'sub-case A: setup-omarchy did not run'
    assert_not_grep "$output" '\[setup-fedora\]' \
        'sub-case A: setup-fedora did not run'
    # setup-fonts in dry-run does not call curl/unzip/fc-cache.
    if [[ -s "$stub_log" ]]; then
        if grep -qE '^(curl|unzip|fc-cache) ' "$stub_log"; then
            printf 'sub-case A: fonts dry-run should not invoke curl/unzip/fc-cache; got:\n%s\n' \
                "$(cat -- "$stub_log")" >&2
            return 1
        fi
    fi

    # --- Sub-case B: --deps only.
    #
    # The dispatcher's contract for --deps is: invoke scripts/setup-deps
    # exactly once, do not call setup-fonts or setup-omarchy. With PR-3
    # (WU-4) setup-deps auto-detects the host: when no env flag is
    # passed, it probes package managers and picks omarchy or fedora.
    # In make_sandbox all four PMs (pacman, rpm, yay, dnf) are stubbed,
    # so the probe picks yay first → omarchy. The T4 contract is
    # purely about dispatch; the auto-detect behavior is T7's concern.
    sandbox="$(make_sandbox)"
    stub_log="$sandbox/stub.log"

    set +e
    output="$(run_setup "$sandbox" --dry-run --deps 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case B: expected exit 0, got %d\n%s\n' "$rc" "$output" >&2
        return 1
    fi

    # The dispatcher's breadcrumb is the verifiable signal that
    # scripts/setup-deps was the target.
    assert_grep "$output" '\[setup\] Dispatching to: setup-deps' \
        'sub-case B: dispatcher invoked setup-deps'
    # setup-deps's own log tag is now emitted because auto-detect
    # replaces the previous "choose an environment" error path.
    assert_grep "$output" '\[setup-deps\]' \
        'sub-case B: setup-deps ran (auto-detect succeeded)'
    assert_not_grep "$output" '\[setup-fonts\]' \
        'sub-case B: setup-fonts did not run'
    assert_not_grep "$output" '\[setup-omarchy\]' \
        'sub-case B: setup-omarchy did not run'
    assert_not_grep "$output" '\[setup-fedora\]' \
        'sub-case B: setup-fedora did not run'

    # --- Sub-case C: --fonts and --deps together without an env flag.
    # Root is a thin dispatcher and must invoke exactly one target, so
    # this combination must fail validation rather than hit an internal
    # dispatch-table error.
    sandbox="$(make_sandbox)"

    set +e
    output="$(run_setup "$sandbox" --dry-run --fonts --deps 2>&1)"
    rc=$?
    set -e

    if [[ $rc -eq 0 ]]; then
        printf 'sub-case C: expected non-zero exit, got 0\n%s\n' "$output" >&2
        return 1
    fi
    assert_grep "$output" 'choose only one standalone helper: --fonts or --deps' \
        'sub-case C: validation explains unsupported standalone combo'
    assert_not_grep "$output" 'internal dispatch table' \
        'sub-case C: no internal dispatch-table error leaks to user'

    # --- Sub-case D: --deps propagates setup-deps failure.
    # Root must not swallow setup-deps's failure when auto-detect cannot
    # find a supported package manager. Use a stripped PATH so host PMs
    # cannot contaminate the assertion.
    sandbox="$(make_sandbox)"
    local utils_dir
    utils_dir="$(make_minimal_utils_dir "$sandbox")"

    set +e
    output="$(env -i \
        HOME="$sandbox/home" \
        PATH="$utils_dir" \
        STUB_LOG="$sandbox/stub.log" \
        LANG="${LANG:-C.UTF-8}" \
        LC_ALL="${LC_ALL:-C.UTF-8}" \
        "$SETUP_BIN" --dry-run --deps 2>&1)"
    rc=$?
    set -e

    if [[ $rc -eq 0 ]]; then
        printf 'sub-case D: expected non-zero exit from propagated setup-deps failure, got 0\n%s\n' \
            "$output" >&2
        return 1
    fi
    assert_grep "$output" '\[setup\] Dispatching to: setup-deps' \
        'sub-case D: root dispatched to setup-deps'
    assert_grep "$output" 'Could not detect a supported package manager' \
        'sub-case D: setup-deps failure propagated through root'

    return 0
}

# ---------------------------------------------------------------------------
# Test 5
# ---------------------------------------------------------------------------
# The env script (scripts/setup-omarchy) is responsible for the full env
# flow. Its pre-flight verifies the fonts dir is present and non-empty.
# This is defense-in-depth for direct invocation (running setup-omarchy
# without going through root and without a fonts install).
#
# Two sub-cases triangulate the contract:
#   A) Missing fonts dir at the default location in dry-run: pre-flight
#      warns but continues so a clean machine can preview the full flow.
#   B) DOTFILES_FONTS_DIR set to a non-empty custom path: pre-flight
#      honors the override (proves the env var is read, not a hardcoded
#      path) and setup-fonts picks up the same override (proves WU-5).
test_env_script_preflight_handles_fonts_dir() {
    local sandbox output rc stub_log setup_omarchy
    setup_omarchy="$REPO_ROOT/scripts/setup-omarchy"

    # --- Sub-case A: missing fonts at default location in dry-run.
    sandbox="$(make_sandbox_no_fonts)"
    stub_log="$sandbox/stub.log"

    set +e
    output="$(env -i \
        HOME="$sandbox/home" \
        PATH="$sandbox/stubs:/usr/bin:/bin" \
        STUB_LOG="$stub_log" \
        LANG="${LANG:-C.UTF-8}" \
        LC_ALL="${LC_ALL:-C.UTF-8}" \
        "$setup_omarchy" --dry-run 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case A: expected exit 0, got %d\n%s\n' \
            "$rc" "$output" >&2
        return 1
    fi

    assert_grep "$output" 'Nerd Fonts not installed' \
        'sub-case A: dry-run warning message present'
    assert_grep "$output" '\[setup-omarchy\] Setup complete' \
        'sub-case A: dry-run continues through Setup complete'

    # --- Sub-case B: DOTFILES_FONTS_DIR override points to a non-empty dir.
    # This is RED against pre-WU-3 code: the env script used a hardcoded
    # path, so setting DOTFILES_FONTS_DIR was ignored and the pre-flight
    # failed because the default location was empty.
    sandbox="$(make_sandbox_no_fonts)"
    stub_log="$sandbox/stub.log"

    local custom_fonts="$sandbox/custom-fonts"
    mkdir -p "$custom_fonts"
    : >"$custom_fonts/SymbolsNerdFont-Regular.ttf"

    set +e
    output="$(env -i \
        HOME="$sandbox/home" \
        PATH="$sandbox/stubs:/usr/bin:/bin" \
        STUB_LOG="$stub_log" \
        DOTFILES_FONTS_DIR="$custom_fonts" \
        LANG="${LANG:-C.UTF-8}" \
        LC_ALL="${LC_ALL:-C.UTF-8}" \
        "$setup_omarchy" --dry-run 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case B: expected exit 0 (env var override should pass), got %d\n%s\n' \
            "$rc" "$output" >&2
        return 1
    fi

    # The env script and setup-fonts must both consult the override.
    # setup-omarchy logs the env var in its pre-flight and setup-fonts
    # logs "Install base: $FONT_BASE" with the override. Either side
    # is sufficient to prove the env var was read.
    if ! grep -qF "$custom_fonts" <<<"$output"; then
        printf 'sub-case B: pre-flight did not log custom fonts dir %s\noutput:\n%s\n' \
            "$custom_fonts" "$output" >&2
        return 1
    fi

    return 0
}

# ---------------------------------------------------------------------------
# Test 6
# ---------------------------------------------------------------------------
# After a successful run, no DOTFILES_* env var persists in the
# calling shell environment. The dispatcher must `unset` them before
# returning. The dispatcher now exports FIVE variables: DOTFILES_ROOT,
# DOTFILES_ENV, DOTFILES_DRY_RUN, DOTFILES_BACKUP_DIR, DOTFILES_FONTS_DIR.
#
# Two sub-cases triangulate the cleanup:
#   A) env -i run pattern — runs the dispatcher in a clean env and
#      asserts no DOTFILES_* leaked into the calling shell. The
#      child-process env changes never reach the parent, so this
#      sub-case primarily documents the contract.
#   B) trap-on-EXIT is configured in the source. The behavior of
#      unsetting in the child is not externally observable, so we
#      verify the mechanism the design specifies: a `trap 'unset
#      DOTFILES_*' EXIT` line must be present in `setup`, and it must
#      list all five variables (including DOTFILES_FONTS_DIR). Without
#      this, the spec's "unset from calling shell environment"
#      requirement has no enforcement.
test_dotfiles_vars_unset_after_run() {
    local sandbox output rc
    sandbox="$(make_sandbox)"

    # --- Sub-case A: env -i run pattern.
    set +e
    output="$(env -i \
        HOME="$sandbox/home" \
        PATH="$sandbox/stubs:/usr/bin:/bin" \
        STUB_LOG="$sandbox/stub.log" \
        bash -c '
            "$1" --omarchy
            leaked="$(printenv | grep "^DOTFILES_" || true)"
            if [[ -n "$leaked" ]]; then
                printf "DOTFILES_ vars leaked into calling env:\n%s\n" \
                    "$leaked" >&2
                exit 1
            fi
        ' _ "$SETUP_BIN" 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case A: expected clean env after run, got rc=%d\noutput:\n%s\n' \
            "$rc" "$output" >&2
        return 1
    fi

    # --- Sub-case B: the trap is configured in the source for all
    # five variables (the new contract adds DOTFILES_FONTS_DIR). Pull
    # the trap line out, then assert each of the five names appears in
    # it. A plain alternation regex is too weak (it matches the line
    # if ANY of the alternatives is present); we need every name.
    local trap_line
    trap_line="$(grep -E "trap '?unset DOTFILES_" "$REPO_ROOT/setup" | head -1 || true)"
    if [[ -z "$trap_line" ]]; then
        printf 'sub-case B: setup has no DOTFILES_* unset trap line\n' >&2
        return 1
    fi
    local var
    for var in ROOT ENV DRY_RUN BACKUP_DIR FONTS_DIR; do
        if ! grep -qE "DOTFILES_${var}\\b|${var}'|${var} *\\$|${var} *$" <<<"$trap_line"; then
            printf 'sub-case B: trap line is missing DOTFILES_%s\nline: %s\n' \
                "$var" "$trap_line" >&2
            return 1
        fi
    done
}

# ---------------------------------------------------------------------------
# Test 7
# ---------------------------------------------------------------------------
# scripts/setup-deps auto-detects the host environment by probing
# package managers in the documented order:
#
#   yay     → omarchy  (AUR helper is the documented Omarchy entry)
#   pacman  → omarchy  (with yay-not-found warning; Arch without AUR)
#   dnf     → fedora   (canonical Fedora package manager)
#   rpm     → fedora   (with dnf-not-found warning; Fedora-derived)
#   none    → fail     ("Could not detect a supported package manager")
#
# --omarchy and --fedora remain valid as explicit overrides that skip
# the probe entirely. The override is useful for non-standard hosts,
# ambiguous chroots, and deterministic test fixtures.
#
# Five sub-cases triangulate the contract:
#   A) yay on PATH (with pacman for verification) → omarchy package
#      list, pacman -Q is used, no rpm -q, no dnf list, "yay -S --needed"
#      dry-run preview is emitted.
#   B) dnf on PATH (with rpm for verification) → fedora package list,
#      rpm -q is used, no pacman -Q, no yay -S, "sudo dnf install -y"
#      dry-run preview is emitted.
#   C) no package manager on PATH → non-zero exit with the
#      "Could not detect a supported package manager" message.
#   D) --omarchy override with dnf on PATH → omarchy is forced, the
#      probe is skipped (no "Detected env:" log), pacman -Q is used,
#      no rpm -q or dnf list.
#   E) pacman on PATH (no yay) → omarchy is selected, and a warning
#      that yay is missing is emitted. Spec scenario: "pacman without
#      yay resolves to omarchy with warning".
test_setup_deps_auto_detects_env() {
    local setup_deps
    setup_deps="$REPO_ROOT/scripts/setup-deps"
    if [[ ! -x "$setup_deps" ]]; then
        printf 'FATAL: %s not found or not executable\n' "$setup_deps" >&2
        return 1
    fi

    # Build a minimal utils dir for T7. The host (Omarchy) has yay and
    # pacman on /usr/bin; to keep the probe deterministic in sub-cases
    # B, C, and D, PATH must NOT include /usr/bin. The script needs
    # only `dirname` and `cat` as external commands in dry-run mode.
    local utils_dir
    utils_dir="$(make_minimal_utils_dir "$TEST_WORKSPACE")"

    local sandbox stub_log output rc

    # --- Sub-case A: yay on PATH (with pacman for verification).
    sandbox="$(mktemp -d "$TEST_WORKSPACE/sandbox.XXXXXX")"
    mkdir -p "$sandbox/home/.config" "$sandbox/stubs"
    : >"$sandbox/stub.log"
    make_pm_stubs "$sandbox/stubs" yay pacman
    stub_log="$sandbox/stub.log"

    set +e
    output="$(env -i \
        HOME="$sandbox/home" \
        PATH="$sandbox/stubs:$utils_dir" \
        STUB_LOG="$stub_log" \
        LANG="${LANG:-C.UTF-8}" \
        LC_ALL="${LC_ALL:-C.UTF-8}" \
        "$setup_deps" --dry-run 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case A: expected exit 0, got %d\noutput:\n%s\n' \
            "$rc" "$output" >&2
        return 1
    fi
    # Auto-detect picked omarchy.
    if ! grep -qE 'Env:[[:space:]]+omarchy' <<<"$output"; then
        printf 'sub-case A: expected "Env: omarchy" in output, got:\n%s\n' \
            "$output" >&2
        return 1
    fi
    # Omarchy verification: pacman -Q was called. Fedora verification
    # was NOT (no rpm -q, no dnf list).
    if ! grep -qE '^pacman -Q ' "$stub_log"; then
        printf 'sub-case A: stub log does not contain "pacman -Q" (Omarchy verification)\nlog:\n%s\n' \
            "$(cat -- "$stub_log")" >&2
        return 1
    fi
    if grep -qE '^(rpm -q|dnf list|dnf install|yay) ' "$stub_log"; then
        printf 'sub-case A: stub log contains a non-omarchy PM call; should not\nlog:\n%s\n' \
            "$(cat -- "$stub_log")" >&2
        return 1
    fi
    # Omarchy install preview uses yay -S --needed.
    if ! grep -qE 'yay -S --needed ' <<<"$output"; then
        printf 'sub-case A: expected "yay -S --needed" preview in dry-run output\noutput:\n%s\n' \
            "$output" >&2
        return 1
    fi

    # --- Sub-case B: dnf on PATH (with rpm for verification).
    sandbox="$(mktemp -d "$TEST_WORKSPACE/sandbox.XXXXXX")"
    mkdir -p "$sandbox/home/.config" "$sandbox/stubs"
    : >"$sandbox/stub.log"
    make_pm_stubs "$sandbox/stubs" dnf rpm
    stub_log="$sandbox/stub.log"

    set +e
    output="$(env -i \
        HOME="$sandbox/home" \
        PATH="$sandbox/stubs:$utils_dir" \
        STUB_LOG="$stub_log" \
        LANG="${LANG:-C.UTF-8}" \
        LC_ALL="${LC_ALL:-C.UTF-8}" \
        "$setup_deps" --dry-run 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case B: expected exit 0, got %d\noutput:\n%s\n' \
            "$rc" "$output" >&2
        return 1
    fi
    # Auto-detect picked fedora.
    if ! grep -qE 'Env:[[:space:]]+fedora' <<<"$output"; then
        printf 'sub-case B: expected "Env: fedora" in output, got:\n%s\n' \
            "$output" >&2
        return 1
    fi
    # Fedora verification: rpm -q was called. Omarchy verification
    # was NOT (no pacman -Q, no yay).
    if ! grep -qE '^rpm -q ' "$stub_log"; then
        printf 'sub-case B: stub log does not contain "rpm -q" (Fedora verification)\nlog:\n%s\n' \
            "$(cat -- "$stub_log")" >&2
        return 1
    fi
    if grep -qE '^(pacman|yay) ' "$stub_log"; then
        printf 'sub-case B: stub log contains an omarchy PM call; should not\nlog:\n%s\n' \
            "$(cat -- "$stub_log")" >&2
        return 1
    fi
    # Fedora install preview uses sudo dnf install -y.
    if ! grep -qE 'sudo dnf install -y ' <<<"$output"; then
        printf 'sub-case B: expected "sudo dnf install -y" preview in dry-run output\noutput:\n%s\n' \
            "$output" >&2
        return 1
    fi

    # --- Sub-case C: no package manager on PATH.
    # PATH has only the minimal utils dir (no PM stubs). Detection
    # must fail with a clear, non-zero exit.
    sandbox="$(mktemp -d "$TEST_WORKSPACE/sandbox.XXXXXX")"
    mkdir -p "$sandbox/home/.config"

    set +e
    output="$(env -i \
        HOME="$sandbox/home" \
        PATH="$utils_dir" \
        LANG="${LANG:-C.UTF-8}" \
        LC_ALL="${LC_ALL:-C.UTF-8}" \
        "$setup_deps" --dry-run 2>&1)"
    rc=$?
    set -e

    if [[ $rc -eq 0 ]]; then
        printf 'sub-case C: expected non-zero exit (no PM detectable), got 0\noutput:\n%s\n' \
            "$output" >&2
        return 1
    fi
    if ! grep -qE 'Could not detect a supported package manager' <<<"$output"; then
        printf 'sub-case C: expected "Could not detect" message, got:\n%s\n' \
            "$output" >&2
        return 1
    fi

    # --- Sub-case D: --omarchy override with dnf on PATH.
    # The probe would pick fedora (dnf on PATH, no yay). --omarchy
    # forces omarchy and skips detection entirely. To make the
    # verification command observable in the stub log, pacman is
    # also stubbed.
    sandbox="$(mktemp -d "$TEST_WORKSPACE/sandbox.XXXXXX")"
    mkdir -p "$sandbox/home/.config" "$sandbox/stubs"
    : >"$sandbox/stub.log"
    make_pm_stubs "$sandbox/stubs" dnf rpm pacman
    stub_log="$sandbox/stub.log"

    set +e
    output="$(env -i \
        HOME="$sandbox/home" \
        PATH="$sandbox/stubs:$utils_dir" \
        STUB_LOG="$stub_log" \
        LANG="${LANG:-C.UTF-8}" \
        LC_ALL="${LC_ALL:-C.UTF-8}" \
        "$setup_deps" --omarchy --dry-run 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case D: expected exit 0 (override), got %d\noutput:\n%s\n' \
            "$rc" "$output" >&2
        return 1
    fi
    # Override forced omarchy.
    if ! grep -qE 'Env:[[:space:]]+omarchy' <<<"$output"; then
        printf 'sub-case D: expected "Env: omarchy" in output (override), got:\n%s\n' \
            "$output" >&2
        return 1
    fi
    # Probe was skipped — no "Detected env:" log.
    if grep -qE 'Detected env:' <<<"$output"; then
        printf 'sub-case D: probe should have been skipped; got "Detected env:" in output\noutput:\n%s\n' \
            "$output" >&2
        return 1
    fi
    # Omarchy verification: pacman -Q. Fedora verification was NOT.
    if ! grep -qE '^pacman -Q ' "$stub_log"; then
        printf 'sub-case D: stub log does not contain "pacman -Q" (omarchy verification)\nlog:\n%s\n' \
            "$(cat -- "$stub_log")" >&2
        return 1
    fi
    if grep -qE '^(rpm -q|dnf list|dnf install) ' "$stub_log"; then
        printf 'sub-case D: stub log contains a Fedora PM call; should not\nlog:\n%s\n' \
            "$(cat -- "$stub_log")" >&2
        return 1
    fi

    # --- Sub-case E: pacman on PATH (no yay) → omarchy with warning.
    # Spec scenario "pacman without yay resolves to omarchy with
    # warning". The probe should fall through yay, hit pacman, emit
    # a WARN that yay is missing, and pick omarchy.
    sandbox="$(mktemp -d "$TEST_WORKSPACE/sandbox.XXXXXX")"
    mkdir -p "$sandbox/home/.config" "$sandbox/stubs"
    : >"$sandbox/stub.log"
    make_pm_stubs "$sandbox/stubs" pacman
    stub_log="$sandbox/stub.log"

    set +e
    output="$(env -i \
        HOME="$sandbox/home" \
        PATH="$sandbox/stubs:$utils_dir" \
        STUB_LOG="$stub_log" \
        LANG="${LANG:-C.UTF-8}" \
        LC_ALL="${LC_ALL:-C.UTF-8}" \
        "$setup_deps" --dry-run 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case E: expected exit 0, got %d\noutput:\n%s\n' \
            "$rc" "$output" >&2
        return 1
    fi
    # omarchy selected via pacman (not yay).
    if ! grep -qE 'Env:[[:space:]]+omarchy' <<<"$output"; then
        printf 'sub-case E: expected "Env: omarchy" in output, got:\n%s\n' \
            "$output" >&2
        return 1
    fi
    # Warning that yay is missing.
    if ! grep -qE 'yay is not on PATH' <<<"$output"; then
        printf 'sub-case E: expected WARN about missing yay, got:\n%s\n' \
            "$output" >&2
        return 1
    fi
    # pacman -Q verification was used.
    if ! grep -qE '^pacman -Q ' "$stub_log"; then
        printf 'sub-case E: stub log does not contain "pacman -Q" (omarchy verification)\nlog:\n%s\n' \
            "$(cat -- "$stub_log")" >&2
        return 1
    fi
    # No Fedora verification.
    if grep -qE '^(rpm -q|dnf list|dnf install) ' "$stub_log"; then
        printf 'sub-case E: stub log contains a Fedora PM call; should not\nlog:\n%s\n' \
            "$(cat -- "$stub_log")" >&2
        return 1
    fi

    return 0
}

# ---------------------------------------------------------------------------
# Test 8
# ---------------------------------------------------------------------------
# scripts/setup-deps performs a single-pass batch install per env:
# it collects every missing package, then invokes the env's package
# manager exactly once with all missing packages as positional args.
# Per-pkg [ok]/[miss] lines are preserved, a consolidated install
# log line is emitted before the call, and the all-present path
# skips the install command entirely.
#
# Five sub-cases triangulate the contract (no E; AUR flag set was
# removed in rev 2):
#   A) All packages present (Omarchy): one "all present" log line;
#      no install command appears in the stub log.
#   B) Single missing (Omarchy): pacman exits 1, yay exits 0.
#      Exactly ONE yay -S --needed line is emitted, per-pkg [miss]
#      lines are present, no sudo invocation.
#   C) >= 2 missing (Omarchy): same stub shape as B; the single yay
#      line's args contain every missing package as a positional
#      argument (substring set; no strict order).
#   D) >= 2 missing (Fedora): rpm exits 1, dnf exits 0. Exactly ONE
#      sudo dnf install -y line with all missing pkgs; no sudo -v
#      appears in the stub log (Fedora contract: one sudo per run).
#   F) Install failure (Omarchy): pacman exits 1, yay exits 7 in
#      real mode. The script aborts with exit 7, exactly ONE yay
#      invocation in the stub log, and neither "Summary:" nor
#      "Setup complete." appears in the captured output.
test_setup_deps_single_pass_batch_install() {
    local setup_deps
    setup_deps="$REPO_ROOT/scripts/setup-deps"
    if [[ ! -x "$setup_deps" ]]; then
        printf 'FATAL: %s not found or not executable\n' "$setup_deps" >&2
        return 1
    fi

    # Build a minimal utils dir for T8. The host (Omarchy) has yay
    # and pacman on /usr/bin; to keep the probe deterministic, PATH
    # must NOT include /usr/bin. The script needs only `dirname` and
    # `cat` as external commands in dry-run mode.
    local utils_dir
    utils_dir="$(make_minimal_utils_dir "$TEST_WORKSPACE")"

    local sandbox stub_log output rc

    # --- Sub-case A: all present (Omarchy).
    # pacman and rpm stubbed as exit 0. Auto-detect falls through
    # yay (not on PATH) to pacman, picks omarchy. Every pacman -Q
    # returns 0 -> all packages present -> no install command
    # invoked.
    sandbox="$(mktemp -d "$TEST_WORKSPACE/sandbox.XXXXXX")"
    mkdir -p "$sandbox/home/.config" "$sandbox/stubs"
    : >"$sandbox/stub.log"
    make_pm_stubs "$sandbox/stubs" pacman rpm
    # make_pm_stubs hardcodes pacman/rpm to exit 1 (package missing);
    # override them to exit 0 for the all-present scenario.
    for cmd in pacman rpm; do
        cat >"$sandbox/stubs/$cmd" <<'EOF'
#!/usr/bin/env bash
printf '%s %s\n' "$(basename -- "$0")" "$*" >> "${STUB_LOG:-/dev/null}"
exit 0
EOF
        chmod +x "$sandbox/stubs/$cmd"
    done
    stub_log="$sandbox/stub.log"

    set +e
    output="$(env -i \
        HOME="$sandbox/home" \
        PATH="$sandbox/stubs:$utils_dir" \
        STUB_LOG="$stub_log" \
        LANG="${LANG:-C.UTF-8}" \
        LC_ALL="${LC_ALL:-C.UTF-8}" \
        "$setup_deps" --dry-run 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case A: expected exit 0, got %d\noutput:\n%s\n' \
            "$rc" "$output" >&2
        return 1
    fi
    # The "all present" early-exit message must be present.
    if ! grep -qE '[Aa]ll [0-9]+ packages present' <<<"$output"; then
        printf 'sub-case A: expected "all present" log line, got:\n%s\n' \
            "$output" >&2
        return 1
    fi
    # No install command should have run; the stub log must not
    # contain yay or dnf (we did not even put them on PATH).
    if grep -qE '^(yay|dnf|sudo dnf|sudo -v) ' "$stub_log"; then
        printf 'sub-case A: stub log contains a PM install call; should not\nlog:\n%s\n' \
            "$(cat -- "$stub_log")" >&2
        return 1
    fi
    # No "Summary:" in this path (final summary is skipped on the
    # all-present early-exit).
    if grep -qE 'Summary:' <<<"$output"; then
        printf 'sub-case A: all-present path must not emit Summary; got:\n%s\n' \
            "$output" >&2
        return 1
    fi

    # --- Sub-case B: single missing (Omarchy).
    # pacman exits 1 (all packages look missing); yay exits 0 so
    # the install_batch real path is not exercised in dry-run. We
    # assert exactly one yay -S --needed line in the stub log.
    sandbox="$(mktemp -d "$TEST_WORKSPACE/sandbox.XXXXXX")"
    mkdir -p "$sandbox/home/.config" "$sandbox/stubs"
    : >"$sandbox/stub.log"
    make_pm_stubs "$sandbox/stubs" pacman yay
    stub_log="$sandbox/stub.log"

    set +e
    output="$(env -i \
        HOME="$sandbox/home" \
        PATH="$sandbox/stubs:$utils_dir" \
        STUB_LOG="$stub_log" \
        LANG="${LANG:-C.UTF-8}" \
        LC_ALL="${LC_ALL:-C.UTF-8}" \
        "$setup_deps" --dry-run 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case B: expected exit 0, got %d\noutput:\n%s\n' \
            "$rc" "$output" >&2
        return 1
    fi
    # Per-pkg [miss] line(s) must be emitted.
    if ! grep -qE '\[miss\]' <<<"$output"; then
        printf 'sub-case B: expected at least one per-pkg [miss] line, got:\n%s\n' \
            "$output" >&2
        return 1
    fi
    # In dry-run, the script logs the would-be command once and does
    # NOT actually invoke the PM. So the assertion looks at the script
    # output, not the stub log: exactly ONE "yay -S --needed" line
    # (the dry-run preview).
    local yay_count
    yay_count="$(grep -cE 'yay -S --needed ' <<<"$output" || true)"
    if [[ "$yay_count" -ne 1 ]]; then
        printf 'sub-case B: expected exactly 1 "yay -S --needed" line in output, got %d\noutput:\n%s\n' \
            "$yay_count" "$output" >&2
        return 1
    fi
    # In dry-run the PM is never invoked, so the stub log has no yay
    # or sudo calls. This is the dry-run safety contract.
    if grep -qE '^(yay|sudo|sudo dnf|sudo -v) ' "$stub_log"; then
        printf 'sub-case B: stub log contains a PM call; dry-run must not invoke the PM\nlog:\n%s\n' \
            "$(cat -- "$stub_log")" >&2
        return 1
    fi

    # --- Sub-case C: >= 2 missing (Omarchy).
    # Same stub shape as B. We additionally assert that the single
    # yay line's args contain every missing package as a positional
    # argument (substring set, no strict order).
    sandbox="$(mktemp -d "$TEST_WORKSPACE/sandbox.XXXXXX")"
    mkdir -p "$sandbox/home/.config" "$sandbox/stubs"
    : >"$sandbox/stub.log"
    make_pm_stubs "$sandbox/stubs" pacman yay
    stub_log="$sandbox/stub.log"

    set +e
    output="$(env -i \
        HOME="$sandbox/home" \
        PATH="$sandbox/stubs:$utils_dir" \
        STUB_LOG="$stub_log" \
        LANG="${LANG:-C.UTF-8}" \
        LC_ALL="${LC_ALL:-C.UTF-8}" \
        "$setup_deps" --dry-run 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case C: expected exit 0, got %d\noutput:\n%s\n' \
            "$rc" "$output" >&2
        return 1
    fi
    yay_count="$(grep -cE 'yay -S --needed ' <<<"$output" || true)"
    if [[ "$yay_count" -ne 1 ]]; then
        printf 'sub-case C: expected exactly 1 "yay -S --needed" line, got %d\noutput:\n%s\n' \
            "$yay_count" "$output" >&2
        return 1
    fi
    # Extract the single yay line and assert every Omarchy package
    # is a substring of its args (substring set, not strict order).
    # The Omarchy package list is hard-coded in scripts/setup-deps;
    # we assert each name appears as a substring of the yay line's
    # args. Substring match is order-agnostic and robust to quoting
    # differences in the dry-run preview line.
    local yay_line pkg
    yay_line="$(grep -E 'yay -S --needed ' <<<"$output" | head -1)"
    # Mirrors OMARCHY_PACKAGES in scripts/setup-deps (line ~61). Edit both in lockstep.
    local omarchy_pkgs=(
        lsof hunspell hunspell-en_us hunspell-es_any zellij trash-cli keyd piper libratbag
    )
    for pkg in "${omarchy_pkgs[@]}"; do
        if ! grep -qF -- "$pkg" <<<"$yay_line"; then
            printf 'sub-case C: yay line missing package %s\nline: %s\n' \
                "$pkg" "$yay_line" >&2
            return 1
        fi
    done

    # --- Sub-case D: >= 2 missing (Fedora).
    # rpm exits 1; dnf exits 0. The single sudo dnf install -y
    # line must list every Fedora package, and no sudo -v may
    # appear (the single dnf invocation is the only sudo touchpoint).
    sandbox="$(mktemp -d "$TEST_WORKSPACE/sandbox.XXXXXX")"
    mkdir -p "$sandbox/home/.config" "$sandbox/stubs"
    : >"$sandbox/stub.log"
    make_pm_stubs "$sandbox/stubs" rpm dnf
    stub_log="$sandbox/stub.log"

    set +e
    output="$(env -i \
        HOME="$sandbox/home" \
        PATH="$sandbox/stubs:$utils_dir" \
        STUB_LOG="$stub_log" \
        LANG="${LANG:-C.UTF-8}" \
        LC_ALL="${LC_ALL:-C.UTF-8}" \
        "$setup_deps" --fedora --dry-run 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case D: expected exit 0, got %d\noutput:\n%s\n' \
            "$rc" "$output" >&2
        return 1
    fi
    local dnf_count
    dnf_count="$(grep -cE 'sudo dnf install -y ' <<<"$output" || true)"
    if [[ "$dnf_count" -ne 1 ]]; then
        printf 'sub-case D: expected exactly 1 "sudo dnf install -y" line, got %d\noutput:\n%s\n' \
            "$dnf_count" "$output" >&2
        return 1
    fi
    # Fedora contract: no upfront sudo -v. The only sudo touchpoint
    # is the dnf invocation. In dry-run, the PM is never invoked,
    # so the stub log must have no sudo calls.
    if grep -qE '^(sudo|sudo -v) ' "$stub_log"; then
        printf 'sub-case D: stub log contains a sudo call; dry-run must not invoke the PM\nlog:\n%s\n' \
            "$(cat -- "$stub_log")" >&2
        return 1
    fi
    # Every Fedora package is in the single dnf line's args.
    local dnf_line pkg
    dnf_line="$(grep -E 'sudo dnf install -y ' <<<"$output" | head -1)"
    local fedora_pkgs=(
        lsof hunspell hunspell-en-US hunspell-es trash-cli
    )
    for pkg in "${fedora_pkgs[@]}"; do
        if ! grep -qF -- "$pkg" <<<"$dnf_line"; then
            printf 'sub-case D: dnf line missing package %s\nline: %s\n' \
                "$pkg" "$dnf_line" >&2
            return 1
        fi
    done

    # --- Sub-case F: install failure (Omarchy).
    # pacman exits 1 (all packages missing); yay exits 7 in REAL
    # mode (no --dry-run). set -e propagates the failure; the
    # script must exit 7, emit exactly ONE yay invocation, and
    # not emit the final Summary: line nor "Setup complete.".
    sandbox="$(mktemp -d "$TEST_WORKSPACE/sandbox.XXXXXX")"
    mkdir -p "$sandbox/home/.config" "$sandbox/stubs"
    : >"$sandbox/stub.log"
    make_pm_stubs "$sandbox/stubs" pacman yay
    stub_log="$sandbox/stub.log"

    # Override the yay stub to exit 7 (install failure). The
    # default make_pm_stubs makes it exit 0.
    cat >"$sandbox/stubs/yay" <<'EOF'
#!/usr/bin/env bash
printf '%s %s\n' "$(basename -- "$0")" "$*" >> "${STUB_LOG:-/dev/null}"
exit 7
EOF
    chmod +x "$sandbox/stubs/yay"

    set +e
    output="$(env -i \
        HOME="$sandbox/home" \
        PATH="$sandbox/stubs:$utils_dir" \
        STUB_LOG="$stub_log" \
        LANG="${LANG:-C.UTF-8}" \
        LC_ALL="${LC_ALL:-C.UTF-8}" \
        "$setup_deps" 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 7 ]]; then
        printf 'sub-case F: expected exit 7, got %d\noutput:\n%s\n' \
            "$rc" "$output" >&2
        return 1
    fi
    yay_count="$(grep -cE '^yay ' "$stub_log" || true)"
    if [[ "$yay_count" -ne 1 ]]; then
        printf 'sub-case F: expected exactly 1 yay invocation, got %d\nlog:\n%s\n' \
            "$yay_count" "$(cat -- "$stub_log")" >&2
        return 1
    fi
    # No Summary: line and no "Setup complete." (failure path skips
    # both).
    if grep -qE 'Summary:' <<<"$output"; then
        printf 'sub-case F: failure path must not emit Summary; got:\n%s\n' \
            "$output" >&2
        return 1
    fi
    if grep -qE 'Setup complete\.' <<<"$output"; then
        printf 'sub-case F: failure path must not emit "Setup complete."; got:\n%s\n' \
            "$output" >&2
        return 1
    fi

    return 0
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
echo "1..$TEST_PLAN"

run_test() {
    local name="$1"
    local fn="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    local output rc
    set +e
    output="$("$fn" 2>&1)"
    rc=$?
    set -e
    if [[ $rc -eq 0 ]]; then
        echo "ok $TESTS_RUN - $name"
    else
        echo "not ok $TESTS_RUN - $name"
        if [[ -n "$output" ]]; then
            echo "  ---"
            printf '%s\n' "$output" | sed 's/^/  /'
            echo "  ---"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
}

run_test "root --omarchy invokes setup-omarchy exactly once" \
    test_root_omarchy_invokes_setup_omarchy_once
run_test "--omarchy --fonts and --omarchy --deps are absorbed by root" \
    test_omarchy_with_fonts_or_deps_absorbed
run_test "--fedora (any combo) short-circuits to not-implemented and exits 0" \
    test_fedora_short_circuit_exits_zero
run_test "--fonts runs only setup-fonts; --deps runs only setup-deps" \
    test_fonts_or_deps_only_direct_dispatch
run_test "env-script pre-flight handles missing/overridden \$DOTFILES_FONTS_DIR" \
    test_env_script_preflight_handles_fonts_dir
run_test "DOTFILES_* (5 vars) cleanup under env -i + trap source grep" \
    test_dotfiles_vars_unset_after_run
run_test "scripts/setup-deps auto-detects env (yay/dnf/none) and respects override" \
    test_setup_deps_auto_detects_env
run_test "scripts/setup-deps single-pass batch install per env (T8 A/B/C/D/F)" \
    test_setup_deps_single_pass_batch_install

echo "# $((TESTS_RUN - TESTS_FAILED))/$TESTS_RUN passed"
if (( TESTS_FAILED == 0 )); then
    exit 0
fi
exit 1
