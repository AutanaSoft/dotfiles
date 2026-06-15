# Propuesta SDD: ideas-implementation

## Resumen ejecutivo

Alinear el comportamiento del orquestador `./setup` y de los scripts `scripts/setup-*` con la lectura literal de `ideas.md`. La propuesta y la verificación previas describían un modelo en el que la raíz conduce un pipeline `setup-deps → setup-fonts → setup-<env>`. La corrección arquitectónica — ya adoptada en `design.md` (revisado) y en las decisiones Engram #1377 y #1378 — redefine el límite:

- La raíz es un **despachador delgado**: parsea banderas, valida argumentos, define y exporta las rutas reales que necesitan los otros scripts, registra una trampa para limpiar esas variables y delega en **un solo** script.
- Los scripts de entorno (`scripts/setup-omarchy`, futuro `scripts/setup-fedora`) son **propietarios del flujo completo**: verifican dependencias, instalan fuentes, aplican la configuración de entorno.
- `scripts/setup-deps` **autodetecta** el sistema sondeando los gestores de paquetes disponibles; las banderas `--omarchy` y `--fedora` se conservan como override explícito opcional.

El cambio es estructural, no aditivo. La propuesta anterior queda invalidada en su "Problema" y en su "Alcance"; el delta de OpenSpec, el plan de tareas y el reporte de verificación requieren regeneración.

## Problema

`ideas.md` es claro en dos puntos que la propuesta anterior no refleja:

1. **El setup script es el orquestador y solo debe orquestar.** Debe limitarse a recibir y validar argumentos, inicializar las variables de rutas reales que necesitan los otros scripts y limpiar esas variables al salir. La propuesta anterior describía a `setup` como conductor de pipeline (`setup-deps → setup-fonts → setup-<env>`); esa interpretación es incorrecta.
2. **Los scripts de configuración tienen tres responsabilidades: verificar dependencias, instalar fuentes, configurar el entorno.** La propuesta anterior trataba esas tres responsabilidades como una fase de pre-vuelo en `setup-omarchy`, no como el flujo completo del script de entorno.

Adicionalmente, `scripts/setup-deps` no descubre el sistema: requiere que la raíz le pase una bandera de entorno. Esto fuerza a la raíz a tener conocimiento sobre distribuciones, contradice el límite delgado y vuelve ambiguo el comportamiento de `./setup --deps` cuando no hay bandera de entorno.

## Objetivo

Establecer un único contrato público del comando `./setup` y de los scripts `scripts/setup-*` que cumpla literalmente `ideas.md`:

- Raíz delgada: parsea, valida, exporta rutas reales, atrapa limpieza, despacha a un solo script.
- Scripts de entorno (`scripts/setup-omarchy`, futuro `scripts/setup-fedora`) propietarios del flujo completo.
- `scripts/setup-deps` autodetecta el entorno por gestores de paquetes disponibles; las banderas explícitas se conservan como override opcional.

## Alcance

- Rediseñar el orquestador `setup` para que sea un despachador delgado:
  - Parsea `--omarchy`, `--fedora`, `--fonts`, `--deps`, `--dry-run`, `--help` / `-h` y aplica exclusión mutua entre banderas de entorno.
  - Resuelve y exporta las rutas reales: `DOTFILES_ROOT`, `DOTFILES_ENV`, `DOTFILES_DRY_RUN`, `DOTFILES_BACKUP_DIR` y la nueva `DOTFILES_FONTS_DIR`.
  - Registra `trap 'unset DOTFILES_*' EXIT` para limpiar las cinco variables en cualquier camino de salida.
  - Despacha a exactamente uno: `scripts/setup-omarchy` (cuando `--omarchy` esté presente, con o sin `--fonts` / `--deps` absorbidos), `scripts/setup-fonts` (cuando solo `--fonts`), `scripts/setup-deps` (cuando solo `--deps`), o un mensaje de "no implementado" + `exit 0` para `--fedora` en cualquier combinación.
  - Sin contadores multi-paso, sin helpers `run_deps` / `run_fonts` / `run_env`, sin rama de short-circuit previa para fedora.
- Mover el pipeline completo al script de entorno `scripts/setup-omarchy`:
  - Verifica `omarchy` y `hyprctl` en `PATH`.
  - Invoca `scripts/setup-deps` (que autodetecta) y `scripts/setup-fonts` como sub-procesos, pasando `$DOTFILES_DRY_RUN`.
  - Realiza una pre-vuelo no-mutante sobre `$DOTFILES_FONTS_DIR` (defensa en profundidad para invocación directa).
  - Aplica los symlinks, valida el sistema y emite el resumen "Setup complete".
  - Mantiene su propio contador `TOTAL_STEPS` / `current_step` para las etiquetas `1/N` … `N/N`.
