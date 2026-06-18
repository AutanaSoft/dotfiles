# Propuesta: housekeeping-cleanup — limpieza post-reorg

> **Alcance confirmado** (2026-06-18): cierre de los hallazgos residuales
> W3 (reglas inertes en `.gitignore`) y W4 (guías Fedora/Windows-era fuera
> de alcance) del verify-report de `repo-structure-omarchy-reorg`. W2
> queda diferido.

## Por qué

La reorg (PR #7) movió los dotfiles canónicos a `src/home/config/` y
eliminó los directorios `shared/`, `home/` y `omarchy/` del árbol
rastreado. Quedan dos problemas residuales que confunden a futuros
lectores y agentes:

1. `.gitignore` (líneas 5-9) referencia `shared/home/.ssh/*`. La ruta
   no existe; las reglas son inertes y el comentario induce a error
   sobre dónde deben aterrizar las claves SSH por host.
2. `docs/git.md` y `docs/wezterm.md` documentan archivos que ya no
   existen (`home/.gitconfig`, `home/.wezterm.lua`, `omarchy/README.md`).
   Son reliquias pre-`omarchy-only-scope`; el repo es Omarchy-only y
   el instalador de Omarchy maneja esas superficies.

Ninguno cambia comportamiento runtime: el `.gitignore` corregido
restablece la protección que el comentario promete, y los docs
eliminados reducen ruido sin perder información vigente.

## Qué cambia

| Tipo | Ruta | Notas |
| --- | --- | --- |
| Modificado | `.gitignore` | Reescribir bloque SSH: `shared/home/.ssh/*` → `src/home/.ssh/*` y `!shared/home/.ssh/config` → `!src/home/.ssh/config`. |
| Eliminado | `docs/git.md` | `git rm` — reliquia Fedora-era, sin `home/.gitconfig` ni `omarchy/README.md`. |
| Eliminado | `docs/wezterm.md` | `git rm` — reliquia Windows-era, sin `home/.wezterm.lua` ni `omarchy/README.md`. |

### Fuera de alcance

- **W2** (referencias `docs/ideas/scripts/cleanup.md` en
  `src/utils/bash/cleanup` líneas 3/42/90) — diferido. Es drift
  documental en comentario interno / texto de usage; no bloqueante.
  Puede abordarse en un cambio futuro.

## Capacidades

### Nuevas capacidades

Ninguna.

### Capacidades modificadas

Ninguna. El cambio no toca el contrato runtime del repo; sólo limpia
referencias documentales y reglas inertes del `.gitignore`.

## Enfoque

1. Editar `.gitignore` (líneas 5-9): actualizar comentario + reglas al
   path vigente.
2. `git rm docs/git.md docs/wezterm.md` en el mismo commit
   (work unit: eliminar reliquias Fedora/Windows-era).
3. Verificación: `git grep -nE 'shared/home/\.ssh|home/\.gitconfig|home/\.wezterm\.lua|omarchy/README\.md' -- ':!openspec/changes/archive/'`
   debe devolver vacío.
4. Único PR, dos commits:
   - `fix(gitignore): point SSH ignore rules at src/home/.ssh/`
   - `chore(docs): remove Fedora/Windows-era guides`

## Áreas afectadas

| Área | Impacto | Descripción |
| --- | --- | --- |
| `.gitignore` | Modificado | Reglas SSH corregidas al path actual. |
| `docs/git.md` | Eliminado | Redacción ya no vigente. |
| `docs/wezterm.md` | Eliminado | Redacción ya no vigente. |
| `openspec/changes/archive/*` | Sin tocar | Política de archivo SDD. |
| `openspec/changes/cleanup-omarchy/` | Sin tocar | Cambio activo no relacionado. |

## Riesgos

| Riesgo | Prob. | Mitigación |
| --- | --- | --- |
| Alguien tenía claves SSH en `shared/home/.ssh/` esperando ser protegidas. | Baja | El directorio `shared/` no existe desde la reorg. La corrección reactiva el `.gitignore` a la realidad. |
| Algún enlace externo apuntaba a `docs/git.md` o `docs/wezterm.md`. | Baja | Repositorio personal, sin docs site público. `git grep` confirma cero referencias internas restantes. |
| PR se confunde con la reorg principal. | Baja | Título y cuerpo aclaran que es follow-up housekeeping, no reorg. |

## Plan de rollback

`git revert <commit>` (o ambos) recupera el estado previo en uno o dos
pasos. Sin riesgo de pérdida: los archivos eliminados son documentos,
no configuración activa.

## Dependencias

Ninguna.

## Criterios de éxito

- [ ] `.gitignore` líneas 5-9 usan `src/home/.ssh/*` y `!src/home/.ssh/config`.
- [ ] `docs/git.md` y `docs/wezterm.md` ya no están en el árbol rastreado.
- [ ] `git grep -nE 'shared/home/\.ssh|home/\.gitconfig|home/\.wezterm\.lua|omarchy/README\.md' -- ':!openspec/changes/archive/'`
      devuelve vacío.
- [ ] `openspec/changes/archive/*` y `openspec/changes/cleanup-omarchy/`
      byte-idénticos a `main`.