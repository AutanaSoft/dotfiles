# Propuesta: repo-structure-omarchy-reorg

> **Bloqueo de alcance** (confirmado por el usuario el 2026-06-18, post-`omarchy-only-scope`):
> el layout de nivel superior del repo de dotfiles se reestructura para
> coincidir con el contrato ya documentado en `docs/conventions.md` (el spec)
> y para cerrar el drift entre el spec y el layout real en disco. Cinco
> forks abiertos de la fase de explore fueron resueltos por el usuario;
> esta propuesta codifica esas resoluciones como decisiones concretas y
> bloqueadas.

## Por qué

Después de que `omarchy-only-scope` se mergeó, la carpeta wrapper `omarchy/`
se convirtió en un prefijo de un solo env que no agrega información. La
carpeta `shared/` (la capa de fuente canónica para herramientas compartidas:
nvim/LazyVim, Zellij, Starship) es accesible desde un único env vía
symlinks relativos en `omarchy/config/{nvim,zellij,starship.toml} → ../../shared/...`,
así que la indirección del wrapper es pura ceremonia. Mientras tanto,
`docs/conventions.md` (la fuente de verdad para el layout del repo) ya
documenta la forma plana objetivo: `home/`, `config/`, `bin/`, `docs/`,
`shared/`, `scripts/`. El repo actualmente envuelve las primeras tres en
`omarchy/{home,config,local,bin}` más un subfolder `home/.config/`
sin usar — drift puro entre el spec y la implementación.

El reorg cierra ese drift. La nueva forma es `src/{home/{config,local},etc/}`:
`src/home/config/` es el nuevo hogar del config ligado a `~/.config/`
(absorbiendo la indirección de `omarchy/config/` y `shared/`),
`src/home/local/` es el nuevo hogar del contenido ligado a `~/.local/share/`
(bin/, ...), y `src/etc/` está reservado para configs de sistema en `/etc/`
que requieren sudo. Los scripts de setup se mueven a `src/utils/bash/`.
El wrapper `omarchy/` se elimina. `docs/conventions.md` se convierte en
el layout real (no se necesita editar el doc para la tabla de alto nivel
— solo los ejemplos de paths específicos necesitan actualizarse para
coincidir).

## Qué cambia