- Modificar `scripts/setup-deps` para autodetectar el entorno:
  - Sondea `yay` → `omarchy`; si no, `pacman` → `omarchy` (con aviso si falta `yay`); si no, `dnf` → `fedora`; si no, `rpm` → `fedora` (con aviso si falta `dnf`); si no, falla con mensaje claro.
  - Conserva `--omarchy` y `--fedora` como override explícito opcional; cuando se pasan, la sonda se omite.
  - Reemplaza el error "elija un entorno" por el nuevo error "no se pudo detectar un gestor de paquetes compatible".
- Actualizar `scripts/setup-fonts` para leer `$DOTFILES_FONTS_DIR` cuando esté definida; en su defecto, mantiene el comportamiento por defecto.
- Reescribir `tests/setup-deps.bash` para reflejar el nuevo encadenamiento y añadir casos de autodetección.
- Reescribir `docs/setup.md` para reflejar el nuevo límite, la matriz de despacho, el contrato de variables exportadas y el comportamiento de autodetección.

## No-alcance

- No crear `scripts/setup-fedora` real; queda como TODO. Esta propuesta prepara el límite, no lo implementa.
- No modificar la estrategia de symlinks (mapa explícito, no carpeta completa).
- No modificar el comportamiento de backup con `DOTFILES_BACKUP_DIR` y el sufijo por colisión.
- No modificar el seeding de `~/.ssh/config` (escritura, no symlink) ni los modos 600/700.
- No modificar el marco de pruebas (stubs, helpers de sandbox, helpers de aserción); solo se ajustan los casos.
- No modificar archivos fuera de `setup`, `scripts/setup-deps`, `scripts/setup-omarchy`, `scripts/setup-fonts`, `tests/setup-deps.bash` y `docs/setup.md`.
- No modificar `AGENTS.md`, `README.md` ni `docs/conventions.md`.

## Capacidades (Capabilities)

Esta propuesta sustituye la capacidad descrita en la propuesta anterior; no introduce una nueva.

| Capacidad | Cambio | Justificación |
| --- | --- | --- |
| `setup-orchestration` | **Reemplazo arquitectónico** (no adición) | El contrato del orquestador y de los scripts de entorno cambia: la raíz se vuelve despachador delgado, los scripts de entorno absorben el flujo completo y `setup-deps` autodetecta el host. Los escenarios de la especificación previa (modo `--deps` exclusivo, fedora no implementado, pre-vuelo) deben regenerarse. |

`setup-orchestration` es el nombre usado en el delta actual (`openspec/changes/ideas-implementation/specs/setup-orchestration/spec.md`) y se conserva para mantener la coherencia con `sdd-spec`. No hay specs base en `openspec/specs/`, por lo que este nombre no entra en conflicto con una capacidad existente.

## Reglas de comportamiento (Quick path)

| Invocación | Raíz hace | Script de entorno hace |
| --- | --- | --- |
| `./setup --omarchy` | Exporta rutas, atrapa limpieza, invoca `scripts/setup-omarchy`, `exit 0` | Verifica deps, instala fuentes, aplica configuración de entorno |
| `./setup --omarchy --fonts` | Igual que `--omarchy` (flag absorbido) | El script de entorno gestiona fuentes |
| `./setup --omarchy --deps` | Igual que `--omarchy` (flag absorbido) | El script de entorno gestiona deps (autodetecta) |
| `./setup --fedora` (cualquier combinación) | Imprime "Fedora env executor no implementado", `exit 0`. Nunca invoca `setup-deps`, `setup-fonts` ni `setup-omarchy` | — |
| `./setup --fonts` | Invoca `scripts/setup-fonts` directamente, `exit 0` | — (idempotente) |
| `./setup --deps` | Invoca `scripts/setup-deps` directamente, `exit 0` | — (autodetecta el host) |
| `--help` / `-h` | Imprime ayuda, `exit 0` | — |
| `--omarchy --fedora` | `exit` distinto de 0 + usage (exclusión mutua) | — |
| Bandera desconocida | `exit` distinto de 0 + usage a stderr | — |
| Sin argumentos | `exit` distinto de 0 + usage | — |

En cualquier ejecución (éxito, error de validación, error propagado del script de entorno), las cinco variables `DOTFILES_*` quedan `unset` antes de retornar, gracias a la trampa `EXIT`.

## Enfoque

