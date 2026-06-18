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
# The full spec describes 5 tests (T1, T2, T4, T5, T6). PR-2 landed
# T1, T2, T4, T5, and T6. T3 (the env-only short-circuit) was removed
# in the dispatcher collapse. T7 and T8 (setup-deps auto-detect and
# single-pass batch install per env) were removed in the deps collapse
# because the per-env shape no longer applies — the only env is now
# Omarchy.
#
#   PR-1               T1  --dots invokes setup-dots once
#                     T2  --dots --fonts/--deps are absorbed
#                     T4  --fonts runs only setup-fonts; --deps only setup-deps
#                     T6  DOTFILES_* (5 vars) cleanup under env -i + trap grep
#   PR-2               T5  env-script pre-flight blocks on missing
#                            $DOTFILES_FONTS_DIR; honors override (defense
#                            in depth for direct invocation).
#
# `make_sandbox_no_fonts` (defined below) is the fixture for T5's
# missing-fonts sub-case. `make_pm_stubs` and `make_minimal_utils_dir`
# are kept as general-purpose infrastructure; the no-PM-fail path in
# T4 sub-case D still uses `make_minimal_utils_dir`.

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
# PR-3 covered T1, T2, T4, T5, T6, T7. T7 (setup-deps auto-detect) and
# T8 (setup-deps single-pass batch install per env) were removed in
# the deps collapse. The only env is now Omarchy, so the per-env
# sub-cases no longer apply.
TEST_PLAN=5

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
#                                                setup-dots pre-flight
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
# setup-dots invoked without fonts installed must fail fast at the
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
# Selective PM stubs (general-purpose fixture)
# ---------------------------------------------------------------------------
# Create a stubs directory with ONLY the specified commands. Used by the
# no-PM-fail propagation path in T4 sub-case D and any future test that
# needs a deterministic package-manager PATH. Pacman and rpm get a
# "package missing" stub (exit 1); other commands get a "present" stub
# (exit 0). Same shape as make_stubs, but with a caller-controlled list.
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
# Minimal utilities dir (general-purpose fixture)
# ---------------------------------------------------------------------------
# Build a directory containing symlinks to the few external utilities
# setup-deps needs (dirname, cat). Used by the no-PM-fail propagation
# path in T4 sub-case D and any future test that needs to strip the
# host's /usr/bin from PATH, so the test is not contaminated by host
# PMs (the dev host is Omarchy: yay and pacman live on /usr/bin).
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
# `./setup --dry-run --dots` invokes `src/utils/bash/setup-dots` exactly
# once and the dispatcher targets setup-dots (not setup-deps or
# setup-fonts). The env script now owns the full flow, so its
# subprocess calls (setup-deps, setup-fonts) appear in the output as a
# consequence of the env script's flow — that is correct PR-2 behavior.
test_root_omarchy_invokes_setup_omarchy_once() {
    local sandbox output rc
    sandbox="$(make_sandbox)"

    set +e
    output="$(run_setup "$sandbox" --dry-run --dots 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'expected exit 0, got %d\n%s\n' "$rc" "$output" >&2
        return 1
    fi

    # Root dispatched to setup-dots exactly once. The dispatcher's
    # breadcrumb is the externally observable signal that root chose
    # the omarchy target, not setup-deps or setup-fonts.
    assert_grep "$output" '\[setup\] Dispatching to: setup-dots' \
        'root dispatched to setup-dots'
    # setup-dots ran and finished its flow.
    assert_grep "$output" '\[setup-dots\]' 'setup-dots tag present'
    assert_grep "$output" '\[setup-dots\] Setup complete' \
        'setup-dots finished its main()'

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
# `./setup --dots --fonts` and `./setup --dots --deps` are
# absorbed by the dispatcher: root dispatches to `src/utils/bash/setup-dots`
# exactly once, and does NOT also dispatch to `setup-fonts` or
# `setup-deps`. The env script owns the full flow and calls the
# sub-scripts internally as part of its own main().
test_omarchy_with_fonts_or_deps_absorbed() {
    local sandbox output rc

    # --- Sub-case A: --dots --fonts.
    sandbox="$(make_sandbox)"

    set +e
    output="$(run_setup "$sandbox" --dry-run --dots --fonts 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case A: expected exit 0, got %d\n%s\n' "$rc" "$output" >&2
        return 1
    fi

    assert_grep "$output" '\[setup\] Dispatching to: setup-dots' \
        'sub-case A: root dispatched to setup-dots'
    assert_grep "$output" '\[setup-dots\]' \
        'sub-case A: setup-dots ran'
    assert_not_grep "$output" '\[setup\] Dispatching to: setup-fonts' \
        'sub-case A: root did not dispatch to setup-fonts'
    assert_not_grep "$output" '\[setup\] Dispatching to: setup-deps' \
        'sub-case A: root did not dispatch to setup-deps'

    # --- Sub-case B: --dots --deps.
    sandbox="$(make_sandbox)"

    set +e
    output="$(run_setup "$sandbox" --dry-run --dots --deps 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'sub-case B: expected exit 0, got %d\n%s\n' "$rc" "$output" >&2
        return 1
    fi

    assert_grep "$output" '\[setup\] Dispatching to: setup-dots' \
        'sub-case B: root dispatched to setup-dots'
    assert_grep "$output" '\[setup-dots\]' \
        'sub-case B: setup-dots ran'
    assert_not_grep "$output" '\[setup\] Dispatching to: setup-deps' \
        'sub-case B: root did not dispatch to setup-deps'
    assert_not_grep "$output" '\[setup\] Dispatching to: setup-fonts' \
        'sub-case B: root did not dispatch to setup-fonts'

    return 0
}

# ---------------------------------------------------------------------------
# Test 4
# ---------------------------------------------------------------------------
# `./setup --fonts` (alone or with `--dry-run`) runs ONLY
# `src/utils/bash/setup-fonts`. `./setup --deps` (alone or with `--dry-run`)
# runs ONLY `src/utils/bash/setup-deps`. Root does not call the env executor
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
    assert_not_grep "$output" '\[setup-dots\]' \
        'sub-case A: setup-dots did not run'
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
    # The dispatcher's contract for --deps is: invoke src/utils/bash/setup-deps
    # exactly once, do not call setup-fonts or setup-dots. With the
    # Omarchy-only scope lock, setup-deps auto-detects the host: when no
    # env flag is passed, it probes package managers and picks omarchy.
    # In make_sandbox yay and pacman are stubbed, so the probe picks
    # yay first → omarchy. The T4 contract is purely about dispatch.
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
    # src/utils/bash/setup-deps was the target.
    assert_grep "$output" '\[setup\] Dispatching to: setup-deps' \
        'sub-case B: dispatcher invoked setup-deps'
    # setup-deps's own log tag is now emitted because auto-detect
    # replaces the previous "choose an environment" error path.
    assert_grep "$output" '\[setup-deps\]' \
        'sub-case B: setup-deps ran (auto-detect succeeded)'
    assert_not_grep "$output" '\[setup-fonts\]' \
        'sub-case B: setup-fonts did not run'
    assert_not_grep "$output" '\[setup-dots\]' \
        'sub-case B: setup-dots did not run'

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
# The env script (src/utils/bash/setup-dots) is responsible for the full env
# flow. Its pre-flight verifies the fonts dir is present and non-empty.
# This is defense-in-depth for direct invocation (running setup-dots
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
    setup_omarchy="$REPO_ROOT/src/utils/bash/setup-dots"

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
    assert_grep "$output" '\[setup-dots\] Setup complete' \
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
    # setup-dots logs the env var in its pre-flight and setup-fonts
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
            "$1" --dots
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

run_test "root --dots invokes setup-dots exactly once" \
    test_root_omarchy_invokes_setup_omarchy_once
run_test "--dots --fonts and --dots --deps are absorbed by root" \
    test_omarchy_with_fonts_or_deps_absorbed
run_test "--fonts runs only setup-fonts; --deps runs only setup-deps" \
    test_fonts_or_deps_only_direct_dispatch
run_test "env-script pre-flight handles missing/overridden \$DOTFILES_FONTS_DIR" \
    test_env_script_preflight_handles_fonts_dir
run_test "DOTFILES_* (5 vars) cleanup under env -i + trap source grep" \
    test_dotfiles_vars_unset_after_run

echo "# $((TESTS_RUN - TESTS_FAILED))/$TESTS_RUN passed"
if (( TESTS_FAILED == 0 )); then
    exit 0
fi
exit 1
