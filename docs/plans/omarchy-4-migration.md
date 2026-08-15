# Plan de migración a Omarchy 4

## Objetivo

Adaptar el perfil `omarchy` a Omarchy 4.x para que `./setup --profile omarchy --dots-only` aplique
únicamente configuraciones compatibles con el shell Quickshell y con la configuración Lua de
Hyprland.

La migración no dará soporte a temas personalizados. El perfil usará los temas oficiales
proporcionados por Omarchy.

## Alcance

Se revisarán y actualizarán los siguientes componentes:

- `omarchy/dots-manifest`
- `omarchy/home/bashrc`
- `omarchy/home/config/hypr/`
- `omarchy/home/config/omarchy/`
- `omarchy/utils/bash/setup-validate`
- `README.md`
- `docs/setup.md`
- `docs/hypr.md`
- `tests/setup-contract.sh`

Se eliminarán del perfil los archivos asociados a componentes retirados por Omarchy 4:

- `omarchy/home/config/waybar/config.jsonc`
- `omarchy/home/config/hypr/hypridle.conf`
- `omarchy/home/config/omarchy/themes/tokyo-night-autana/`

No se modificarán automáticamente archivos bajo `/usr/share/omarchy/`, configuraciones no
administradas por el manifiesto ni archivos privilegiados bajo `omarchy/etc/`.

## Fase 1: definir el contrato de Omarchy 4

1. Documentar que el perfil `omarchy` requiere Omarchy 4.x y una sesión Hyprland con soporte de
   configuración Lua.
2. Actualizar las referencias de rutas internas:
   - usar `OMARCHY_PATH` y `/usr/share/omarchy`;
   - eliminar referencias a `~/.local/share/omarchy`;
   - documentar `~/.config/omarchy/shell.json` y `shell.toml` como las ubicaciones de
     personalización del shell.
3. Incorporar comprobaciones tempranas antes de aplicar enlaces:
   - disponibilidad de `omarchy`;
   - versión compatible de Omarchy;
   - disponibilidad de `hyprctl` para la validación de sesión.
4. Definir un fallo claro y sin mutaciones para instalaciones Omarchy 3.x o no compatibles.

**Criterio de aceptación:** una instalación no compatible falla antes de crear backups, enlaces o
archivos.

## Fase 2: migrar Hyprland de `.conf` a Lua

1. Sustituir los archivos personales actuales de Hyprland en formato `.conf` por módulos Lua
   compatibles con Omarchy 4:
   - `hyprland.lua`;
   - `monitors.lua`;
   - `bindings.lua`;
   - `looknfeel.lua`;
   - `windows.lua`;
   - `autostart.lua` e `input.lua` solo si contienen configuración propia necesaria.
2. Construir `hyprland.lua` a partir del bootstrap oficial de Omarchy 4:
   - cargar `default.hypr.bootstrap`;
   - cargar `default.hypr.omarchy`;
   - cargar los módulos personales después de los valores por defecto.
3. Migrar la disposición de monitores actual a `hl.monitor(...)` conservando las resoluciones,
   posiciones y escalas declaradas.
4. Migrar preferencias visuales a `hl.config(...)`:
   - `gaps_in` y `gaps_out`;
   - tamaño de borde;
   - redondeo;
   - cualquier preferencia adicional que permanezca activa.
5. Migrar reglas de ventanas a `o.window(...)`, preservando el comportamiento de ventanas flotantes,
   tamaños y reglas PiP.
6. Migrar atajos personales:
   - usar `hl.unbind(...)` únicamente para los atajos vigentes que deban reemplazarse;
   - usar `o.bind(...)` para Zellij, Tmux, navegador privado, editor, Docker y aplicaciones web;
   - sustituir comandos retirados por comandos o APIs documentadas en Omarchy 4;
   - confirmar las clases reales de las aplicaciones antes de codificar reglas o enfoque exclusivo.
7. Actualizar el manifiesto para enlazar módulos `.lua` y dejar de gestionar los archivos `.conf` de
   Hyprland.

**Criterio de aceptación:** `hyprctl reload` y `hyprctl configerrors` terminan sin errores, y los
monitores, atajos, apariencia y reglas se aplican desde los módulos Lua.

## Fase 3: adaptar barra, bloqueo e inactividad al shell

1. Eliminar Waybar del manifiesto y retirar su configuración del repositorio.
2. Eliminar `hypridle.conf`: Omarchy 4 delega la inactividad, el bloqueo, los fondos y los OSD al
   shell Quickshell.
3. Identificar las preferencias personales que deben conservarse:
   - composición y posición de la barra;
   - widgets de reloj, red, audio, batería y área de notificaciones;
   - tiempos de protector de pantalla y bloqueo.
