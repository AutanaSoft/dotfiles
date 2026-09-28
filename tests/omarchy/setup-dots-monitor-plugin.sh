#!/usr/bin/env bash
set -euo pipefail

script="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)/omarchy/utils/bash/setup-dots"
tmp="$(mktemp -d)"
mkdir -p "$tmp/bin"
trap 'rm -rf -- "$tmp"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_log() { grep -Fq -- "$1" "$tmp/log" || fail "missing call: $1"; }

run_case() {
    local name="$1" state="$2" mode="${3:-}" home repo
    home="$tmp/$name/home"
    repo="$tmp/$name/repo"
    mkdir -p "$home/.local/bin" "$repo/omarchy/home/config/omarchy/plugins/lcardenas.monitor" "$tmp/bin"
    printf 'plugin\n' > "$repo/omarchy/home/config/omarchy/plugins/lcardenas.monitor/manifest.json"
    printf 'dir\tomarchy/home/config/omarchy/plugins/lcardenas.monitor\t.config/omarchy/plugins/lcardenas.monitor\n' > "$repo/omarchy/dots-manifest"
    : > "$tmp/log"
    HOME="$home" DOTFILES_ROOT="$repo" DOTFILES_BACKUP_DIR="$tmp/$name/backup" \
        PLUGIN_STATE="$state" CALL_LOG="$tmp/log" PATH="$tmp/bin:$PATH" \
        bash "$script" $mode > "$tmp/output" 2>&1
}

cat > "$tmp/bin/omarchy" <<'EOF'
#!/usr/bin/env bash
[[ $1 == version ]] && { echo 4.0.4; exit 0; }
printf 'omarchy %s\n' "$*" >> "$CALL_LOG"
exit 0
EOF
cat > "$tmp/bin/omarchy-shell" <<'EOF'
#!/usr/bin/env bash
printf 'shell %s\n' "$*" >> "$CALL_LOG"
[[ $PLUGIN_STATE == no-shell ]] && exit 1
if [[ $* == 'shell listPlugins' ]]; then
    case "$PLUGIN_STATE" in
        delayed)
            count_file="${CALL_LOG}.count"
            count=0
            [[ ! -f "$count_file" ]] || read -r count < "$count_file"
            printf '%s\n' "$((count + 1))" > "$count_file"
            if (( count < 2 )); then echo '[]'; exit 0; fi
            echo '[{"id":"lcardenas.monitor","enabled":false},{"id":"omarchy.power","enabled":true}]'
            exit 0
            ;;
        enabled) echo '[{"id":"lcardenas.monitor","enabled":true},{"id":"omarchy.power","enabled":true}]' ;;
        no-power) echo '[{"id":"lcardenas.monitor","enabled":false}]' ;;
        *) echo '[{"id":"lcardenas.monitor","enabled":false},{"id":"omarchy.power","enabled":true}]' ;;
    esac
fi
EOF
chmod +x "$tmp/bin/omarchy" "$tmp/bin/omarchy-shell"

run_case fresh fresh
assert_log 'shell shell rescanPlugins'
assert_log 'omarchy plugin enable lcardenas.monitor --section right --before omarchy.power'
[[ -L "$tmp/fresh/home/.config/omarchy/plugins/lcardenas.monitor" ]] || fail 'plugin not linked'

run_case delayed delayed
assert_log 'omarchy plugin enable lcardenas.monitor --section right --before omarchy.power'
[[ $(grep -Fc 'shell shell listPlugins' "$tmp/log") -eq 3 ]] || fail 'delayed discovery was not retried'

run_case enabled enabled
assert_log 'shell shell listPlugins'
! grep -q 'plugin enable' "$tmp/log" || fail 'already enabled widget was moved'

run_case fallback no-power
assert_log 'omarchy plugin enable lcardenas.monitor --section right'

if run_case unavailable no-shell; then fail 'unavailable shell reported success'; fi
grep -qi 'shell' "$tmp/output" || fail 'no actionable shell error'

run_case dry fresh --dry-run
[[ ! -e "$tmp/dry/home/.config" ]] || fail 'dry-run modified HOME'
! grep -q '^shell\|^omarchy plugin enable' "$tmp/log" || fail 'dry-run changed runtime'
grep -q 'rescanPlugins' "$tmp/output" || fail 'dry-run did not announce rescan'

for kind in matching other file; do
    home="$tmp/stale-$kind/home"
    repo="$tmp/stale-$kind/repo"
    mkdir -p "$home/.local/bin" "$repo/omarchy/home/config/omarchy/plugins/lcardenas.monitor"
    printf 'plugin\n' > "$repo/omarchy/home/config/omarchy/plugins/lcardenas.monitor/manifest.json"
    printf 'dir\tomarchy/home/config/omarchy/plugins/lcardenas.monitor\t.config/omarchy/plugins/lcardenas.monitor\n' > "$repo/omarchy/dots-manifest"
    case "$kind" in
        matching) ln -s "$repo/omarchy/home/local/bin/monitor" "$home/.local/bin/monitor" ;;
        other) ln -s /other/monitor "$home/.local/bin/monitor" ;;
        file) printf 'keep\n' > "$home/.local/bin/monitor" ;;
    esac
    : > "$tmp/log"
    HOME="$home" DOTFILES_ROOT="$repo" PLUGIN_STATE=enabled CALL_LOG="$tmp/log" \
        PATH="$tmp/bin:$PATH" bash "$script" > "$tmp/output" 2>&1
    if [[ "$kind" == matching ]]; then
        [[ ! -e "$home/.local/bin/monitor" && ! -L "$home/.local/bin/monitor" ]] || fail 'obsolete link retained'
    else
        [[ -e "$home/.local/bin/monitor" || -L "$home/.local/bin/monitor" ]] || fail 'unrelated monitor removed'
    fi
done

echo 'setup-dots monitor plugin cases passed'
