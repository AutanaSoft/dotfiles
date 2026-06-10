# Symlinks — Tabla de archivos

## Tabla de symlinks

| Archivo en el repo | Symlink en tu sistema |
| --- | --- |
| `omarchy/config/hypr/hypr.conf` | `~/.config/hypr/hypr.conf` |
| `omarchy/config/waybar/config` | `~/.config/waybar/config` |
| `omarchy/config/alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` |
| `omarchy/config/foot/foot.ini` | `~/.config/foot/foot.ini` |
| `omarchy/home/.zshrc` | `~/.zshrc` |
| `omarchy/bin/omarchy-sync` | `~/.local/bin/omarchy-sync` |

## Cómo crear un symlink

```bash
ln -sf /home/lcardenas/Projects/autanasoft/dotfiles/omarchy/config/hypr/hypr.conf ~/.config/hypr/hypr.conf
```

Formato:
```
ln -sf <ruta-al-repo> <ruta-donde-quiere-el-symlink>
```

- `ln` — comando de symlink
- `-s` — simbólico (no hard link)
- `-f` — fuerza: sobreescribe si ya existe

## Verificar que está bien

```bash
ls -la ~/.config/hypr/hypr.conf
```

Si muestra `lrwxrwxrwx` al inicio, el symlink está OK. Si muestra `-rw-r--r--`, es un archivo normal ( roto).

## Si `omarchy refresh` lo rompe

`omarchy refresh` reemplaza symlinks con archivos normales. Para reparar:

```bash
rm ~/.config/hypr/hypr.conf
ln -sf /home/lcardenas/Projects/autanasoft/dotfiles/omarchy/config/hypr/hypr.conf ~/.config/hypr/hypr.conf
```

Eso es todo.