1. **Reducir `setup` a un despachador delgado** (≈ −140 / +20 líneas netas). Borrar los helpers de pipeline, el contador `TOTAL_STEPS`, la rama corta de fedora y la sección "Execution order: deps → fonts → env". Añadir `DOTFILES_FONTS_DIR` al export y al `trap`. Centralizar el cómputo de la ruta de fuentes.
2. **Expandir `scripts/setup-omarchy`** (≈ +60 / −5 líneas netas) para que posea el flujo completo: helpers `invoke_setup_deps` / `invoke_setup_fonts` con el mismo estilo de los antiguos `run_deps` / `run_fonts`, contador propio `TOTAL_STEPS` / `current_step`, pre-vuelo sobre `$DOTFILES_FONTS_DIR` y todo el `validate_system` actual.
3. **Añadir autodetección en `scripts/setup-deps`** (≈ +50 / −20 líneas netas) con la función `detect_env()` y la tabla de sondeo descrita en `design.md`. Mantener `--omarchy` / `--fedora` como override explícito opcional.
4. **Centralizar la ruta de fuentes** en `setup` (export) y consumirla en `scripts/setup-fonts` y `scripts/setup-omarchy` (≈ +5 / −2 líneas netas en fonts; lectura en el env).
5. **Reescribir la suite de pruebas** (≈ +60 / −50 líneas netas). Mantener `make_sandbox` y los helpers; ajustar el `TEST_PLAN` a 7, reescribir los casos que dependían del despacho de pipeline desde la raíz y añadir tres sub-casos de autodetección (omarchy, fedora, sin gestores).
6. **Reescribir `docs/setup.md`** (≈ +30 / −25 líneas netas). Quick path, matriz de despacho, contrato de variables exportadas, nota sobre autodetección y override explícito.

El orden de trabajo sigue TDD estricto: tests rojos primero, implementación verde, refactor. La skill `sdd-apply` lo impone.

## Áreas afectadas

- `setup` — despachador delgado.
- `scripts/setup-omarchy` — propietario del flujo de entorno Omarchy.
- `scripts/setup-deps` — autodetección + override opcional.
- `scripts/setup-fonts` — lee `DOTFILES_FONTS_DIR`.
- `tests/setup-deps.bash` — reescritura de casos.
- `docs/setup.md` — reescritura del contrato documentado.

No se introducen archivos ni directorios nuevos. La superficie sigue siendo de seis archivos. `openspec/changes/ideas-implementation/proposal.md` (este archivo) y `design.md` (revisado) son la fuente de verdad; los artefactos derivados (spec, tasks, código, verify report) deben regenerarse a partir de aquí.

## Riesgos

| Riesgo | Mitigación |
| --- | --- |
| Autodetección elige el entorno incorrecto (chroot con `yay` y `dnf`, toolbox Fedora sobre Arch, contenedores con varios gestores) | Conservar `--omarchy` / `--fedora` como override explícito y documentarlo prominentemente en `usage()` y `docs/setup.md`. |
| El script de entorno invoca `setup-fonts` aunque las fuentes ya estén instaladas, duplicando trabajo visible | `setup-fonts` es idempotente; el contador muestra el plan completo. Si resulta ruidoso, el script de entorno puede sondear `$DOTFILES_FONTS_DIR` y omitir con un log "fonts already present". |
| Pérdida de las etiquetas "Step 1/2" / "Step 2/2" en la salida de la raíz para corridas de entorno | El script de entorno emite sus propias etiquetas `1/N` … `N/N`. Aceptable; el contrato se mueve al script de entorno. |
| La raíz delgada puede sentirse infrautilizada; mantenedores podrían reintroducir lógica de pipeline | Añadir un comentario al inicio de `setup` explicando el límite y apuntando a `scripts/setup-omarchy` como plantilla canónica. |
| Regeneración del delta en OpenSpec puede introducir churn en el spec | Aceptable; el delta existe precisamente para registrar el cambio. La especificación previa se archiva en `sdd-archive`. |
| Re-aplicación rompe la suite de pruebas a mitad de camino (los tests se reescriben antes de que la implementación coincida) | TDD estricto: primero los tests rojos, luego la implementación verde, luego refactor. La skill `sdd-apply` lo impone. |
| Conflicto de la variable `DOTFILES_FONTS_DIR` con cualquier otro consumidor | Improbable; el espacio de nombres `DOTFILES_*` es privado del repositorio. Documentar en `usage()`. |
| Confianza del verificador en el nuevo diseño es más difícil de construir (el reporte previo queda invalidado) | Nuevo `verify-report.md` después de la re-aplicación. El reporte anterior se archiva con sufijo `.deprecated-YYYYMMDD.md`. |

## Rollback

- La propuesta anterior (pipeline en raíz) quedó implementada y verificada. Su `verify-report.md` se conserva; se archiva con sufijo `.deprecated-YYYYMMDD.md` cuando se re-aplique.
- Si la autodetección falla en producción, el override explícito (`scripts/setup-deps --omarchy` o `--fedora`) sigue siendo válido.
- Si la raíz delgada rompe un consumidor externo, `git revert` del commit del orquestador restaura el comportamiento anterior (sin afectar a los scripts de entorno, que mantienen su flujo interno).
- En el peor caso, `git revert` del PR completo devuelve al estado previo; la documentación y los tests se revierten juntos.

