#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT_DIR/omarchy/home/local/bin/backup-mirror"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/backup mirror.XXXXXX")"
mkdir -m 700 "$TEMP_DIR/runtime" "$TEMP_DIR/runtime-alt" "$TEMP_DIR/bin" "$TEMP_DIR/home" "$TEMP_DIR/mount"
export HOME="$TEMP_DIR/home" XDG_RUNTIME_DIR="$TEMP_DIR/runtime"
export TEST_MOUNT_PATH="$TEMP_DIR/mount" TEST_MOUNTED=yes TEST_UUID=7AA6431BA642D6F3
export PATH="$TEMP_DIR/bin:$PATH"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  grep -Fq -- "$1" "$2" || fail "Expected '$1' in $2"
}

assert_file() {
  [[ -f "$1" ]] || fail "Expected file: $1"
}

assert_absent() {
  [[ ! -e "$1" ]] || fail "Expected absent path: $1"
}

cat > "$TEMP_DIR/bin/mountpoint" <<'EOF'
#!/usr/bin/env bash
[[ "${TEST_MOUNTED:-yes}" == yes && "${*: -1}" == "$TEST_MOUNT_PATH" ]]
EOF
cat > "$TEMP_DIR/bin/findmnt" <<'EOF'
#!/usr/bin/env bash
case " $* " in
  *' --output TARGET '*)
    [[ "${TEST_MOUNTED:-yes}" == yes ]] || exit 1
    printf '%s\n' "$TEST_MOUNT_PATH"
    case " $* " in
      *' --submounts '*) [[ -z "${TEST_NESTED_MOUNT:-}" ]] || printf '%s\n' "$TEST_NESTED_MOUNT" ;;
    esac
    ;;
  *' --output UUID '*)
    [[ "${TEST_MOUNTED:-yes}" == yes ]] || exit 1
    printf '%s\n' "${TEST_UUID:-}"
    ;;
  *) printf '%s\n' "$TEST_MOUNT_PATH" ;;
esac
EOF
chmod +x "$TEMP_DIR/bin/mountpoint" "$TEMP_DIR/bin/findmnt"

mkdir -p "$HOME/Documents" "$HOME/Pictures" "$HOME/Folder With Spaces" "$HOME/Disabled" "$HOME/Projects/nested/node_modules" "$HOME/Projects/nested/.turbo" \
  "$HOME/Projects/airtm-cashiers-activity/apps/cli/build" \
  "$HOME/Projects/some directory/cache" "$HOME/Projects/keep dir" \
  "$TEST_MOUNT_PATH/Documents" "$TEST_MOUNT_PATH/Projects/nested/node_modules" \
  "$TEST_MOUNT_PATH/Projects/some directory/cache"
printf 'base\n' > "$HOME/Documents/keep.txt"
printf 'spaced exclusion\n' > "$HOME/Projects/some directory/cache/keep.txt"
printf 'spaced destination exclusion\n' > "$TEST_MOUNT_PATH/Projects/some directory/cache/existing.txt"
printf 'spaced folder\n' > "$HOME/Folder With Spaces/note.txt"
printf 'not selected\n' > "$HOME/Disabled/ignored.txt"
printf 'old destination\n' > "$TEST_MOUNT_PATH/Documents/keep.txt"
printf 'excluded\n' > "$HOME/Projects/nested/node_modules/dependency.js"
printf 'excluded\n' > "$HOME/Projects/nested/.turbo/cache"
printf 'excluded\n' > "$HOME/Projects/airtm-cashiers-activity/apps/cli/build/output"
printf 'with spaces\n' > "$HOME/Projects/keep dir/file name.txt"
printf 'preserve\n' > "$TEST_MOUNT_PATH/Projects/nested/node_modules/old.js"
printf 'remove\n' > "$TEST_MOUNT_PATH/Projects/obsolete.txt"
printf 'unrelated\n' > "$TEST_MOUNT_PATH/unrelated.txt"

