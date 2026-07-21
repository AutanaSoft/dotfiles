# AGENTS

Reglas estrictas para que un agente (humano o IA) trabaje en este repositorio sin romper
las convenciones.

Si una regla aquí entra en conflicto con una skill instalada, este archivo prevalece.

Léelo completo antes de tu primera edición: cada sección indica su alcance y límites.

## Estructura del repositorio

Consulta [README.md](README.md) para la estructura y convenciones específicas de este repositorio.

## Comunicación con el usuario

- Respuestas cortas y directas por defecto.
- Una pregunta a la vez. Después de preguntar, DETENTE y espera.

## Commits y pushes

- **Commit**: No crear ni generar sin la solicitud explícita del usuario.
- **Push**: No hacer push sin la solicitud explícita del usuario.
- **Skill:** Usa siempre `commit-message` para crear, generar los commits.

## Comentarios en línea y documentación

- **Qué documentar**: exportaciones (funciones, clases, tipos, interfaces) cuando el contrato
  no sea obvio. Omitir helpers autoexplicativos y one-liners.
- **Contenido**: el por qué (intención, decisión, gotcha), no el qué.
- **Código comentado**: prohibido. Eliminarlo; git preserva la historia.

## Generación de código

- **Plan antes de implementar**: antes de cualquier cambio, entregar un plan con alcance, archivos
  afectados y pasos. No ejecutar hasta que el desarrollador apruebe.
- **Cero suposiciones**: no inventar APIs, convenciones ni comportamientos. Verificar contra la
  documentación oficial (citar URL + versión) o preguntar al desarrollador. La memoria y el
  "probablemente" no son evidencia.
- **Sin cambios implícitos**: no tocar archivos fuera del alcance declarado en el plan.
- **Si el usuario señala un error**: verificar contra la documentación antes de aceptar o rechazar.

## Cambios del usuario sobre código generado

- **Asumir intención**: cualquier diferencia entre lo generado y lo que está en el
  repositorio es, por defecto, intencional.
- **No revertir sin confirmación**: no deshacer, reescribir ni "arreglar" esos cambios
  sin confirmación explícita.
- **Cómo preguntar**: si se considera un error o bug, plantear la observación con evidencia
  (URL, línea, diff) y preguntar antes de tocar.
- **Excepción**: si el usuario pidió explícitamente revertir o ajustar ("volver atrás",
  "aplicar esto en lugar del anterior"), proceder.
