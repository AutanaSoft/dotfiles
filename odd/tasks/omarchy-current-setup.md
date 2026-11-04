# Omarchy current setup

Branch: omarchy-4.5-personal-config; delivery: no commits; runner: `./tests/run.sh`.

## Specs

- S1: «adaptar el instalador de Omarchy a las configuraciones que existen actualmente en `omarchy/`,
  sin restaurar las que eliminaste ni modificar el perfil Fedora WSL2».
- S2: «Eliminar la fase específica de Omarchy y sus referencias en el coordinador y en la interfaz
  compartida»; «Mantener intacto `--locale` para Fedora WSL2».
- S3: «Revisar dependencias, fuentes y servicios frente a los archivos y herramientas que el perfil
  actual utiliza»; «Corregir el aviso de servicios para que describa también PostgreSQL y Valkey».
- S4: «Comprobar cómo se resuelven `input`, `autostart` y `windows.lua` en la instalación actual»;
  «sin sobrescribir configuraciones personales no gestionadas»; «añadir `require("hypr.windows")` a
  `omarchy/home/config/hypr/hyprland.lua`».
- S5: «Retirar referencias a las funciones Bash, el plugin y `backup-mirror` eliminados»; «Añadir o
  ajustar pruebas aisladas»; «Actualizar la ayuda y la documentación afectadas».
- S6: «sin instalar paquetes ni modificar servicios»; «No haré una instalación real, cambios
  privilegiados, commits ni modificaciones fuera de este alcance».

## Tasks

- T1 [S1 S2 S5 S6] Locale removal and isolated tests; delegated; done; no commit; RED observed,
  Fedora contract passed; full Omarchy suite awaits T2.
- T2 [S1 S3 S4 S5 S6] Check integration, adjust installer, documentation and tests; delegated; done;
  isolated checks and independent verifier passed; no commit.
- T3 [S1 S5 S6] Verify full suite and remaining checks; done; Prettier, markdownlint-cli2, suite and
  diff checks passed; no commit.

## Log

L1: «ok, entonces vamos a ajustar los script de instalacion del perfil de Omarchy para que instale
las configuraciones actuales del prefil de Omarchy. dame el plan de implementacion.» L2: «ok
implementa» L3: Existing user changes and prior edits are preserved. No commits per approved plan.
Forecast exceeds 400 lines only if obsolete tests/docs require extensive adjustments; review scope
remains bounded. L4: T1 RED observed for unsupported locale and obsolete helper; Fedora contract
passed. Removed obsolete tracked helper; Omarchy suite reaches pre-existing missing Bash functions
assertion, addressed in T2. Independent verifier confirmed public rejection and identified remaining
helper before removal. L5: T2 updates installer prompt, isolated tests and documentation; removed
orphaned backup-mirror test and documentation. Full suite passed in parent and independent scratch
verification; Fedora --locale differential matched baseline stdout, stderr and exit. Prettier and
markdownlint-cli2 are unavailable; no installation or privileged operations performed. Independent
native assessment could not assess untracked scope; verifier was run. L6: User authorized reads of
installed bootstrap, input and autostart; bootstrap searches state, config then Omarchy paths; input
and autostart exist. User authorized explicitly adding require("hypr.windows") to the tracked
entrypoint. L7: Added explicit windows require, isolated regression test and documentation. Focused
and complete suites passed; independent verifier confirmed installed links preserve personal
input/autostart in scratch. Real Hyprland reload not run. Markdown formatter and linter unavailable;
no commits or real installation.

L8: User installed Prettier and markdownlint-cli2. Both checks passed on five changed Markdown files
and the full Omarchy/Fedora suite passed again. Native assessment remained unassessable because of
untracked scope; independent verification was performed. No real install or Hyprland reload.