write_config() {
  cat > "$TEMP_DIR/config" <<EOF
[destination]
mount_path = $TEST_MOUNT_PATH
uuid = 7AA6431BA642D6F3

[folders]
Documents
Folder With Spaces
Pictures
Projects

[exclusions]
Projects:/**/node_modules/
Projects:/**/.turbo/
Projects:airtm-cashiers-activity/apps/cli/build/
Projects:some directory/cache/
EOF
}
write_config

# Bare list entries preserve internal spaces and honor blank/comment lines.
cat > "$TEMP_DIR/bare-lists.conf" <<EOF
[destination]
mount_path = $TEST_MOUNT_PATH
uuid = 7AA6431BA642D6F3

[folders]
# Disabled
Documents
$(printf '  Folder With Spaces  ')
Pictures
Projects

[exclusions]
Projects:/**/node_modules/
Projects:/**/.turbo/
Projects:airtm-cashiers-activity/apps/cli/build/
EOF
if ! "$SCRIPT" --config "$TEMP_DIR/bare-lists.conf" --dry-run > "$TEMP_DIR/bare-lists.out" 2>&1; then
  printf '%s\n' "$(<"$TEMP_DIR/bare-lists.out")" >&2
  fail 'Bare-list configuration was rejected'
fi
assert_contains "$HOME/Folder With Spaces" "$TEMP_DIR/bare-lists.out"
if grep -Fq "$HOME/Disabled" "$TEMP_DIR/bare-lists.out"; then fail 'Commented folder was activated'; fi

# A config is parsed as data, never evaluated as shell code.
cat >> "$TEMP_DIR/config" <<'EOF'
$(touch "${TEMP_DIR}/executed") = true
EOF
if "$SCRIPT" --config "$TEMP_DIR/config" > "$TEMP_DIR/out" 2>&1; then
  fail 'Executable config syntax unexpectedly succeeded'
fi
assert_absent "$TEMP_DIR/executed"
write_config

# Preview is the default and must not alter the destination.
"$SCRIPT" --config "$TEMP_DIR/config" > "$TEMP_DIR/out" 2>&1 || { printf '%s\n' "$(<"$TEMP_DIR/out")" >&2; fail 'Default preview failed'; }
assert_contains 'Preview complete' "$TEMP_DIR/out"
assert_contains '*deleting' "$TEMP_DIR/out"
grep '^\*deleting ' "$TEMP_DIR/out" | sed 's/^\*deleting *//' > "$TEMP_DIR/preview-deletions"
assert_absent "$TEST_MOUNT_PATH/Pictures"
[[ "$(<"$TEST_MOUNT_PATH/Documents/keep.txt")" == 'old destination' ]] || fail 'Preview changed mirror content'
assert_file "$TEST_MOUNT_PATH/Projects/obsolete.txt"
assert_file "$TEST_MOUNT_PATH/Projects/nested/node_modules/old.js"

# Apply copies files with spaces, updates selected roots, and deletes only in those roots.
"$SCRIPT" --config "$TEMP_DIR/config" --apply > "$TEMP_DIR/apply.out" 2>&1 || fail 'Apply failed'
grep '^\*deleting ' "$TEMP_DIR/apply.out" | sed 's/^\*deleting *//' > "$TEMP_DIR/apply-deletions"
cmp -s "$TEMP_DIR/preview-deletions" "$TEMP_DIR/apply-deletions" || fail 'Preview deletion plan differs from apply'
assert_file "$TEST_MOUNT_PATH/Documents/keep.txt"
[[ -d "$TEST_MOUNT_PATH/Pictures" ]] || fail 'Apply did not create a missing destination folder'
cmp -s "$HOME/Documents/keep.txt" "$TEST_MOUNT_PATH/Documents/keep.txt" || fail 'Existing file was not updated'
assert_file "$TEST_MOUNT_PATH/Projects/keep dir/file name.txt"
assert_file "$TEST_MOUNT_PATH/Folder With Spaces/note.txt"
assert_file "$TEST_MOUNT_PATH/Projects/some directory/cache/existing.txt"
assert_absent "$TEST_MOUNT_PATH/Projects/obsolete.txt"
assert_absent "$TEST_MOUNT_PATH/Projects/nested/.turbo/cache"
assert_absent "$TEST_MOUNT_PATH/Projects/nested/node_modules/dependency.js"
assert_file "$TEST_MOUNT_PATH/Projects/nested/node_modules/old.js"
assert_file "$TEST_MOUNT_PATH/unrelated.txt"

