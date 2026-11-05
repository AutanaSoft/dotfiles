#!/usr/bin/env bash
set -euo pipefail

script="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)/omarchy/utils/bash/setup-dots"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }
mkdir -p "$tmp/bin"
printf '#!/usr/bin/env bash\n[[ $1 == version ]] && echo 4.5.0\n' > "$tmp/bin/omarchy"
chmod +x "$tmp/bin/omarchy"

for kind in absolute relative dangling dangling-source correct correct-alias file; do
    for mode in dry apply; do
        root="$tmp/$kind-$mode"
        home="$root/home with spaces"
        repo="$root/repo with spaces"
        backup="$root/backup"
        target="$home/target with spaces"
        mkdir -p "$home" "$repo/omarchy" "$backup"
        if [[ "$kind" == dangling-source ]]; then
            ln -s 'missing/one' "$repo/omarchy/source"
        else
            printf 'source\n' > "$repo/omarchy/source"
        fi
        printf 'original\n' > "$home/original file"
        printf 'file\tomarchy/source\ttarget with spaces\n' > "$repo/omarchy/dots-manifest"
        case "$kind" in
            absolute) old="$home/original file"; ln -s "$old" "$target" ;;
            relative) old='original file'; ln -s "$old" "$target" ;;
            dangling) old='missing file'; ln -s "$old" "$target" ;;
            dangling-source) old='missing/two'; ln -s "$old" "$target" ;;
            correct) old="$repo/omarchy/source"; ln -s "$old" "$target" ;;
            correct-alias) old="$repo/omarchy/../omarchy/source"; ln -s "$old" "$target" ;;
            file) printf 'original\n' > "$target" ;;
        esac
        # Even a dangling backup reserves its name; a regular suffix also survives.
        ln -s 'previous missing' "$backup/target with spaces"
        printf 'previous\n' > "$backup/target with spaces.1"
        args=()
        [[ "$mode" != dry ]] || args+=(--dry-run)
        if HOME="$home" DOTFILES_ROOT="$repo" DOTFILES_BACKUP_DIR="$backup" PATH="$tmp/bin:$PATH" \
            bash "$script" "${args[@]}" > "$root/stdout" 2> "$root/stderr"; then
            status=0
        else
            status=$?
        fi
        [[ "$status" == 0 ]] || fail "$kind/$mode exit $status"
        [[ ! -s "$root/stderr" ]] || fail "$kind/$mode unexpected stderr"
        [[ "$(readlink -- "$backup/target with spaces")" == 'previous missing' ]] || fail 'backup link overwritten'
        [[ "$(<"$backup/target with spaces.1")" == previous ]] || fail 'backup file overwritten'
        [[ "$(<"$home/original file")" == original ]] || fail 'referent modified'
        if [[ "$kind" == correct || "$kind" == correct-alias ]]; then
            grep -Fx "[setup-dots] Already linked: $target" "$root/stdout" >/dev/null || fail 'correct link not recognized'
            [[ "$(readlink -- "$target")" == "$old" ]] || fail 'correct link replaced'
            [[ ! -e "$backup/target with spaces.2" && ! -L "$backup/target with spaces.2" ]] || fail 'correct link backed up'
        else
            grep -Fx "[setup-dots] Backing up existing target: $target -> $backup/target with spaces.2" "$root/stdout" >/dev/null || fail "$kind/$mode backup message missing"
            if [[ "$mode" == dry ]]; then
                [[ ! -e "$backup/target with spaces.2" && ! -L "$backup/target with spaces.2" ]] || fail 'dry-run wrote backup'
                if [[ "$kind" == file ]]; then
                    [[ ! -L "$target" && "$(<"$target")" == original ]] || fail 'dry-run changed file'
                else
                    [[ "$(readlink -- "$target")" == "$old" ]] || fail 'dry-run changed link'
                fi
            else
                [[ "$(readlink -- "$target")" == "$repo/omarchy/source" ]] || fail 'new link missing'
                if [[ "$kind" == file ]]; then
                    [[ ! -L "$backup/target with spaces.2" && "$(<"$backup/target with spaces.2")" == original ]] || fail 'file backup changed'
                else
                    [[ -L "$backup/target with spaces.2" && "$(readlink -- "$backup/target with spaces.2")" == "$old" ]] || fail 'original link not preserved'
                fi
                HOME="$home" DOTFILES_ROOT="$repo" DOTFILES_BACKUP_DIR="$backup" PATH="$tmp/bin:$PATH" \
                    bash "$script" > "$root/repeat-stdout" 2> "$root/repeat-stderr" || fail 'repeat failed'
                [[ ! -s "$root/repeat-stderr" ]] || fail 'repeat stderr'
                grep -Fx "[setup-dots] Already linked: $target" "$root/repeat-stdout" >/dev/null || fail 'repeat not idempotent'
                [[ ! -e "$backup/target with spaces.3" && ! -L "$backup/target with spaces.3" ]] || fail 'repeat created backup'
            fi
        fi
    done
done

echo 'setup-dots destination symlink backup cases passed'
