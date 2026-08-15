# Hyprland

El perfil Omarchy administra módulos Lua personales para Omarchy 4. Los archivos fuente viven en
`omarchy/home/config/hypr/` y se enlazan en `~/.config/hypr/` mediante `omarchy/dots-manifest`.

Referencia: <https://wiki.hypr.land/Configuring/>

## Requisitos

- Omarchy 4.x.
- Una sesión Hyprland activa.
- `hyprctl` disponible en `PATH` para validar la configuración.

Omarchy carga sus valores por defecto desde `/usr/share/omarchy` a través de `OMARCHY_PATH`. No se
deben modificar los archivos de esa ruta: pertenecen al paquete y se sustituyen al actualizar.

## Recargar y verificar

Después de cada cambio:

```bash
hyprctl reload && hyprctl configerrors
```

La recarga debe terminar sin errores antes de continuar.

## Archivos administrados

| Archivo         | Propósito                                                                               |
| --------------- | --------------------------------------------------------------------------------------- |
| `hyprland.lua`  | Punto de entrada: carga el bootstrap, los valores por defecto y los módulos personales. |
| `monitors.lua`  | Disposición específica de los monitores AOC.                                            |
| `bindings.lua`  | Atajos personales y reemplazos explícitos de atajos oficiales.                          |
| `looknfeel.lua` | Gaps, bordes y redondeo.                                                                |
| `windows.lua`   | Reglas personales de ventanas y PiP.                                                    |

Los módulos se cargan después de `default.hypr.omarchy`, por lo que los cambios propios prevalecen
sin copiar la configuración empaquetada.

## Personalizaciones

Las reglas de `windows.lua` conservan las ventanas flotantes en el tamaño 16:9 personal de 1043×587
para Nautilus, Spotify, Cliamp, Neovim, Alacritty, Discord y las webapps configuradas. Las reglas
PiP amplían el título en español y sobrescriben el tamaño y borde del valor por defecto de Omarchy.

`bindings.lua` solo elimina los atajos oficiales que reemplaza. Antes de añadir un reemplazo,
consulta los bindings de la versión instalada:

```bash
omarchy menu keybindings --print
```

Las clases reales de una aplicación se deben comprobar antes de añadir una regla nueva:

```bash
hyprctl clients
```

## Shell de Omarchy

Waybar, hypridle y hyprlock no forman parte de Omarchy 4. La barra, bloqueo, inactividad, fondos y
OSD pertenecen al shell Quickshell de Omarchy. Este perfil no administra un layout del shell ni
temas personalizados; utiliza los valores y temas oficiales.

## Véase también

- [`AGENTS.md`](../AGENTS.md) — convenciones del repositorio.
- [`plans/omarchy-4-migration.md`](plans/omarchy-4-migration.md) — plan de migración y criterios de
  aceptación.