| Tipo | Path | Notas |
| --- | --- | --- |
| Movido | `omarchy/config/*` | → `src/home/config/`. Aplica a `alacritty/`, `hypr/`, `mako/`, `nvim/`, `omarchy/{hooks,themes}/`, `tmux/`, `waybar/`. |
| Eliminado (indirección absorbida) | `omarchy/config/nvim` (symlink) | `shared/nvim` se mueve a `src/home/config/nvim` (el target del symlink se convierte en carpeta real). |
| Eliminado (indirección absorbida) | `omarchy/config/zellij` (symlink) | `shared/zellij` se mueve a `src/home/config/zellij`. |
| Eliminado (indirección absorbida) | `omarchy/config/starship.toml` (symlink) | `shared/starship.toml` se mueve a `src/home/config/starship.toml`. |
| Movido | `omarchy/home/.bashrc` | → `src/home/.bashrc` (top de `src/home/`, no en `src/home/config/`). |
| Movido | `omarchy/local/bin/monitor` | → `src/home/local/bin/monitor` (nota: no es symlink, manual-only — ver nota de `apply_symlinks`). |
| Movido | `shared/home/.ssh/config` | → `src/home/.ssh/config` (la excepción del template SSH se mueve con él). |
| Movido | `omarchy/home/.config/keyd/default.conf` | → `src/etc/keyd/default.conf` (config de sistema; nuevo tier `src/etc/`; patrón de install preservado). |
| Movido | `omarchy/README.md` | → `src/README.md` (nombre env-free). Actualiza su tabla de paths gestionados. |
| Eliminado | `omarchy/` (wrapper) | `git rm -r omarchy/`. La superficie histórica queda en `git log`. |
| Eliminado | `shared/` (carpeta) | Absorbida en `src/home/config/`. |
| Renombrado + Movido | `scripts/setup-omarchy` | → `src/utils/bash/setup-dots` (el nuevo nombre refleja el alcance dotfiles, no el alcance env). |
| Movido | `scripts/setup-deps` | → `src/utils/bash/setup-deps` (nombre sin cambio). |
| Movido | `scripts/setup-fonts` | → `src/utils/bash/setup-fonts` (nombre sin cambio). |
| Renombrado + Movido | `scripts/cleanup-omarchy` | → `src/utils/bash/cleanup` (nombre env-free; cleanup no es específico de Omarchy). |
| Eliminado | `scripts/` (carpeta) | Absorbida en `src/utils/bash/`. |
| Modificado | `setup` (dispatcher raíz) | Vars de path: `SCRIPTS_DIR=$DOTFILES_ROOT/src/utils/bash`. Flag rename: `--omarchy` → `--dots`. Se queda en raíz. |
| Eliminado | `omarchy/config/mako/.gitkeep` | Omarchy provee los defaults; el directorio está vacío. |
| Eliminado | `omarchy/config/omarchy/hooks/.gitkeep` | Vacío. |
| Eliminado | `omarchy/config/omarchy/themes/.gitkeep` | `themes/tokyo-night-autana/` es el único contenido; no se necesita placeholder. |
| Modificado | `omarchy/config/tmux/tmux.conf` | KEEP as-is (no rename, no move del archivo en sí). Agregar un comment `# Reason:` al inicio explicando que es un placeholder para el futuro config personal de tmux (el contenido actual es el default de Omarchy) y que el archivo se rastrea intencionalmente para mantener vivo el symlink. |
| Movido | `docs/ideas/scripts/cleanup.md` | → `docs/cleanup.md` (cleanup ya no es omarchy-specific; sale de la carpeta scratch `ideas/`). |
| Modificado (delta) | `openspec/specs/setup-orchestration/spec.md` | Actualizar referencias de path: `scripts/setup-omarchy` → `src/utils/bash/setup-dots`; `scripts/setup-deps` y `scripts/setup-fonts` → `src/utils/bash/{setup-deps,setup-fonts}`; `omarchy/config/*` → `src/home/config/*`; `omarchy/home/.config/keyd/default.conf` → `src/etc/keyd/default.conf`; el callout de `apply_symlinks` se actualiza al nuevo path; la cross-ref a cleanup-omarchy (si existe) se actualiza a `src/utils/bash/cleanup`. |
| Modificado | `openspec/config.yaml` | Actualizar el bloque `context:` para reflejar `src/{home/{config,local},etc/}` + `src/utils/bash/`. |
| Modificado | `README.md` | Actualizar la tabla de repo-layout: `<env>/home/.<dotfile>` → `src/home/.<dotfile>`; `<env>/config/<app>/` → `src/home/config/<app>/`; `<env>/bin/<name>` → `src/home/local/bin/<name>`; `scripts/` → `src/utils/bash/`; `omarchy/README.md` → `src/README.md`. |
| Modificado | `AGENTS.md` | Aplicar la corrección de la línea 55: el texto actual "Hyprland / Mako / Waybar / Walker configs (omarchy-only, not shared)" está mal — esos configs SÍ están en el repo bajo `omarchy/config/{hypr,waybar,mako}/`. Reescribir la lista de Forbidden Paths con la nueva estructura (`src/etc/` para configs de sistema; `~/.local/share/omarchy/` para contenido gestionado por el instalador; la excepción SSH bajo `src/home/.ssh/`). Actualizar la sección "Main tools" para apuntar a `src/home/config/`. Actualizar la regla "Setup entrypoint": "Env executors: `src/utils/bash/setup-<env>`" → "Env executors: `src/utils/bash/setup-dots`" (single-env, sin sufijo `<env>`). |
| Modificado | `docs/conventions.md` | Actualizar ejemplos de path (la tabla de layout ya está alineada con la nueva forma; solo los ejemplos de path específicos necesitan el rename). La tabla "Repo layout": `home/` → `src/home/.<dotfile>`; `config/` → `src/home/config/`; `bin/` → `src/home/local/bin/`. La tabla "Source of truth" necesita lo mismo. La sección "Adding a new environment" es no-op (single env ahora). |
| Modificado | `docs/shared-layer.md` | Heading: `# shared/ layer` → `# src/home/config layer` (o `# canonical-config layer`). El diagrama del modelo de symlinks `~/.config/<x>/<f> → <env>/config/<x>/ → ../../shared/<x>/` se convierte en `~/.config/<x>/<f> → src/home/config/<x>/`. La columna env-path de la tabla "Mapping" se convierte en el path `src/home/config/`. La sección "Adding a new environment" se elimina. La excepción del template SSH se mueve para apuntar a `src/home/.ssh/config`. La excepción de keyd se mueve para apuntar a `src/etc/keyd/default.conf`. |
| Modificado | symlinks vivos `omarchy/config/hypr/*` | Re-point atómico: `~/.config/hypr/{hyprland,hypridle,p-*.conf}` deben re-apuntar de `omarchy/config/hypr/<file>` a `src/home/config/hypr/<file>`. Constraint del apply phase — ver "Approach" abajo. |
| Modificado | symlinks vivos `~/.config/{alacritty,waybar,nvim,zellij,omarchy/themes,starship.toml}` + `~/.bashrc` | Re-point atómico. |
| Intacto | `openspec/changes/archive/*` | Preservado por la política de archive de SDD. |
| Intacto | `openspec/changes/cleanup-omarchy/` | Change activo no relacionado; no es parte de este reorg. |
| Intacto | `backup/` | La carpeta de backup per-run se deja intacta; los logs viejos son históricos. |

