# Especificación V1: instalador de perfiles TUI

La TUI permite configurar un perfil de Omarchy desde una interfaz de terminal: seleccionar categorías y componentes,
revisar la selección y ejecutar la instalación real. Se implementa en Bash, sin bibliotecas gráficas ni frameworks de
interfaz. Esta especificación define el alcance y comportamiento de V1; los detalles aún no definidos se indican en
«Detalles pendientes».

## Alcance y arquitectura

- V1 cubre el perfil Omarchy.
- `scripts/setup` es el único punto de entrada de la TUI. Descubre perfiles bajo `src/` mediante el manifiesto
  `src/<perfil>/profile.json`; los subdirectorios que no contienen ese archivo se ignoran sin aviso. Un manifiesto
  existente pero inválido produce un error, sin impedir que los perfiles válidos estén disponibles. Con `--profile <id>`
  se omite el selector y se abre directamente ese perfil; ambas rutas usan el mismo motor común.
- La TUI conserva, para los componentes seleccionados, el comportamiento vigente que siga siendo aplicable, adaptando
  cada conducta individualmente a la interfaz. El CLI existente sirve únicamente como referencia de comportamiento y
  comprobaciones; la TUI no depende de él durante la ejecución. Las comprobaciones aplicables se reproducen para los
  componentes seleccionados.

## Manifiestos y componentes

Cada perfil tiene un manifiesto JSON en `src/<perfil>/profile.json`. El manifiesto contiene `schema_version`, `id`,
`name`, `description`, `order`, `platform`, `requirements` y `categories`. `schema_version` es obligatorio y debe ser un
número JSON con valor `1`; se rechazan las versiones no admitidas y cualquier otro tipo. `id` usa solo letras
minúsculas, dígitos y guiones. `platform` identifica `os`, `distribution` y `version` principal. `order` determina la
posición en el selector; si dos perfiles empatan, se conserva el orden en que se descubrieron.

Los manifiestos contienen datos. Bash los lee y valida con `jq`; no se cargan con `source`, no se evalúan ni se
ejecutan. Antes de leerlos, la TUI comprueba que `jq` esté disponible. Cada manifiesto existente inválido produce un
error y no se puede seleccionar, sin ocultar los perfiles válidos. Los perfiles con un `id` duplicado producen un error
y no se pueden seleccionar.

`categories` es un array de categorías; cada categoría incluye `id`, `name`, `description`, `requirements` y
`components`. Cada componente incluye `id`, `name`, `description` e `items`. El orden declarado en los arrays de
categorías, componentes e ítems rige su presentación y ejecución. Los IDs son únicos dentro de su ámbito: entre perfiles
descubiertos, dentro del perfil para las categorías y dentro de la categoría para los componentes.

La validación exige los campos y tipos requeridos, IDs sin duplicados en su ámbito, acciones y handlers conocidos, y
rutas y valores requeridos. La forma exacta de las validaciones pendientes se indica en «Detalles pendientes».

- **Dotfiles:** cada ítem incluye `action`, `source` y `destination`. `source` se resuelve desde la raíz del repositorio
  y `destination` desde `$HOME`.
  - **`file`:** requiere un origen existente y asegura que el destino sea un enlace simbólico al origen. Si el enlace ya
    es correcto, se conserva; si se sustituye un destino existente, se respalda primero.
  - **`copy`:** se omite el elemento si no existe el origen y no se sobrescribe un destino existente.
  - **`glob`:** trata `source` como un patrón desde la raíz del repositorio y crea en `destination` enlaces con el
    nombre base de cada coincidencia, aplicando las mismas reglas de `file`. Si no hay coincidencias, la instalación se
    detiene con un error.
- **Fuentes:** cada ítem incluye `url`, `sha256` y `destination`, relativo a `$HOME`. Se verifica el digest antes de
  extraer el archivo; si no coincide, la instalación se detiene. No se sobrescriben fuentes no gestionadas.
- **Dependencias:** la categoría incluye `package_manager` y requisitos de comandos. Cada `items` es un array de nombres
  de paquetes.
- **Servicios:** los ítems identifican handlers con nombre y pueden indicar un destino absoluto del sistema. No se
  permiten comandos arbitrarios.

La instalación no promete atomicidad ni reversión. Un fallo o una interrupción puede dejar cambios parciales.

## Categorías y granularidad de selección

| Categoría    | Unidad seleccionable                                                               |
| ------------ | ---------------------------------------------------------------------------------- |
| Dotfiles     | Componente o grupo. Pi Agent y Gentle AI forman un único componente seleccionable. |
| Fuentes      | Componente.                                                                        |
| Dependencias | Componente; sus ítems son nombres de paquetes.                                     |
| Servicios    | Componente.                                                                        |

### Inventario actual de referencia (no catálogo aprobado)

Este inventario refleja la configuración actual del perfil Omarchy y sirve como referencia para diseñar la TUI; no es el
catálogo final aprobado ni implica que todos sus elementos deban incluirse.

- **Dotfiles (7 grupos):** Hyprland, Neovim, Bash, Starship, Mise, Pi Agent y Gentle AI (un grupo), Herdr.
- **Fuentes:** Monaspace Nerd Font, Fira Code Nerd Font y Fira Mono Nerd Font.
- **Dependencias (10 paquetes):** systemd-resolvconf, wireguard-tools, lsof, hunspell, hunspell-en_us, hunspell-es_any,
  trash-cli, keyd, discord y anydesk-bin.
- **Servicios:** keyd y WireGuard. El preparador actual habilita e inicia keyd; WireGuard se prepara para el arranque,
  pero nunca se inicia la VPN.