# Required tools are checked before creating any destination or lock directories.
mkdir -m 700 "$TEMP_DIR/no-rsync-bin" "$TEMP_DIR/no-rsync-runtime" "$TEMP_DIR/no-rsync-mount"
for tool in bash cat realpath stat dirname cksum mkdir flock; do
  ln -s "$(command -v "$tool")" "$TEMP_DIR/no-rsync-bin/$tool"
done
ln -s "$TEMP_DIR/bin/findmnt" "$TEMP_DIR/no-rsync-bin/findmnt"
ln -s "$TEMP_DIR/bin/mountpoint" "$TEMP_DIR/no-rsync-bin/mountpoint"
cat > "$TEMP_DIR/no-rsync-config" <<EOF
[destination]
mount_path = $TEMP_DIR/no-rsync-mount
uuid = 7AA6431BA642D6F3

[folders]
Documents

[exclusions]
EOF
if PATH="$TEMP_DIR/no-rsync-bin" HOME="$HOME" XDG_RUNTIME_DIR="$TEMP_DIR/no-rsync-runtime" TEST_MOUNT_PATH="$TEMP_DIR/no-rsync-mount" "$SCRIPT" --config "$TEMP_DIR/no-rsync-config" --apply > "$TEMP_DIR/no-rsync.out" 2>&1; then
  fail 'Missing rsync unexpectedly succeeded'
fi
assert_contains 'rsync' "$TEMP_DIR/no-rsync.out"
assert_absent "$TEMP_DIR/no-rsync-mount/Documents"
assert_absent "$TEMP_DIR/no-rsync-runtime/backup-mirror"

# Complete preflight rejects a missing source before any transfer starts.
mkdir "$TEMP_DIR/failure-bin"
cat > "$TEMP_DIR/failure-bin/rsync" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == --help ]]; then printf '%s\n' '--mkpath'; exit 0; fi
printf 'unexpected transfer\n' >> "$RSYNC_LOG"
exit 91
EOF
chmod +x "$TEMP_DIR/failure-bin/rsync"
export RSYNC_LOG="$TEMP_DIR/rsync.log" PATH="$TEMP_DIR/failure-bin:$PATH"
sed 's/^Documents$/Documents\nDownloads/' "$TEMP_DIR/config" > "$TEMP_DIR/missing.conf"
if "$SCRIPT" --config "$TEMP_DIR/missing.conf" --apply > "$TEMP_DIR/out" 2>&1; then
  fail 'Missing source unexpectedly succeeded'