4. Implementar esas preferencias mediante los artefactos compatibles:
   - `~/.config/omarchy/shell.json` para layout y comportamiento;
   - `~/.config/omarchy/shell.toml` para tipografía, espaciado o apariencia persistente.
5. Mantener overrides mínimos para no congelar el layout o las mejoras futuras del shell oficial.

**Criterio de aceptación:** el shell inicia sin Waybar, conserva las preferencias aprobadas y sigue
funcionando después de cambiar a un tema oficial.

## Fase 4: actualizar Bash y terminal

1. Reemplazar la carga heredada de `~/.local/share/omarchy/default/bash/rc` en `omarchy/home/bashrc`
   por el bootstrap de Omarchy 4:

   ```bash
   [[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && \
     source /usr/share/omarchy/default/bash/env-bootstrap
   source "$OMARCHY_PATH/default/bash/rc"
   ```

2. Conservar la carga posterior de `~/.config/bash/rc` para aliases, funciones y variables
   personales.
3. Verificar shells interactivos y no interactivos para asegurar que `OMARCHY_PATH`, el `PATH` y los
   aliases de Omarchy estén disponibles cuando corresponda.
4. Mantener la configuración de Alacritty si continúa importando el tema desde
   `~/.local/state/omarchy/current/theme/alacritty.toml`.

**Criterio de aceptación:** Bash no accede a rutas de Omarchy 3 y conserva los comandos de Omarchy y
la configuración personal.

## Fase 5: actualizar el instalador y la validación

1. Actualizar `omarchy/dots-manifest` para incluir solo archivos compatibles con Omarchy 4.
2. Mantener el comportamiento actual de `setup-dots`: respaldar destinos existentes antes de crear
   enlaces y no modificar el host con `--dry-run`.
3. Eliminar de `setup-validate` la aplicación del tema `tokyo-night-autana`.
4. Adaptar la validación para comprobar:
   - prerequisitos de Omarchy 4;
   - recarga y errores de Hyprland;
   - ausencia de artefactos administrados de Waybar y de rutas Omarchy 3;
   - que no se gestione ningún tema personalizado.
5. Actualizar el texto de ayuda y la documentación para no prometer soporte de temas propios.

**Criterio de aceptación:** `--dots-only --dry-run` solo enumera artefactos compatibles con Omarchy
4 y la validación no aplica ni espera un tema personalizado.

## Fase 6: pruebas y validación

1. Extender `tests/setup-contract.sh` para comprobar:
   - detección de una versión no compatible;
   - manifiesto sin Waybar, `hypridle.conf` ni temas personalizados;
   - presencia y enlace de los módulos Lua esperados;
   - `bashrc` con el bootstrap de Omarchy 4;
   - preservación de las garantías de `--dry-run`.
2. Ejecutar las verificaciones automatizadas:

   ```bash
   bash tests/setup-contract.sh
   ./setup --profile omarchy --dots-only --non-interactive --dry-run
   ```

3. Validar en una sesión Hyprland real, con backup disponible:
   - aplicar `--dots-only`;
   - ejecutar `hyprctl reload`;
   - revisar `hyprctl configerrors`;
   - probar monitores, atajos, reglas de ventana, shell, bloqueo e inactividad;
   - abrir Bash y Alacritty;
   - cambiar entre temas oficiales para confirmar que los overrides sobreviven.

**Criterio de aceptación:** la validación automatizada pasa, la sesión no presenta errores de
configuración y no existe dependencia funcional de componentes retirados ni de un tema
personalizado.

## Riesgos y decisiones

- Los atajos de Omarchy 4 difieren de los de Omarchy 3; cada `hl.unbind(...)` debe verificarse
  frente a los bindings oficiales de la versión instalada.
- Las clases de las aplicaciones pueden haber cambiado; se validarán con `hyprctl clients` antes de
  fijar reglas de ventana.
- La disposición de monitores es específica del host y permanecerá explícita, no se convertirá en un
  valor portátil por defecto.
- Un `shell.json` completo puede impedir mejoras posteriores del shell; se preferirán overrides
  pequeños y documentados.
- El tema personalizado y todos sus recursos se retiran deliberadamente. El perfil dependerá de los
  temas oficiales de Omarchy.

## Fuera de alcance

- Crear, adaptar o administrar temas personalizados.
- Modificar `/usr/share/omarchy/`.
- Instalar Omarchy, modificar particiones o automatizar `fstab`.
- Cambiar las fases de dependencias, fuentes, servicios o locale salvo que la implementación
  descubra una incompatibilidad concreta y documentada.
- Crear commits o modificar archivos locales no relacionados.
