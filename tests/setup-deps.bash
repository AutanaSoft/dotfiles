#!/usr/bin/env bash
# tests/setup-deps.bash — minimal repo-native tests for the root `./setup`
# dependency flow.
#
# Usage:
#     bash tests/setup-deps.bash
#     # or
#     ./tests/setup-deps.bash
#
# These tests verify the dispatch behavior of the root `./setup`
# orchestrator. They do NOT install packages, modify the live home, or
# touch the repo on disk. Each test runs in a fresh temp HOME with stub
# commands on PATH, so the only commands ever invoked are bash builtins,
# POSIX utilities (mkdir, ln, readlink, find, etc.), and the stubs
# declared in `make_stubs` below.
#
# Output is TAP-ish: one `ok N - <name>` or `not ok N - <name>` line per
# test, followed by a summary. Exit code is 0 on full pass.
#
# Requires only Bash. No external test framework (Bats, shellcheck,
# etc.) is needed at test time.

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
TEST_PLAN=3

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
    for cmd in omarchy hyprctl yay dnf curl unzip fc-cache; do
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
#   <sandbox>/home   — temp HOME
#   <sandbox>/stubs  — command stubs (chmod +x)
#   <sandbox>/stub.log — sentinel log the stubs append to
# Echoes the absolute path to stdout.
make_sandbox() {
    local dir
    dir="$(mktemp -d "$TEST_WORKSPACE/sandbox.XXXXXX")"
    mkdir -p "$dir/home/.config" "$dir/home/.ssh" "$dir/home/.local/share"
    : >"$dir/stub.log"
    make_stubs "$dir/stubs"
    printf '%s\n' "$dir"
}

# ---------------------------------------------------------------------------
# Run the setup orchestrator with an isolated environment.
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
# `./setup --dry-run --omarchy` runs deps before the env step,
# previews missing deps, and never invokes the real package manager.
test_omarchy_dry_run_runs_deps_before_env() {
    local sandbox output rc deps_line env_line
    sandbox="$(make_sandbox)"

    set +e
    output="$(run_setup "$sandbox" --dry-run --omarchy 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'expected exit 0, got %d\n%s\n' "$rc" "$output" >&2
        return 1
    fi

    # Deps step ran.
    assert_grep "$output" '\[setup-deps\]' 'setup-deps tag present'

    # Env step ran (and produced its own log tag).
    assert_grep "$output" '\[setup-omarchy\]' 'setup-omarchy tag present'

    # Deps ran BEFORE env: the orchestrator's "install dependencies
    # for omarchy" log line must precede the first [setup-omarchy]
    # log line.
    deps_line="$(grep -n 'install dependencies for omarchy' <<<"$output" \
        | head -1 | cut -d: -f1 || true)"
    env_line="$(grep -n '\[setup-omarchy\]' <<<"$output" \
        | head -1 | cut -d: -f1 || true)"
    if [[ -z "$deps_line" ]]; then
        printf 'deps log line not found\noutput:\n%s\n' "$output" >&2
        return 1
    fi
    if [[ -z "$env_line" ]]; then
        printf 'env log line not found\noutput:\n%s\n' "$output" >&2
        return 1
    fi
    if (( deps_line >= env_line )); then
        printf 'deps (line %s) must run before env (line %s)\noutput:\n%s\n' \
            "$deps_line" "$env_line" "$output" >&2
        return 1
    fi

    # Dry-run preview: setup-deps reports the would-be install for
    # each missing package, without running yay.
    assert_grep "$output" '\[dry-run\] would run: yay -S --needed ' \
        'yay dry-run preview present'
    assert_not_grep "$output" '\[dry-run\] would run: sudo dnf' \
        'no Fedora preview in Omarchy run'

    # Step counter: 1/2 then 2/2.
    assert_grep "$output" 'Step 1/2' 'deps step labelled 1/2'
    assert_grep "$output" 'Step 2/2' 'env step labelled 2/2'

    # Stub-pacman was actually invoked (proves the test went through
    # the verification path, not some other code path).
    assert_grep "$(cat -- "$sandbox/stub.log")" '^pacman ' \
        'pacman stub was invoked'

    # No real-package-manager side effects. The stub-pacman logs to
    # the stub log AND its output is discarded by setup-deps, so the
    # captured stdout/stderr should not contain the stub's own log
    # line.
    assert_not_grep "$output" '\[STUB\] pacman called' \
        'no stub stderr leaked into captured output'

    # Fonts step was NOT requested.
    assert_not_grep "$output" 'install fonts' 'no fonts step'
    assert_not_grep "$output" 'Step 1/3' 'no 3-step run'

    return 0
}

