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

| Archivo          | Propósito                                                                               |
| ---------------- | --------------------------------------------------------------------------------------- |
| `hyprland.lua`   | Punto de entrada: carga el bootstrap, los valores por defecto y los módulos personales. |
| `monitors.lua`   | Disposición específica de los monitores AOC.                                            |
| `bindings.lua`   | Atajos personales y reemplazos explícitos de atajos oficiales.                          |
| `looknfeel.lua`  | Gaps, bordes y redondeo.                                                                |
| `windows.lua`    | Reglas personales de ventanas y PiP.                                                    |
| `workspaces.lua` | Layouts persistentes por workspace.                                                     |

Los módulos se cargan después de `default.hypr.omarchy`, por lo que los cambios propios prevalecen
sin copiar la configuración empaquetada.

## Personalizaciones

Las reglas de `windows.lua` conservan las ventanas flotantes en el tamaño 16:9 personal de 1043×587
para Nautilus, Spotify, Cliamp, Neovim, Alacritty, Discord y las webapps configuradas. Las reglas
PiP amplían el título en español y sobrescriben el tamaño y borde del valor por defecto de Omarchy.

El workspace `1` usa el layout `master`: la ventana principal ocupa el 62 % izquierdo y las ventanas
posteriores se apilan equitativamente en el 38 % derecho. Hyprland solo admite `orientation` en las
opciones de `master` por workspace, por lo que `mfact` y `new_status` se definen como valores
globales del layout; solo afectan a otro workspace si este también usa `master`. La regla se carga
después de los layouts dinámicos de Omarchy, por lo que se restablece al recargar Hyprland o iniciar
una nueva sesión. `SUPER + L` puede cambiar el layout durante la sesión actual, pero no persiste los
tamaños ni el árbol de ventanas; Hyprland tampoco los guarda automáticamente.

`bindings.lua` solo elimina los atajos oficiales que reemplaza. Antes de añadir un reemplazo,
consulta los bindings de la versión instalada:

```bash
omarchy menu keybindings --print
```

Las clases reales de una aplicación se deben comprobar antes de añadir una regla nueva:

```bash
hyprctl clients
```

## Resolución del punto de entrada

`hyprland.lua` carga `default.hypr.omarchy` y luego requiere `hypr.monitors`, `hypr.input`,
`hypr.bindings`, `hypr.looknfeel` y `hypr.autostart`. El manifiesto enlaza los módulos `*.lua`
existentes en `omarchy/home/config/hypr/`; en este repositorio están `monitors.lua`, `bindings.lua`,
`looknfeel.lua`, `windows.lua` y `workspaces.lua`, pero no `input.lua` ni `autostart.lua`.

En la instalación actual, el bootstrap busca primero en `state`, después en `config` y finalmente en
las rutas de Omarchy. Los archivos `input` y `autostart` existen en la instalación del usuario, pero
son configuraciones personales no administradas por este repositorio. Ese resultado observado no
constituye una garantía general de portabilidad. No se crean sustitutos ni se sobrescriben esas
configuraciones. `windows.lua` sí forma parte del perfil y `hypr.windows` se carga explícitamente
desde el punto de entrada.

Waybar, hypridle y hyprlock no forman parte de los archivos Omarchy retenidos en este perfil. La
configuración de esos componentes y de los plugins del shell no se instala mediante este manifiesto.

## Véase también

- [`AGENTS.md`](../AGENTS.md) — convenciones del repositorio.
- [`plans/omarchy-4-migration.md`](plans/omarchy-4-migration.md) — plan de migración y criterios de
  aceptación.