## Capabilities

### Nuevas capabilities

- `src-etc-install`: un nuevo install path pequeño para `/etc/keyd/default.conf` y cualquier futuro config de `/etc/`. Actualmente un archivo; la fase de design documenta el patrón (copia con privilegios, modo `0644`, source bajo `src/etc/`, sin symlink). Es una capability fina, scoped al install de keyd que ya existe en `setup-omarchy` (ahora `setup-dots`).

### Capabilities modificadas

- `setup-orchestration`: el contrato de path se actualiza — `SCRIPTS_DIR` resuelve a `src/utils/bash/`, el mapa de `apply_symlinks` en el env script apunta a `src/home/config/...`, el install de keyd apunta a `src/etc/keyd/default.conf`, el template SSH apunta a `src/home/.ssh/config`. El contrato de flags, el contrato de env-vars, y la superficie de tests TAP quedan sin cambio. `cleanup-omarchy` se renombra a `cleanup` en las cross-refs.

## Approach

La fase de apply es el meollo de este cambio. El approach prioriza
**seguridad sobre atomicidad**: en vez de hacer un `git mv` directo de los
archivos de datos (que removería los paths viejos y dejaría los symlinks
vivos apuntando a nada entre el move y la edición de scripts), la apply
phase sigue un patrón de **shadow copy** — copia primero a paths shadow,
edita los scripts para que apunten a los shadows, re-apunta los symlinks
vivos con el setup script (verificando), y solo al final hace el commit
atómico del rename (shadow → final) y la limpieza de los paths viejos.
Cada paso es independientemente reversible: si algo falla, los archivos
viejos siguen existiendo como fallback y el working tree queda en un
estado conocido y recuperable. Si el setup run rompe algo, los symlinks
vivos siguen apuntando a `omarchy/...` y el sistema sigue funcionando.

**Decisión (bloqueada)**: shadow copy approach. Los work units del apply
phase ejecutan en este orden — shadow copy + diff verify, edición de
scripts apuntando a paths shadow, dry-run del setup script, run real con
verificación de symlinks + `hyprctl configerrors`, `git mv` shadow →
final + `git rm -r` de los paths viejos (commit atómico), ediciones de
docs/config, y verify final.

Work units (secuenciados; cada uno completable en una sesión):