# ---------------------------------------------------------------------------
# Test 2
# ---------------------------------------------------------------------------
# `./setup --dry-run --fedora` exits 0 and skips the Fedora env
# executor (which is absent) with a clear warning, after the deps
# preview ran.
test_fedora_dry_run_skips_env_when_executor_missing() {
    local sandbox output rc
    sandbox="$(make_sandbox)"

    set +e
    output="$(run_setup "$sandbox" --dry-run --fedora 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'expected exit 0, got %d\n%s\n' "$rc" "$output" >&2
        return 1
    fi

    # Deps step ran and previewed Fedora packages.
    assert_grep "$output" '\[setup-deps\]' 'setup-deps tag present'
    assert_grep "$output" '\[dry-run\] would run: sudo dnf install -y ' \
        'dnf dry-run preview present'

    # Env executor skip warning + log line.
    assert_grep "$output" 'Fedora env executor is not implemented' \
        'skip warning present'
    assert_grep "$output" 'skip Fedora env' 'skip log line present'

    # The absent executor must NOT be invoked. setup-fedora does not
    # exist on disk; assert that no log line was emitted from inside
    # it.
    assert_not_grep "$output" '\[setup-fedora\]' 'setup-fedora not invoked'

    # Step counter: 1/2 then 2/2 (last is the skip step).
    assert_grep "$output" 'Step 1/2' 'deps step labelled 1/2'
    assert_grep "$output" 'Step 2/2' 'skip step labelled 2/2'

    # Stub-rpm was invoked.
    assert_grep "$(cat -- "$sandbox/stub.log")" '^rpm ' \
        'rpm stub was invoked'

    # The Omarchy branch must not have run.
    assert_not_grep "$output" '\[setup-omarchy\]' 'no Omarchy env ran'
    assert_not_grep "$output" 'yay -S --needed' 'no yay preview'
    assert_not_grep "$output" 'install fonts' 'no fonts step'

    return 0
}

# ---------------------------------------------------------------------------
# Test 3
# ---------------------------------------------------------------------------
# `./setup --dry-run --fonts` does NOT run the deps step. Fonts-only
# run, single step, no env.
test_fonts_dry_run_does_not_run_deps() {
    local sandbox output rc stub_log
    sandbox="$(make_sandbox)"
    stub_log="$sandbox/stub.log"

    set +e
    output="$(run_setup "$sandbox" --dry-run --fonts 2>&1)"
    rc=$?
    set -e

    if [[ $rc -ne 0 ]]; then
        printf 'expected exit 0, got %d\n%s\n' "$rc" "$output" >&2
        return 1
    fi

    # Fonts step ran.
    assert_grep "$output" 'install fonts' 'fonts step ran'
    assert_grep "$output" '\[setup-fonts\]' 'setup-fonts tag present'

    # Deps step did NOT run.
    assert_not_grep "$output" '\[setup-deps\]' 'no setup-deps tag'
    assert_not_grep "$output" 'install dependencies' 'no deps log'
    assert_not_grep "$output" 'Step [0-9]*/[2-9]' 'no multi-step run'

    # Single step.
    assert_grep "$output" 'Step 1/1' 'single step labelled 1/1'

    # No env.
    assert_not_grep "$output" '\[setup-omarchy\]' 'no Omarchy env'
    assert_not_grep "$output" '\[setup-fedora\]' 'no Fedora env'
    assert_not_grep "$output" 'Fedora env executor is not implemented' \
        'no Fedora skip warning'

    # No package manager stubs were invoked: fonts dry-run never
    # needs them. setup-fonts in dry-run does not call curl, unzip,
    # or fc-cache either.
    if [[ -s "$stub_log" ]]; then
        printf 'stub log should be empty for fonts-only run; got:\n%s\n' \
            "$(cat -- "$stub_log")" >&2
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

run_test "omarchy dry-run runs deps before env and previews missing deps" \
    test_omarchy_dry_run_runs_deps_before_env
run_test "fedora dry-run exits 0 and skips env executor when absent" \
    test_fedora_dry_run_skips_env_when_executor_missing
run_test "fonts dry-run does not run deps" \
    test_fonts_dry_run_does_not_run_deps

echo "# $((TESTS_RUN - TESTS_FAILED))/$TESTS_RUN passed"
if (( TESTS_FAILED == 0 )); then
    exit 0
fi
exit 1