## Criterios de éxito

- [ ] `./setup --help` lista `--omarchy`, `--fedora`, `--fonts`, `--deps`, `--dry-run`, `--help` / `-h` y describe el límite delgado.
- [ ] `./setup --omarchy` invoca `scripts/setup-omarchy` exactamente una vez.
- [ ] `scripts/setup-omarchy` invoca `scripts/setup-deps` y `scripts/setup-fonts` como sub-procesos antes de aplicar la configuración de entorno.
- [ ] `./setup --fedora` (cualquier combinación) imprime el mensaje de "no implementado" y sale `0`, sin invocar `setup-deps`, `setup-fonts` ni `setup-omarchy`.
- [ ] `./setup --fonts` invoca `scripts/setup-fonts` directamente.
- [ ] `./setup --deps` invoca `scripts/setup-deps` directamente; `setup-deps` autodetecta el entorno por gestores de paquetes.
- [ ] `scripts/setup-deps` sin flag de entorno y con `yay` o `pacman` en `PATH` usa la lista Omarchy.
- [ ] `scripts/setup-deps` sin flag de entorno y con `dnf` o `rpm` en `PATH` usa la lista Fedora.
- [ ] `scripts/setup-deps` sin gestor detectable falla con un mensaje claro y código distinto de 0.
- [ ] `scripts/setup-deps --omarchy` y `--fedora` siguen siendo overrides válidos.
- [ ] `scripts/setup-fonts` lee `DOTFILES_FONTS_DIR` cuando está definida.
- [ ] Después de cualquier ejecución (éxito, error, validación), `printenv | grep '^DOTFILES_'` no devuelve ninguna variable del orquestador.
- [ ] `bash tests/setup-deps.bash` es 7/7 verde.
- [ ] `docs/setup.md` describe el nuevo límite, el contrato de variables y la autodetección, sin contradicciones con el código.

## Preguntas abiertas

Ninguna con efecto bloqueante. Los detalles de implementación (formato exacto de los mensajes, granularidad del sondeo, formato del contador de pasos del script de entorno) se resuelven en la fase `sdd-spec` o `sdd-design`.

## Artefactos a regenerar

Esta propuesta sustituye el modelo descrito en los artefactos previos. Los siguientes quedan obsoletos y deben regenerarse en fases posteriores:

| Artefacto | Acción | Motivo |
| --- | --- | --- |
| `openspec/changes/ideas-implementation/specs/setup-orchestration/spec.md` | Regenerar con `sdd-spec` | El escenario "modo `--deps` exclusivo" se redefine; la "pre-vuelo" se expande a "scripts de entorno propietarios del flujo completo"; la regla de precedencia cambia; nuevo requisito: autodetección de entorno en `setup-deps`; nuevo requisito: export y limpieza de `DOTFILES_FONTS_DIR`. |
| `openspec/changes/ideas-implementation/tasks.md` | Regenerar con `sdd-tasks` | El plan previo de 4 tareas describía el pipeline en raíz. Las nuevas tareas incluyen: reducción de la raíz, expansión del script de entorno, autodetección en `setup-deps`, override de ruta de fuentes, reescritura de tests, reescritura de docs. |
| Implementación (`setup`, `scripts/setup-deps`, `scripts/setup-omarchy`, `scripts/setup-fonts`, `tests/setup-deps.bash`, `docs/setup.md`) | Re-aplicar con `sdd-apply` | Cambios estructurales descritos en `design.md` (revisado). TDD estricto. |
| `openspec/changes/ideas-implementation/verify-report.md` | Re-verificar después de re-aplicar | El reporte actual documenta la arquitectura deprecada. Archivar con sufijo `.deprecated-YYYYMMDD.md` y producir uno nuevo tras la re-aplicación. |

## Archivos relevantes

- `setup` — orquestador delgado.
- `scripts/setup-omarchy` — flujo completo de entorno Omarchy.
- `scripts/setup-deps` — autodetección + override.
- `scripts/setup-fonts` — lee `DOTFILES_FONTS_DIR`.
- `tests/setup-deps.bash` — reescritura de casos.
- `docs/setup.md` — reescritura del contrato documentado.
- `ideas.md` — entrada de la exploración, fuente de las decisiones arquitectónicas.
- `openspec/changes/ideas-implementation/design.md` — diseño revisado, alineado con esta propuesta.
- Decisiones Engram #1377 y #1378 — fuente de las decisiones arquitectónicas.