1. **WU-1: Shadow copy + diff verify (sin tocar el sistema vivo).**
   - `cp -a omarchy/config src/home/config-shadow`.
   - `cp -a omarchy/home/.bashrc src/home/.bashrc-shadow`.
   - `cp -a omarchy/local src/home/local-shadow`.
   - `cp -a shared/home/.ssh src/home/.ssh-shadow`.
   - `cp -a shared/nvim src/home/config-shadow/nvim` (los `cp` anidados meten el contenido de `shared/<x>` dentro del shadow).
   - `cp -a shared/zellij src/home/config-shadow/zellij`.
   - `cp -a shared/starship.toml src/home/config-shadow/starship.toml`.
   - `cp -a omarchy/home/.config/keyd src/etc-shadow/keyd`.
   - `cp -a omarchy/README.md src/README-shadow.md`.
   - **Symlinks relativos**: `omarchy/config/{nvim,zellij,starship.toml}` son symlinks (no directorios). NO se copian con `cp -a` (que los copiaría como symlinks colgantes, porque sus targets `../../shared/...` se están moviendo). Los targets reales ya están en `shared/{nvim,zellij,starship.toml}` y se copiaron arriba a `src/home/config-shadow/...`. Eliminar los symlinks viejos del filesystem con `rm` (NO `git rm` todavía — el commit viene en WU-4).
   - `rm omarchy/config/mako/.gitkeep omarchy/config/omarchy/hooks/.gitkeep omarchy/config/omarchy/themes/.gitkeep` (en el filesystem, no en git todavía).
   - Verificación: `diff -r omarchy/config src/home/config-shadow` debe mostrar solo diferencias esperadas (los symlinks que se eliminaron, los `.gitkeep` que se removieron). `diff -r omarchy/home/.config/keyd src/etc-shadow/keyd` debe ser idéntico.
   - **No tocar el sistema vivo**: este WU no hace `git add`, `git rm`, ni modifica symlinks vivos. Working tree tiene paths viejos y shadows en paralelo.

2. **WU-2: Editar scripts (apuntar a paths shadow).**
   - Editar `src/home/config-shadow/tmux/tmux.conf` para agregar el comment `# Reason:` (esto es dentro del shadow; el archivo viejo queda intacto hasta WU-4).
   - Mover `docs/ideas/scripts/cleanup.md` → `docs/cleanup.md` (en raíz; este cambio no afecta symlinks vivos).
   - Editar `scripts/setup-omarchy` para que `apply_symlinks()` apunte a `src/home/config-shadow/...` en vez de `omarchy/config/...`.
   - Editar `scripts/setup-omarchy` para que el path del install de keyd apunte a `src/etc-shadow/keyd/default.conf`.
   - Editar `scripts/setup-omarchy` para que el path del template SSH apunte a `src/home/.ssh-shadow/config`.
   - Editar el comment de `monitor` para que apunte a `src/home/local-shadow/bin/monitor` (en WU-4 se mueve a `src/home/local/bin/monitor`).
   - Sin tocar `setup` (raíz) todavía — el rename de `scripts/` viene en WU-4.

3. **WU-3: Live re-point (dry-run + real + verify).**
   - **Dry-run**: `bash scripts/setup-omarchy --dry-run` (con los scripts editados en WU-2; los paths apuntan a shadow). Verificar que el dry-run lista los 14 symlinks esperados apuntando a `src/home/config-shadow/...`.
   - **Run real**: `bash scripts/setup-omarchy`. La función `apply_symlinks()` es idempotente — cada `ensure_symlink` chequea si el symlink existe y apunta al lugar correcto; si apunta al viejo (`omarchy/...`), lo reemplaza con el nuevo (`src/home/config-shadow/...`). Después del run, los 14 symlinks vivos apuntan a los paths shadow (más `src/home/.bashrc-shadow`, `src/home/.ssh-shadow/config`, `src/etc-shadow/keyd/default.conf` para los casos especiales).
   - **Verificación**:
     - `readlink -f ~/.config/{nvim,zellij,hypr/{hyprland,hypridle,p-*},waybar,alacritty,omarchy/themes/tokyo-night-autana,starship.toml} ~/.bashrc` debe resolver a paths shadow.
     - `cat /etc/keyd/default.conf` debe matchear `src/etc-shadow/keyd/default.conf` (bit-identical; modo `0644`).
     - `cat ~/.ssh/config` debe tener el contenido del template (copy-only-if-missing semantics; si ya existía, no se sobreescribe).
     - `hyprctl reload && hyprctl configerrors` debe estar vacío.
   - **Si falla**: borrar los shadows (`rm -r src/home/config-shadow src/home/.bashrc-shadow src/home/local-shadow src/home/.ssh-shadow src/etc-shadow src/README-shadow.md`), revertir las ediciones de scripts. Los symlinks vivos quedan intactos apuntando a `omarchy/...` (sistema funcionando).