fi
if ! grep -Fq 'Missing source' "$TEMP_DIR/out"; then printf '%s\n' "$(<"$TEMP_DIR/out")" >&2; fail 'Missing-source preflight message missing'; fi
assert_absent "$RSYNC_LOG"
cat "$TEMP_DIR/config" > "$TEMP_DIR/repeated.conf"
printf '\n[folders]\nDocuments\n' >> "$TEMP_DIR/repeated.conf"
"$SCRIPT" --config "$TEMP_DIR/repeated.conf" > "$TEMP_DIR/out" 2>&1 && fail 'Repeated section accepted'
sed 's|^Projects:some directory/cache/$|Unknown:some directory/cache/|' "$TEMP_DIR/config" > "$TEMP_DIR/unknown-exclusion.conf"
"$SCRIPT" --config "$TEMP_DIR/unknown-exclusion.conf" > "$TEMP_DIR/out" 2>&1 && fail 'Unknown exclusion folder accepted'
sed 's/^\[folders\]$/[unknown]/' "$TEMP_DIR/config" > "$TEMP_DIR/unknown-section.conf"
"$SCRIPT" --config "$TEMP_DIR/unknown-section.conf" > "$TEMP_DIR/out" 2>&1 && fail 'Unknown section accepted'
sed 's/^Folder With Spaces$/Projects/' "$TEMP_DIR/config" > "$TEMP_DIR/duplicate-folder.conf"
"$SCRIPT" --config "$TEMP_DIR/duplicate-folder.conf" > "$TEMP_DIR/out" 2>&1 && fail 'Duplicate folder accepted'
cat "$TEMP_DIR/config" > "$TEMP_DIR/duplicate-exclusion.conf"
printf 'Projects:/**/node_modules/\n' >> "$TEMP_DIR/duplicate-exclusion.conf"
"$SCRIPT" --config "$TEMP_DIR/duplicate-exclusion.conf" > "$TEMP_DIR/out" 2>&1 && fail 'Duplicate exclusion accepted'
sed 's/^Documents$/Documents = true/' "$TEMP_DIR/config" > "$TEMP_DIR/assigned-folder.conf"
"$SCRIPT" --config "$TEMP_DIR/assigned-folder.conf" > "$TEMP_DIR/out" 2>&1 && fail 'Assignment-style folder accepted'
sed 's|^Projects:some directory/cache/$|Projects:some directory/cache/ = true|' "$TEMP_DIR/config" > "$TEMP_DIR/assigned-exclusion.conf"
"$SCRIPT" --config "$TEMP_DIR/assigned-exclusion.conf" > "$TEMP_DIR/out" 2>&1 && fail 'Assignment-style exclusion accepted'
sed 's|^mount_path = |mount_path |' "$TEMP_DIR/config" > "$TEMP_DIR/malformed-destination.conf"
"$SCRIPT" --config "$TEMP_DIR/malformed-destination.conf" > "$TEMP_DIR/out" 2>&1 && fail 'Malformed destination setting accepted'
sed '/^uuid = /a uuid = 7AA6431BA642D6F3' "$TEMP_DIR/config" > "$TEMP_DIR/duplicate-destination-key.conf"
"$SCRIPT" --config "$TEMP_DIR/duplicate-destination-key.conf" > "$TEMP_DIR/out" 2>&1 && fail 'Duplicate destination key accepted'
sed 's/^uuid = /unknown = /' "$TEMP_DIR/config" > "$TEMP_DIR/unknown-destination-key.conf"
"$SCRIPT" --config "$TEMP_DIR/unknown-destination-key.conf" > "$TEMP_DIR/out" 2>&1 && fail 'Unknown destination key accepted'

# Unmounted and wrong-UUID destinations fail before transfer.
TEST_MOUNTED=no "$SCRIPT" --config "$TEMP_DIR/config" --apply > "$TEMP_DIR/out" 2>&1 && fail 'Unmounted destination accepted'
TEST_UUID=wrong "$SCRIPT" --config "$TEMP_DIR/config" --apply > "$TEMP_DIR/out" 2>&1 && fail 'Wrong UUID accepted'

# Symlink sources, unsafe relative paths, and overlapping source roots are rejected.
ln -s "$HOME/Documents" "$HOME/Linked"
sed 's/^Documents$/Linked/' "$TEMP_DIR/config" > "$TEMP_DIR/symlink.conf"
"$SCRIPT" --config "$TEMP_DIR/symlink.conf" --apply > "$TEMP_DIR/out" 2>&1 && fail 'Symlink source accepted'
sed 's/^Documents$/Documents\nDocuments\/nested/' "$TEMP_DIR/config" > "$TEMP_DIR/overlap.conf"
"$SCRIPT" --config "$TEMP_DIR/overlap.conf" > "$TEMP_DIR/out" 2>&1 && fail 'Overlapping sources accepted'
sed 's/^Documents$/Documents\/..\/outside/' "$TEMP_DIR/config" > "$TEMP_DIR/unsafe.conf"
"$SCRIPT" --config "$TEMP_DIR/unsafe.conf" > "$TEMP_DIR/out" 2>&1 && fail 'Traversal source accepted'

mkdir -p "$HOME/Pictures"
ln -s "$TEST_MOUNT_PATH/Documents" "$TEST_MOUNT_PATH/Pictures"
cat > "$TEMP_DIR/destination-link.conf" <<EOF
[destination]
mount_path = $TEST_MOUNT_PATH
uuid = 7AA6431BA642D6F3

[folders]
Pictures