Los componentes no seleccionados no producen efectos. La TUI instala únicamente lo seleccionado de forma manual; no
resuelve relaciones entre componentes, agrega otros automáticamente ni ofrece un mecanismo para gestionar esas
relaciones. Las dependencias propias de los paquetes seleccionados las resuelven `yay` o `pacman`, que pueden solicitar
datos o confirmación al usuario. La TUI permite atender esas solicitudes desde la terminal.

## Flujo de la TUI

1. Al iniciar `scripts/setup`, elegir un perfil válido. Si se proporciona `--profile <id>`, omitir el selector y usar
   ese perfil.
2. Elegir las categorías que se desean configurar: Dotfiles, Fuentes, Dependencias y Servicios.
3. Recorrer las categorías elegidas y seleccionar sus componentes.
4. Comprobar la compatibilidad del perfil y los requisitos de las categorías seleccionadas. Si falta algún requisito,
   bloquear el avance.
5. Revisar un resumen compacto de la selección, agrupado por categoría.
6. Confirmar con `Instalar` para comenzar la instalación real.

El flujo es secuencial: un indicador muestra el paso actual y los pasos del recorrido, sin permitir saltos. Se avanza
con `Continuar` y se retrocede con `Volver`. Las categorías y sus componentes comienzan desmarcados; marcar una
categoría no selecciona automáticamente sus componentes. No se puede avanzar sin seleccionar al menos una categoría ni
desde una categoría elegida si no se seleccionó al menos un componente. Al volver a pasos anteriores se conservan las
selecciones. Los requisitos se comprueban antes de la revisión y de la confirmación.

La pantalla de revisión es de solo lectura. `Volver` conserva la selección y tiene el foco inicial para evitar una
instalación accidental. V1 ejecuta la instalación real al confirmar; no ofrece vista previa ni simulación.

## Plantilla navegable (alcance separado de V1)

La plantilla navegable es un hito independiente de V1 y usa datos de ejemplo. Lee y descubre perfiles a partir de esos
datos, permite recorrer la selección de categorías y componentes, y muestra la revisión de la selección. No ejecuta
instalaciones reales ni cambia el comportamiento de producción. En la revisión muestra `Instalar` deshabilitado y el
texto exacto `Instalación no disponible en esta plantilla.`

La plantilla no sustituye ni reduce el alcance de V1: el flujo de producción de V1 debe ejecutar la instalación real al
confirmar con `Instalar`.

## Presentación y navegación

La interfaz usa una presentación abierta y compacta, con secciones, casillas, acciones, navegación por teclado y una
pantalla de ejecución que muestra estados y la tarea actual. La paleta acordada usa turquesa como acento principal y
reserva el naranja, de forma moderada y restringida, para detalles de identidad; los colores semánticos son verde para
éxito, ámbar para advertencia y rojo para error. El texto principal es claro y el secundario gris.

El foco se identifica con `›` y un fondo turquesa oscuro discreto. Las casillas muestran la selección, que es
independiente del foco. Los estados también se expresan mediante símbolos o texto, no solo con color.

- `↑` y `↓` mueven el foco o desplazan una lista, según el contexto.
- `Espacio` marca o desmarca el elemento enfocado.
- `Enter` activa la acción enfocada o continúa el flujo; al terminar la instalación permite salir.
- `Esc` vuelve al paso anterior.

Las listas tienen desplazamiento propio y mantienen visible el elemento enfocado. El encabezado, el indicador de pasos y
los atajos permanecen visibles. La navegación no es circular. `↑ Más` y `↓ Más` aparecen solo si hay contenido oculto en
esa dirección.

Si la terminal no tiene espacio suficiente para dibujar la interfaz, se muestra un aviso para ampliarla. Al recuperar
espacio se vuelve a mostrar el paso actual sin perder la selección. Durante una instalación, esta continúa mientras se
muestra el aviso y su estado actualizado aparece al recuperar espacio.

## Instalación, estados y resultado

Durante la instalación se muestra una lista compacta de componentes, su estado, la tarea actual y el progreso real. El
progreso cuenta los componentes completados correctamente; no se muestra en vivo la salida detallada de los comandos.

- Si todo termina correctamente, se conserva la pantalla con la lista y sus estados para poder revisarla y salir.
- Ante un error, la ejecución se detiene, se muestra directamente el detalle técnico y los componentes pendientes se
  marcan como no ejecutados. Se conserva el progreso ya alcanzado.
- Tanto tras el éxito como tras un error, se puede revisar la lista y salir.

## Interrupciones y solicitudes de entrada

Antes de instalar, `Ctrl+C` sale de la TUI sin aplicar cambios. Durante la instalación, `Ctrl+C` solicita detener el
proceso activo y espera a que termine o confirme su interrupción. Después se restaura la terminal y se advierte que
pueden quedar cambios parciales. No se hace una reversión automática y algunos comandos pueden no detenerse
inmediatamente. Durante la ejecución no hay una acción de cancelación dentro de la TUI.

Si un comando solicita una contraseña, su mensaje permanece visible y el usuario puede responder directamente en la
terminal. La TUI no captura ni muestra la contraseña. Al terminar la solicitud, se recupera la pantalla compacta con el
estado actualizado.

## Detalles pendientes

- Los detalles de validación de los demás campos de los esquemas, los valores permitidos de `package_manager` y el
  catálogo de acciones y handlers.
- Los identificadores estables de los componentes.
- El tratamiento de una fuente gestionada que haya sido modificada.
- El catálogo final de componentes e ítems de V1 sigue pendiente de aprobación; el inventario anterior es orientativo.
- El tamaño mínimo exacto de terminal y algunos detalles de distribución.
- Los detalles técnicos para manejar interrupciones, solicitudes de contraseña y la interacción con la salida de los
  comandos.
