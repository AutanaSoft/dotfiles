# AGENTS

Reglas estrictas para que un agente, humano o IA, trabaje en este repositorio sin romper sus convenciones.

Si una regla de este archivo entra en conflicto con una skill instalada, este archivo prevalece.

Léelo completo antes de la primera edición. Cada sección delimita su alcance y sus límites.

## Contexto del repositorio

Consulta [README.md](/README.md) antes de editar. Allí están la estructura y las convenciones locales del repositorio.

## Estilo de código

- Al generar o editar código, sigue `.editorconfig` como fuente principal de estilo y `.prettierrc` como configuración complementaria de formato.
- Respeta el linter y el análisis estático configurados por el proyecto; no introduzcas warnings.
- No desactives reglas de formato, linting o tipos sin una justificación localizada y documentada.

## Comunicación

- Responde de forma corta, directa y con un tono técnico neutro.
- Formula una sola pregunta cada vez y espera la respuesta antes de continuar.
- Informa bloqueos, supuestos necesarios y verificaciones no ejecutadas.

## Commits y pushes

- No crees ni generes commits sin una solicitud explícita del usuario.
- No hagas push sin una solicitud explícita del usuario.
- Al preparar un commit, usa la skill `commit-message` si está disponible.

## Comentarios y documentación

- Documenta exportaciones cuando su contrato no sea evidente; omite helpers autoexplicativos y one-liners.
- Explica intención, decisión o limitación, no una descripción literal del código.
- No mantengas código comentado; el historial de Git conserva las versiones anteriores.

## Planificación y verificación

- Antes de cualquier cambio, presenta un plan con alcance, archivos afectados y pasos. No ejecutes hasta que el desarrollador lo apruebe.
- No inventes APIs, convenciones ni comportamientos. Verifica contra la documentación oficial, cita URL y versión, o pregunta al desarrollador. La memoria y el "probablemente" no son evidencia.
- No modifiques archivos fuera del alcance acordado sin informar el motivo.
- Si el usuario cuestiona una afirmación técnica, verifícala antes de aceptarla o rechazarla.

## Cambios del usuario

- Considera intencional cualquier diferencia entre el código generado y el estado actual del repositorio.
- No reviertas, reescribas ni corrijas esos cambios sin confirmación explícita.
- Si identificas un posible error, presenta evidencia verificable —URL, línea o diff— y pide confirmación antes de modificarlo.
- Si el usuario solicita explícitamente revertir o ajustar un cambio, procede dentro del alcance indicado.
