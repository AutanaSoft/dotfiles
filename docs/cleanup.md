# Script CleanUp Para Omarchy

## Contexto

**Hoy**: la única vía para limpiar preinstalados es la opción
`*Preinstalls*` del menú de Omarchy, que borra todo de una vez.

**Problema**: no permite conservar piezas que sí se usan (ver lista
`[K]` abajo) y descartar solo el resto.

**Idea**: definir explícitamente qué se queda y qué se va, y ejecutar
la limpieza de forma selectiva.

## Objetivo

Script de limpieza selectiva que respete los marcadores `[K]` / `[R]`
de la lista de este doc.

Debe permitir:

- Ejecución no interactiva (lista predefinida, sin prompts).
- Ejecución interactiva (picker por si se quiere ajustar antes de
  ejecutar).
- Detenerse si hay items `[K]` en riesgo (revisión manual antes de
  seguir).

## Aplicaciones instaladas por Omarchy

Marcador de la izquierda:
`[K]` Conservar
`[R]` Remover

### Stubs de npx

- [R] `codex`
- [R] `copilot`
- [R] `gemini`
- [R] `opencode`
- [R] `playwright-cli`
- [R] `pi`

### Paquetes

- [R] `1password-beta`
- [R] `1password-cli`
- [K] `aether`
- [R] `claude-code`
- [K] `cliamp`
- [R] `kdenlive`
- [K] `lazydocker`
- [K] `libreoffice-fresh`
- [R] `obs-studio`
- [K] `obsidian`
- [R] `opencode`
- [R] `pinta`
- [R] `signal-desktop`
- [K] `spotify`
- [R] `typora`
- [K] `xournalpp`

### Web apps

- [R] `Basecamp`
- [R] `ChatGPT`
- [R] `Discord`
- [R] `Figma`
- [R] `Fizzy`
- [R] `GitHub`
- [R] `Google Contacts`
- [R] `Google Maps`
- [R] `Google Messages`
- [K] `Google Photos`
- [R] `HEY`
- [R] `Tailscale`
- [K] `WhatsApp`
- [R] `X`
- [R] `Xbox Cloud Gaming`
- [K] `YouTube`
- [R] `Zoom`

### TUIs

- [K] `Docker`
- [K] `Disk Usage`

## Resumen de la limpieza

| Categoría    | A eliminar | A conservar | Total  |
| ------------ | ---------- | ----------- | ------ |
| Stubs de npx | 6          | 0           | 6      |
| Paquetes     | 9          | 7           | 16     |
| Web apps     | 14         | 3           | 17     |
| TUIs         | 0          | 2           | 2      |
| **Total**    | **29**     | **12**      | **41** |