4. **WU-4: Atomic commit (rename shadow → final + rm viejos).**
   - `git mv src/home/config-shadow src/home/config`.
   - `git mv src/home/.bashrc-shadow src/home/.bashrc`.
   - `git mv src/home/local-shadow src/home/local`.
   - `git mv src/home/.ssh-shadow src/home/.ssh`.
   - `git mv src/etc-shadow src/etc`.
   - `git mv src/README-shadow.md src/README.md`.
   - `git mv scripts/setup-omarchy src/utils/bash/setup-dots` + editar docstring/usage.
   - `git mv scripts/setup-deps src/utils/bash/setup-deps` (sin body change).
   - `git mv scripts/setup-fonts src/utils/bash/setup-fonts` (sin body change).
   - `git mv scripts/cleanup-omarchy src/utils/bash/cleanup` + editar docstring/usage.
   - `git rm -r scripts/` (ahora vacío).
   - Actualizar las paths en `src/utils/bash/setup-dots` (que ya está editado en WU-2 con paths shadow): cambiar `src/home/config-shadow/...` → `src/home/config/...`, `src/etc-shadow/...` → `src/etc/...`, `src/home/.ssh-shadow/...` → `src/home/.ssh/...`, `src/home/local-shadow/...` → `src/home/local/...`.
   - Actualizar `setup` (raíz): `SCRIPTS_DIR="$DOTFILES_ROOT/scripts"` → `SCRIPTS_DIR="$DOTFILES_ROOT/src/utils/bash"`. Flag rename: `--omarchy` → `--dots` en el docstring y usage text.
   - `git rm omarchy/config/{nvim,zellij,starship.toml}` (los symlinks que se eliminaron del filesystem en WU-1).
   - `git rm -r omarchy/` (wrapper, ahora vacío o casi).
   - `git rm -r shared/` (ya absorbido en el shadow).
   - **Verificación post-commit**: `git ls-files | grep -E '^(omarchy|shared|scripts)/'` debe devolver vacío. `readlink -f ~/.config/...` debe seguir resolviendo (los symlinks siguen apuntando a los paths shadow, que ahora son `src/home/config/...` por el rename).

5. **WU-5: Doc/config edits + verify final.**
   - `README.md`: tabla de repo-layout.
   - `AGENTS.md`: corrección de la línea 55 + nueva regla "Setup entrypoint".
   - `docs/conventions.md`: ejemplos de path.
   - `docs/shared-layer.md`: rename del heading; diagrama; columna env-path.
   - `docs/setup.md`, `docs/hypr.md`, `docs/starship.md`, etc.: path references actualizadas.
   - `src/README.md`: managed-paths table actualizada.
   - `openspec/config.yaml`: bloque `context:`.
   - Spec delta: `openspec/changes/repo-structure-omarchy-reorg/specs/setup-orchestration/spec.md`.
   - **Verify final**:
     - TAP: `bash tests/setup-deps.bash` (sin cambio; `TEST_PLAN=5` de `omarchy-only-scope`).
     - Hyprland: `hyprctl reload && hyprctl configerrors` (vacío).
     - Symlinks: `readlink -f` sobre los 14 paths.
     - El apply report documenta la secuencia de shadow copy + live re-point y la verificación de no-rotura del sistema vivo.

## Áreas afectadas

