# AGENTS

Stack, idioma y reglas duras para que un agente (humano o IA) trabaje en este repo sin romper convenciones. Si una regla aquí choca con una skill instalada, este archivo gana.

## Comunicación con el usuario

- Respuestas cortas y directas por defecto.
- Español Neutral Técnico, sin variantes regionales ni jerga.
- Una pregunta a la vez. Después de preguntar, STOP y espera.

## Commits y pushes

- **Commit**: solo si el usuario lo pide explícitamente.
- **Push**: solo si el usuario lo pide explícitamente.
- Mensajes en Conventional Commits. Sin "Co-Authored-By" ni atribución a IA. Sin emojis.

## Comentarios y documentación inline

- **Idioma**: inglés (US), técnico, sin importar el idioma de conversación.
- **Qué documentar**: exports (funciones, clases, tipos, interfaces) cuando el contrato no sea obvio. Omitir helpers autoexplicativos y one-liners.
- **Contenido**: por qué (intención, decisión, trampa), no el qué.
- **Código comentado**: prohibido. Borrar; git preserva el historial.
- **Emojis**: prohibidos en código y commits.

## Verificación (contrato del agente)

- No asumas APIs, convenciones ni comportamiento desde memoria. Verifica contra la doc oficial antes de escribir o modificar código.
- Cita fuente (URL de docs + versión del paquete) en claims técnicos no obvios.
- Si el usuario marca algo como incorrecto: verifica contra la doc antes de aceptar o rechazar. La memoria y los "probablemente" no son evidencia.

## Cambios del usuario en código generado

- **Asume intención**: cualquier diferencia entre lo que generaste y el presente en el repo es, por defecto, intencional.
- **No revertir sin confirmar**: no deshagas, reescribas ni "corrijas" esos cambios sin confirmación explícita.
- **Cómo preguntar**: si lo consideras un error o bug, plantea la observación con evidencia (URL, línea, diff) y pregunta antes de tocar.
- **Excepción**: si el usuario pidió revertir o ajustar explícitamente ("vuelve atrás", "aplica esto en lugar de lo anterior"), procede.