[exclusions]
EOF
"$SCRIPT" --config "$TEMP_DIR/destination-link.conf" --apply > "$TEMP_DIR/out" 2>&1 && fail 'Symlink destination accepted'
sed "s|^mount_path = .*|mount_path = $HOME|" "$TEMP_DIR/config" > "$TEMP_DIR/overlapping-destination.conf"
TEST_MOUNT_PATH="$HOME" "$SCRIPT" --config "$TEMP_DIR/overlapping-destination.conf" --apply > "$TEMP_DIR/out" 2>&1 && fail 'Overlapping destination accepted'
sed "s|^mount_path = .*|mount_path = $HOME/Documents|" "$TEMP_DIR/config" > "$TEMP_DIR/equal-destination.conf"
TEST_MOUNT_PATH="$HOME/Documents" "$SCRIPT" --config "$TEMP_DIR/equal-destination.conf" --apply > "$TEMP_DIR/out" 2>&1 && fail 'Equal source and destination accepted'
TEST_NESTED_MOUNT="$HOME/Documents/mounted" "$SCRIPT" --config "$TEMP_DIR/config" > "$TEMP_DIR/out" 2>&1 && fail 'Nested source mount accepted'

# A transfer error is propagated and reported without claiming full completion.
export PATH="$TEMP_DIR/failure-bin:$PATH"
printf 'fail\n' > "$HOME/Documents/failure-trigger"
if "$SCRIPT" --config "$TEMP_DIR/config" --apply > "$TEMP_DIR/out" 2>&1; then
  fail 'Transfer failure unexpectedly succeeded'
fi
assert_contains 'rsync failed' "$TEMP_DIR/out"
if grep -Fq 'Mirror complete' "$TEMP_DIR/out"; then fail 'Failed transfer claimed full completion'; fi

# Root may request help, but never config evaluation, even inside a user namespace.
if command -v unshare >/dev/null && unshare --user --map-root-user true >/dev/null 2>&1; then
  unshare --user --map-root-user -- "$SCRIPT" --help > "$TEMP_DIR/root-help.out" 2>&1 || fail 'Root help was rejected'
  if unshare --user --map-root-user -- "$SCRIPT" --config "$TEMP_DIR/does-not-exist" > "$TEMP_DIR/root.out" 2>&1; then
    fail 'Root execution unexpectedly succeeded'
  fi
  assert_contains 'root' "$TEMP_DIR/root.out"
  if grep -Fq 'config is not a readable' "$TEMP_DIR/root.out"; then fail 'Root check ran after config access'; fi
else
  printf 'SKIP: user namespaces unavailable; root refusal not exercised\n'
fi

# An active preview/apply lock excludes concurrent calls even with different XDG overrides.
mkdir "$TEMP_DIR/block-bin"
cat > "$TEMP_DIR/block-bin/rsync" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == --help ]]; then printf '%s\n' '--mkpath'; exit 0; fi
touch "$RSYNC_STARTED"
sleep 2
EOF
chmod +x "$TEMP_DIR/block-bin/rsync"
export RSYNC_STARTED="$TEMP_DIR/rsync-started" PATH="$TEMP_DIR/block-bin:$PATH"
XDG_RUNTIME_DIR="$TEMP_DIR/runtime" "$SCRIPT" --config "$TEMP_DIR/config" > "$TEMP_DIR/first.out" 2>&1 &
first_pid=$!
for _ in {1..100}; do [[ -e "$RSYNC_STARTED" ]] && break; sleep 0.02; done
[[ -e "$RSYNC_STARTED" ]] || fail 'First process did not reach transfer'
cp "$TEMP_DIR/config" "$TEMP_DIR/alternate.conf"
if XDG_RUNTIME_DIR="$TEMP_DIR/runtime-alt" "$SCRIPT" --config "$TEMP_DIR/alternate.conf" --apply > "$TEMP_DIR/second.out" 2>&1; then
  fail 'Concurrent operation unexpectedly acquired the lock'
fi
assert_contains 'already running' "$TEMP_DIR/second.out"
wait "$first_pid" || fail 'First locked process failed'

printf 'backup-mirror: all tests passed\n'