| Área | Impacto | Descripción |
| --- | --- | --- |
| `src/home/config/*` | Nuevo | Hogar canónico del config ligado a `~/.config/` (absorbe `omarchy/config/` + `shared/`). |
| `src/home/.bashrc` | Nuevo | El dotfile de nivel home se mueve fuera de `omarchy/home/`. |
| `src/home/local/bin/monitor` | Nuevo | El script personal `~/.local/bin/monitor` (manual-only). |
| `src/home/.ssh/config` | Nuevo | El template seguro de SSH se mueve con la excepción SSH. |
| `src/etc/keyd/default.conf` | Nuevo | El config de keyd se mueve a un tier de config de sistema; patrón de install preservado. |
| `src/utils/bash/setup-dots` | Renombrado + Movido | Antes `scripts/setup-omarchy`. |
| `src/utils/bash/setup-deps` | Movido | Nombre sin cambio. |
| `src/utils/bash/setup-fonts` | Movido | Nombre sin cambio. |
| `src/utils/bash/cleanup` | Renombrado + Movido | Antes `scripts/cleanup-omarchy`. |
| `src/README.md` | Renombrado + Movido | Antes `omarchy/README.md`. Tabla de managed-paths actualizada. |
| `setup` (raíz) | Modificado | `SCRIPTS_DIR` resuelve a `src/utils/bash/`. Flag rename: `--omarchy` → `--dots`. |
| `omarchy/`, `shared/`, `scripts/` | Eliminados | Hard removal; la superficie histórica queda en `git log`. |
| 14 symlinks vivos | Re-apuntados | WU-3 re-apunta a paths shadow; WU-4 hace el rename shadow → final. |
| `docs/*` | Modificados | Ejemplos de path actualizados a la nueva forma. |
| `AGENTS.md` | Modificado | Corrección de la línea 55 + nueva regla "Setup entrypoint". |
| `README.md` | Modificado | Tabla de repo-layout. |
| `openspec/specs/setup-orchestration/spec.md` | Modificado (delta) | Referencias de path en los scenarios existentes. |
| `openspec/config.yaml` | Modificado | Bloque `context:`. |
| `openspec/changes/archive/*` | Intacto | Política de archive. |
| `openspec/changes/cleanup-omarchy/` | Intacto | Change activo no relacionado. |
| `backup/` | Intacto | Los logs viejos son históricos. |

## Riesgos

