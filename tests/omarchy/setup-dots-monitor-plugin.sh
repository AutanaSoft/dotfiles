#!/usr/bin/env bash
set -euo pipefail

script="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)/omarchy/utils/bash/setup-dots"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }
mkdir -p "$tmp/bin"
cat > "$tmp/bin/omarchy" <<'EOF'
#!/usr/bin/env bash
[[ $1 == version ]] && { echo 4.5.0; exit 0; }
echo 'unexpected omarchy invocation' >&2
exit 1
EOF
cat > "$tmp/bin/omarchy-shell" <<'EOF'
#!/usr/bin/env bash
echo 'unexpected omarchy-shell invocation' >&2
exit 1
EOF
chmod +x "$tmp/bin/omarchy" "$tmp/bin/omarchy-shell"

for kind in matching other file; do
    home="$tmp/$kind/home"
    repo="$tmp/$kind/repo"
    mkdir -p "$home/.local/bin" "$repo/omarchy"
    printf '# empty manifest\n' > "$repo/omarchy/dots-manifest"
    case "$kind" in
        matching) ln -s "$repo/omarchy/home/local/bin/monitor" "$home/.local/bin/monitor" ;;
        other) ln -s /other/monitor "$home/.local/bin/monitor" ;;
        file) printf 'keep\n' > "$home/.local/bin/monitor" ;;
    esac
    HOME="$home" DOTFILES_ROOT="$repo" PATH="$tmp/bin:$PATH" \
        bash "$script" > "$tmp/output" 2>&1 || { printf '%s\n' "$(<"$tmp/output")" >&2; fail 'setup failed without a monitor plugin'; }
    if [[ "$kind" == matching ]]; then
        [[ ! -e "$home/.local/bin/monitor" && ! -L "$home/.local/bin/monitor" ]] || fail 'obsolete link retained'
    else
        [[ -e "$home/.local/bin/monitor" || -L "$home/.local/bin/monitor" ]] || fail 'unrelated monitor removed'
    fi
done

# A malformed later entry must not leave earlier dotfiles applied.
for invalid in action missing glob; do
    home="$tmp/preflight-$invalid/home"
    repo="$tmp/preflight-$invalid/repo with spaces"
    mkdir -p "$home" "$repo/omarchy"
    printf 'source\n' > "$repo/omarchy/source"
    printf 'original\n' > "$home/target"
    printf 'file\tomarchy/source\ttarget\n' > "$repo/omarchy/dots-manifest"
    case "$invalid" in
        action) printf 'invalid\tomarchy/source\tother\n' >> "$repo/omarchy/dots-manifest" ;;
        missing) printf 'file\tomarchy/missing\tother\n' >> "$repo/omarchy/dots-manifest" ;;
        glob) printf 'glob\tomarchy/missing*.lua\tother/\n' >> "$repo/omarchy/dots-manifest" ;;
    esac
    if HOME="$home" DOTFILES_ROOT="$repo" PATH="$tmp/bin:$PATH" bash "$script" > "$tmp/output" 2>&1; then
        fail "invalid $invalid manifest accepted"
    fi
    [[ ! -L "$home/target" && "$(<"$home/target")" == original ]] || fail "invalid $invalid manifest changed target"
    [[ ! -e "$repo/backup" ]] || fail "invalid $invalid manifest created backup"
done

echo 'setup-dots without monitor plugin cases passed'
