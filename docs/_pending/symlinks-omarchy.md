# Symlinks — file reference

## Symlink table

| Repo file | Symlink on your system |
| --- | --- |
| `omarchy/config/hypr/hypr.conf` | `~/.config/hypr/hypr.conf` |
| `omarchy/config/waybar/config` | `~/.config/waybar/config` |
| `omarchy/config/alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` |
| `omarchy/config/foot/foot.ini` | `~/.config/foot/foot.ini` |
| `omarchy/home/.zshrc` | `~/.zshrc` |
| `omarchy/bin/omarchy-sync` | `~/.local/bin/omarchy-sync` |

## Creating a symlink

```bash
ln -sf ~/Projects/autanasoft/dotfiles/omarchy/config/hypr/hypr.conf ~/.config/hypr/hypr.conf
```

Format:

```
ln -sf <path-in-repo> <where-you-want-the-symlink>
```

- `ln` — symlink command
- `-s` — symbolic (not a hard link)
- `-f` — force: overwrite if it already exists

## Verifying the symlink

```bash
ls -la ~/.config/hypr/hypr.conf
```

If the first column shows `lrwxrwxrwx`, the symlink is OK. If it shows `-rw-r--r--`, it is a regular file (the symlink was broken).

## If `omarchy refresh` breaks it

`omarchy refresh` replaces symlinks with regular files. To repair:

```bash
rm ~/.config/hypr/hypr.conf
ln -sf ~/Projects/autanasoft/dotfiles/omarchy/config/hypr/hypr.conf ~/.config/hypr/hypr.conf
```

Done.