| Riesgo | Probabilidad | Mitigación |
| --- | --- | --- |
| Los symlinks vivos se rompen durante el apply phase: un `git mv` naive deja `~/.config/...` apuntando a paths inexistentes entre el move y el re-point del symlink. | Alta | Shadow copy approach: WU-1 copia a paths shadow sin tocar el sistema vivo, WU-3 re-apunta los symlinks vivos con el setup script mientras los archivos viejos en `omarchy/` siguen existiendo como fallback, WU-4 hace el commit atómico del rename (`git mv` shadow → final + `git rm -r` viejos). Cada paso es independientemente reversible. Si WU-3 rompe algo, los symlinks vivos se re-apuntan a `omarchy/...` y el sistema sigue funcionando. La fase de verify assertea `readlink -f` en cada symlink post-commit. |
| Tres symlinks relativos (`omarchy/config/{nvim,zellij,starship.toml}` → `../../shared/...`) tienen que eliminarse como parte del move. | Med | En WU-1 el `cp -a` NO copia los symlinks relativos (sus targets `../../shared/...` se están moviendo, así que quedarían colgantes). Los symlinks mismos se eliminan del filesystem con `rm` (no `git rm` todavía). Los targets reales de `shared/` se copian a `src/home/config-shadow/...` y luego se mueven a `src/home/config/` en WU-4. WU-4 hace `git rm` sobre los symlinks para sacarlos del index. La fase de verify grepea por `../../shared/` en el working tree para confirmar que ninguno sobrevive. |
| `apply_symlinks()` en el nuevo `src/utils/bash/setup-dots` se actualiza en un solo lugar; un string de path viejo en un sub-paso saltaría silenciosamente un symlink. | Med | El diff en WU-2 cubre cada referencia `$REPO_ROOT/omarchy/...` en el script. WU-4 actualiza los paths shadow → final. La fase de verify corre el script y assertea que cada target symlink existe con el `readlink -f` correcto. |
| La función `apply_symlinks()` en el viejo `scripts/setup-omarchy` es el único generador de path existente; perderse uno (ej. `~/.config/omarchy/themes/tokyo-night-autana`) significa un setup silenciosamente parcial. | Baja | La fase de verify enumera los 14 symlinks conocidos y assertea que cada uno está presente post-commit. Un grep por `REPO_ROOT/omarchy` en el nuevo script debe devolver cero hits (también `REPO_ROOT/src/home/config-shadow` debe devolver cero hits post-WU-4). |
| El comment `# Reason:` de `tmux.conf` enmarca mal el propósito del archivo. La resolución confirmada por el usuario (Fork #4) dice "KEEP as-is (byte-identical to Omarchy default)"; en realidad el archivo son ~97 líneas de config personal (prefix, vi-mode, status bar, theme). | Med | El apply phase re-lee el archivo antes de agregar el comment; si el archivo NO es byte-idéntico al default de Omarchy (que es lo que sugiere el contenido rastreado actual), el comment se amendea para reflejar el estado real ("personal tmux config, kept for the live symlink; no env-script changes"). La propuesta registra esta discrepancia como un check de verify-time. |
| La corrección de la línea 55 de `AGENTS.md` se pierde (o se aplica en la línea incorrecta). | Baja | El diff se chequea con grep: el apply report lista la línea exacta en el `AGENTS.md` post-change y el verify report grepea por el nuevo contenido de Forbidden Paths. |
| La semántica del prefix `p-` se rompe bajo el nuevo path: el `omarchy update` de Omarchy busca archivos con prefix `p-` en `~/.config/hypr/`, no bajo ningún path del repo; el target del symlink no importa. | Ninguna | Sin cambios a la cadena de symlinks. Los archivos `p-` viven bajo `src/home/config/hypr/` pero siguen apareciendo en `~/.config/hypr/p-*.conf` vía el mismo patrón de symlinks per-file de `apply_symlinks()`. El updater de Omarchy nunca ve el path del repo. |
| `docs/conventions.md` ya documenta la forma objetivo; una edición de doc over-eager cambia el spec en vez de alinear la implementación. | Med | Las ediciones de doc en WU-5 son solo de path (sin nuevas reglas de layout). La tabla "Repo layout" se actualiza para apuntar a la nueva forma de path; el texto de las reglas (single env, 2sp default, 4sp KDL/shell/Hyprland, `# Reason:` para remociones) queda sin cambio. |
| Los changes archivados todavía referencian los paths viejos `omarchy/`; futuros lectores pueden malinterpretar el contrato actual. | Baja | El scope cut ya se registró en el verify-report de `omarchy-only-scope` (2026-06-18). El reorg agrega un párrafo de nota en el verify-report de este change explicando que las referencias archivadas a `omarchy/...` preceden al reorg. Sin ediciones retroactivas a artefactos históricos. |
| El rename de `cleanup` rompe cualquier cron job, systemd timer, o alias de shell que el usuario haya configurado. | Med | El usuario resolvió explícitamente el Fork #3 para sacar el sufijo `-omarchy`. El apply phase grep-chequea `~/.bashrc`, `~/.config/{zellij,nvim}/...`, y `~/.zshrc` (si existe) por referencias a `cleanup-omarchy` y ofrece un update de una línea. El verify report flaggea cualquier referencia remanente. |

## Plan de rollback

El shadow copy approach reduce la necesidad de rollback: cada WU tiene un
punto de retorno claro. WU-1 (shadow copy): borrar los shadows, nada más.
WU-2 (script edits): revertir las ediciones, los scripts viejos siguen
funcionando. WU-3 (live re-point): si falla, los symlinks vivos se
restauran corriendo `bash scripts/setup-omarchy --dry-run` seguido del
viejo `git checkout` (los archivos en `omarchy/` siguen ahí hasta WU-4).
WU-4 (atomic commit): `git revert` del commit + `bash scripts/setup-omarchy`
para re-aterrizar los symlinks vivos a los paths viejos. Sin riesgo de
pérdida de datos más allá del working tree.

## Dependencias

Ninguna externa. El instalador de Omarchy (comando `omarchy`) es la única
dependencia externa de runtime, y queda sin cambio. El CLI `git` se
requiere para las operaciones `git mv` y `git rm -r`, y los comandos
`bash`, `readlink`, `diff`, `cp`, `hyprctl`, y `sudo` se requieren para
la apply phase y su verificación.

## Criterios de éxito

- [ ] `git ls-files` no muestra entries bajo `omarchy/`, `shared/`, o `scripts/` (todos absorbidos o eliminados).
- [ ] `git ls-files` muestra los nuevos entries `src/home/{config,local,.bashrc,.ssh}` y `src/etc/keyd/` y `src/utils/bash/{setup-dots,setup-deps,setup-fonts,cleanup}` y `src/README.md`.
- [ ] Los 14 symlinks vivos (`~/.config/nvim`, `~/.config/zellij`, `~/.config/hypr/{hyprland,hypridle,p-bindings,p-index,p-looknfeel,p-monitors,p-rules}.conf`, `~/.config/waybar`, `~/.config/alacritty`, `~/.config/omarchy/themes/tokyo-night-autana`, `~/.config/starship.toml`, `~/.bashrc`) todos `readlink -f` dentro de los nuevos paths `src/home/config/...` y `src/home/.bashrc`.
- [ ] Ningún symlink relativo `../../shared/` sobrevive en ningún lugar del working tree (grep devuelve vacío).
- [ ] `src/home/config/tmux/tmux.conf` tiene un comment `# Reason:` al inicio (el contenido puede variar según el check de verify-time descripto en la tabla de Riesgos).
- [ ] `src/home/config/{mako,omarchy/hooks,omarchy/themes}/` no tienen archivos `.gitkeep`.
- [ ] El script `setup` (raíz) tiene `SCRIPTS_DIR="$DOTFILES_ROOT/src/utils/bash"`; `./setup --dots`, `./setup --fonts`, `./setup --deps` todos dispatchan correctamente.
- [ ] `bash tests/setup-deps.bash` pasa (harness sin cambio; `TEST_PLAN=5` de `omarchy-only-scope`).
- [ ] `hyprctl reload && hyprctl configerrors` no reporta errores después del live re-point.
- [ ] `/etc/keyd/default.conf` matchea `src/etc/keyd/default.conf` (bit-identical) y tiene modo `0644`.
- [ ] Los servicios `keyd` y `ratbagd` están enabled y corriendo.
- [ ] La línea 55 de `AGENTS.md` (y la sección Forbidden Paths que la rodea) está reescrita; el nuevo texto NO contiene la línea vieja "Hyprland / Mako / Waybar / Walker configs (omarchy-only, not shared)"; un grep por "not shared" en `AGENTS.md` devuelve vacío.
- [ ] Los ejemplos de path de `docs/conventions.md` están actualizados; la tabla "Repo layout" refleja la nueva forma.
- [ ] `docs/shared-layer.md` está actualizado; las excepciones SSH y keyd apuntan a los nuevos paths; la sección "Adding a new environment" está eliminada.
- [ ] La tabla de managed-paths de `src/README.md` (antes `omarchy/README.md`) está actualizada.
- [ ] El delta de `openspec/specs/setup-orchestration/spec.md` está escrito bajo `openspec/changes/repo-structure-omarchy-reorg/specs/`; la fase de archive lo mergea de vuelta en el main spec.
- [ ] El bloque `context:` de `openspec/config.yaml` refleja el nuevo layout.
- [ ] `docs/cleanup.md` existe; `docs/ideas/scripts/cleanup.md` ya no existe.
- [ ] `openspec/changes/archive/*` y `openspec/changes/cleanup-omarchy/` son byte-idénticos a antes del change.
