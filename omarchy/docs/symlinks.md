# Symlinks and change workflow

How this repo is exposed to the live Omarchy installation, and the
discipline that keeps it in sync.

## The model

**The repository is the source of truth.** The actual files Hyprland,
Alacritty, Zellij, Mako, etc. read at runtime are symlinks pointing
into this repo. The mapping is simple:

| Repo path | Live path |
| --- | --- |
| `omarchy/config/<app>/<file>` | `~/.config/<app>/<file>` (per-env) |
| `omarchy/home/.<dotfile>` | `~/.<dotfile>` |
| `omarchy/bin/<name>` | `~/.local/bin/<name>` (or wherever `$PATH` resolves) |
| `shared/<area>/<files>` | Source for configs shared across both envs (see [Shared layer](#shared-layer)) |

### Shared layer

For configs that are identical (or omarchy-canonical) across both
environments, the symlink chain is two levels deep. The repo has a
`shared/` directory at its root that holds the source of truth for
these configs; each env's `config/<app>/<file>` for shared content is
a symlink into `../shared/<app>/<file>`. The canonical-source rule
(omarchy wins when configs diverge), the env-to-shared mapping, and
the list of files forbidden in `shared/` all live in
[`shared/README.md`](../../shared/README.md).

A typical per-env example, fully expanded:

```
omarchy/config/hypr/looknfeel.conf  ─symlink─►  ~/.config/hypr/looknfeel.conf
```

A typical shared example, fully expanded (two-level chain):

```
shared/zellij/config.kdl
    ▲
    │ symlink
    │
omarchy/config/zellij/config.kdl
    ▲
    │ symlink
    │
~/.config/zellij/config.kdl
```

When Hyprland reads `~/.config/hypr/looknfeel.conf` (or Zellij reads
`~/.config/zellij/config.kdl`), it follows the symlink chain into
the repo. There is exactly one source of truth per file — either in
`omarchy/`, in `shared/`, or in a host-only override — and there is
no copy.

## Why symlinks (not a copy, not stow)

- **Edits take effect immediately.** No `install` step between writing
  the change and seeing the change.
- **Validation is one command.** `hyprctl reload` and `hyprctl configerrors`
  always read the live config, which is always the repo.
- **No drift.** If the symlink exists, the system uses the repo. If
  the symlink is missing, the system uses whatever is at the path
  (which is usually a stock Omarchy file).

The trade-off: `omarchy refresh` and other Omarchy commands that
write to `~/.config/...` will break the symlink by replacing it with a
regular file. See [Repairing broken symlinks](#repairing-broken-symlinks).

## What is in the repo vs what is not

Only files that **diverge from Omarchy defaults** are tracked. Files
that match the defaults (or are pure system data) stay out of the
repo, even if they exist in `~/.config/`.

Example, current state of `~/.config/hypr/`:

| File in `~/.config/hypr/` | Symlinked? | In repo? |
| --- | --- | --- |
| `hyprland.conf` | yes | yes |
| `p-index.conf` | yes | yes (sourced by `hyprland.conf` to apply personal customizations) |
| `p-monitors.conf` | yes | yes |
| `p-looknfeel.conf` | yes | yes |
| `p-bindings.conf` | yes | yes |
| `p-rules.conf` | yes | yes |
| `hypridle.conf` | yes | yes |
| `autostart.conf` | no | no (matches Omarchy default) |
| `envs.conf` | no | no |
| `input.conf` | no | no |
| `hyprlock.conf` | no | no |
| `hyprsunset.conf` | no | no |
| `xdph.conf` | no | no |

The actual Hyprland customizations live in `p-` prefixed files
because Omarchy does not touch `p-` files on `omarchy update`. See
[hypr.md](hypr.md#the-p--prefix-convention) for the full
explanation of the `p-` prefix convention.

To audit the current state at any time:

```bash
cd ~/.config/hypr
for f in *; do
  [ -f "$f" ] || continue
  target=$(readlink "$f")
  if [ -n "$target" ]; then
    echo "SYMLINK: $f -> $target"
  else
    echo "REGULAR: $f"
  fi
done
```

## Change workflow

For any tracked file:

1. Edit the file in the repo. Per-env files live in
   `omarchy/config/.../...` (or `omarchy/home/...` or
   `omarchy/bin/...`). Shared files live in `shared/...` — edit
   them there, not in the per-env symlink target. See the
   [Shared layer](#shared-layer) section above.
2. The symlink chain (one level for per-env files, two levels for
   shared files) makes the edit visible to the live system
   immediately.
3. Reload the affected service. For Hyprland: `hyprctl reload`.
4. Validate: `hyprctl configerrors` (must be empty).
5. Smoke-test the change in the running session.
6. Commit in the repo with a clear conventional-commit message.

For non-Hyprland tools, the reload step varies:

| Tool | Reload command |
| --- | --- |
| Hyprland | `hyprctl reload` (auto-reloads most changes on save too) |
| Waybar | `omarchy restart waybar` (no auto-reload) |
| Walker | `omarchy restart walker` |
| Alacritty | `omarchy restart terminal` |
| Zellij | none needed (config re-read on attach) |
| nvim | `:source` or restart |

## Adding a new tracked file

When Omarchy's default for a file starts to bother you and you want to
override it:

1. **Backup the existing file** (it is the only copy until you
   symlink, and `omarchy refresh` will overwrite it later):

   ```bash
   cp ~/.config/hypr/whatever.conf ~/.config/hypr/whatever.conf.bak.$(date +%s)
   ```

2. **Replace the live file with a symlink to the repo:**

   ```bash
   ln -sf ~/Projects/autanasoft/dotfiles/omarchy/config/hypr/whatever.conf \
           ~/.config/hypr/whatever.conf
   ```

3. **Add the file to the repo** (if not there yet) and make your
   changes. The symlink means the live file is now the repo file.

4. **Validate** with the appropriate reload command and `configerrors`.

5. **Commit** the new tracked file and the symlink replacement is
   just a host-side concern, not a repo concern.

## Adding a new shared file

When a config becomes identical (or omarchy-canonical) across both
environments, move it into `shared/` so both envs can use the same
source of truth:

1. **Choose the right `shared/` path.** The mapping for existing
   shared areas (zellij, nvim, starship, etc.) is documented in
   [`shared/README.md`](../../shared/README.md). For a new area,
   create the directory under `shared/<area>/` and add a row to
   the mapping table.
2. **Move the file** from its env path to the corresponding
   `shared/` path. `git mv` preserves history; a plain `mv` + later
   `git add` is fine too.
3. **Replace the original env path with a symlink** to the new
   `shared/` location. From `omarchy/config/<app>/`:

   ```bash
   ln -s ../../shared/<app>/<file> <file>
   ```

   The relative depth depends on the env's directory tree; use
   `realpath --relative-to=` to compute it.
4. **Repeat the symlink in the other env** if the file is used
   there. For configs that only matter in one env, the file stays
   per-env — do not move it to `shared/`.
5. **Validate** per the change workflow above (reload the affected
   service, smoke-test, etc.).
6. **Commit** the move + symlink creates in a single commit with a
   conventional-commit message like `refactor(<app>): move <file> to
   shared/`.

## Removing a tracked file

If you stop customizing a file and want it to fall back to Omarchy
defaults:

1. Delete the file from the repo.
2. Remove the symlink at the live path so Omarchy can recreate the
   default file there:

   ```bash
   rm ~/.config/hypr/whatever.conf
   omarchy refresh hypr   # or just relaunch Hyprland
   ```

3. Commit the deletion.

## Repairing broken symlinks

`omarchy refresh` (and other Omarchy commands) write to
`~/.config/...` directly, which overwrites a symlink with a regular
file containing the current default. Symptom: a file you have been
editing stops responding to your changes because Hyprland is reading
the regular file, not the symlink.

For shared files the chain has two levels, so a break can happen at
either the env level (`omarchy/config/<app>/<file>`) or, less
commonly, the shared level (`shared/<app>/<file>` itself).

### Detect (per-env file)

```bash
ls -la ~/.config/hypr/whatever.conf
# If it shows "-rw-r--r--" (regular file) instead of "lrwxrwxrwx" (symlink),
# the symlink was broken.
```

### Repair (per-env file)

```bash
# Back up the broken regular file (it might have Omarchy default changes)
cp ~/.config/hypr/whatever.conf ~/.config/hypr/whatever.conf.bak.$(date +%s)

# Re-create the symlink
ln -sf ~/Projects/autanasoft/dotfiles/omarchy/config/hypr/whatever.conf \
        ~/.config/hypr/whatever.conf

# Verify
ls -la ~/.config/hypr/whatever.conf
```

### Detect (shared file)

Check the env-level link first, then the shared target:

```bash
ls -la ~/Projects/autanasoft/dotfiles/omarchy/config/zellij/config.kdl
ls -la ~/Projects/autanasoft/dotfiles/shared/zellij/config.kdl
```

If the env-level path is a regular file, the env-level symlink was
broken. If the shared file itself is missing or modified, the host
touched `shared/` (rare — usually a manual mistake).

### Repair (shared file, env-level break)

```bash
cd ~/Projects/autanasoft/dotfiles/omarchy/config/zellij
# Back up the broken regular file
cp config.kdl config.kdl.bak.$(date +%s)
# Re-create the env-level symlink
ln -sf ../../../shared/zellij/config.kdl config.kdl
ls -la config.kdl
```

### Repair (shared file, shared-level break)

Restore from git (the shared file is a tracked repo file):

```bash
cd ~/Projects/autanasoft/dotfiles
git checkout shared/zellij/config.kdl
```

If you find this happening often, audit which Omarchy commands you
run and whether they can be replaced with a direct edit. Avoid
`omarchy refresh` for files that are symlinked.

## Validating changes

Every change to a Hyprland config file must pass:

```bash
hyprctl reload           # must print "ok"
hyprctl configerrors     # must print nothing
```

If `configerrors` shows anything, fix it before reloading. Common
errors in this repo's history:

- `windowrulev2 is deprecated` — use `windowrule` (0.55+).
- `invalid field center: missing a value` — use `center 1` (explicit
  bool) in 0.55+.

For a windowrule change, the new rule applies only to **newly opened**
windows. Close and reopen the affected app to see the change.
