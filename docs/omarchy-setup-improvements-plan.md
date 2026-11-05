# Plan de mejoras del instalador de Omarchy

Este plan organiza las mejoras propuestas para que la configuración del perfil sea más segura,
predecible y fácil de mantener. No autoriza por sí mismo la aplicación de configuraciones al
sistema, la eliminación de archivos, la creación de commits ni la instalación de paquetes.

## Estado de implementación

La implementación de los siete pasos está incorporada al repositorio, incluida la evaluación del
paso 7: se conservan los helpers separados porque sus diferencias no justifican una biblioteca
compartida. La suite completa de Omarchy, sintaxis Bash, ayuda y comprobaciones de Markdown pasaron.

**La verificación global no está cerrada:** T1 y fuentes conservan verificaciones independientes no
disponibles; T2 conserva un resultado independiente parcial por la comparación pendiente del flujo
exitoso contra la base. La revisión de cleanup y la del respaldo de enlaces sí se completaron. RDD
está deshabilitado solo para este clon; eso no convierte la evidencia pendiente en aprobada.

El usuario autorizó registrar la implementación en un commit local, sin publicar ni aplicar cambios
al sistema. El detalle y las limitaciones permanecen en `odd/tasks/omarchy-setup-improvements.md`.

## Estado inicial (histórico)

- `setup` despacha las fases seleccionadas; `setup-omarchy` las ejecuta en el orden dependencias,
  fuentes, dotfiles, servicios y validación. Un fallo detiene las fases siguientes, pero no revierte
  las anteriores.
- Al redactar el plan había cambios locales sin commit en `setup-dots` y su prueba para prevalidar
  el manifiesto; esa prevalidación quedó después en el commit `032c61c`. La prueba focalizada y la
  suite de Omarchy pasaron. La revisión nativa aprobó esos dos archivos con dos advertencias no
  bloqueantes, R3-001 y R4-001. La verificación independiente requerida no se completó porque el
  entorno rechazó su solicitud y declaró no disponible el verificador.
- La revisión nativa no sustituye esa verificación. No dar por terminada la primera mejora hasta
  resolver el requisito de verificación aplicable. El registro está en
  `odd/tasks/omarchy-setup-improvements.md`.
- `cleanup` es una herramienta independiente: no se ejecuta como parte de `setup`.

## Orden de implementación

| Paso | Mejora                                               | Archivos principales                                                       | Prioridad |
| ---- | ---------------------------------------------------- | -------------------------------------------------------------------------- | --------- |
| 1    | Validación previa y aplicación segura de dotfiles    | `omarchy/utils/bash/setup-dots`, `omarchy/dots-manifest`, `tests/omarchy/` | Alta      |
| 2    | Recuperación ante fallos de instalación de servicios | `omarchy/utils/bash/setup-services-{postgresql,valkey}`, `tests/omarchy/`  | Alta      |
| 3    | Validación fiable de la escucha de Valkey            | `omarchy/utils/bash/setup-services-valkey`, `tests/omarchy/`               | Alta      |
| 4    | Alcance y comportamiento parcial de servicios        | `omarchy/utils/bash/setup-services`, `setup`, `docs/setup.md`              | Media     |
| 5    | Versiones y comprobación de fuentes                  | `omarchy/utils/bash/setup-fonts`, `tests/omarchy/`, `docs/setup.md`        | Media     |
| 6    | Coherencia y ejecución segura de `cleanup`           | `omarchy/utils/bash/cleanup`, pruebas y documentación correspondientes     | Media     |
| 7    | Simplificación prudente de lógica compartida         | Helpers de servicios y pruebas afectadas                                   | Baja      |

Cada paso debe conservar el comportamiento no relacionado, incluir sus pruebas y actualizar la ayuda
o documentación si modifica un contrato. No se propone tocar el perfil Fedora WSL2.

## 1. Validar el manifiesto antes de aplicar dotfiles

**Objetivo:** detectar entradas inválidas antes de crear enlaces, mover destinos o crear backups.

1. Revisar los cambios locales existentes antes de modificarlos; no descartarlos ni sobrescribirlos.
2. Validar acciones, fuentes obligatorias y patrones `glob` antes de aplicar el manifiesto.
   Preservar explícitamente el comportamiento de `copy` cuando su fuente o destino no corresponda
   aplicarlo.
3. Comprobar rutas con espacios, patrones sin coincidencias y errores en entradas posteriores.
   Evitar que el tratamiento de nombres de archivo introduzca pérdida o división de rutas.
4. Definir y documentar cómo preservar enlaces simbólicos existentes antes de reemplazarlos.
5. Revisar las advertencias informativas de la revisión nativa como trabajo posterior separado, sin
   reabrir ni presentar como bloqueante la revisión aprobada.

**Aceptación:** un manifiesto inválido no cambia destinos ni crea backups; un manifiesto válido
mantiene el comportamiento previsto. Las pruebas comprueban código de salida, mensajes y efectos
observables, incluidos destinos existentes y `--dry-run`. La validación previa no garantiza rollback
ante todos los errores que puedan producirse después, durante la aplicación.

**Decisión aplicada:** un enlace de destino distinto, válido o roto, se mueve como enlace al backup,
con sufijos ante colisiones. Los enlaces correctos se conservan y `--dry-run` solo anuncia la
operación. Un enlace relativo conserva su texto, aunque puede dejar de resolver desde el backup.
Esta política no cambia los enlaces padres rotos ni la limpieza del enlace obsoleto del monitor.

## 2. Recuperar instalaciones parciales de servicios

**Objetivo:** evitar que un fallo al instalar la configuración de PostgreSQL o Valkey deje un
destino parcial sin intentar recuperación.

1. Conservar backup y estado inicial del servicio antes de cualquier cambio.
2. Evaluar instalación temporal y reemplazo seguro en el mismo sistema de archivos, o recuperación
   explícita si falla `install`; preservar propietario y permisos previstos.
3. Mantener las diferencias existentes: PostgreSQL recarga y Valkey reinicia cuando corresponde.
4. Probar fallos simulados de instalación, restauración, inicio y recarga o reinicio, con destino
   previo y sin él. No ejecutar estas pruebas sobre servicios ni datos reales.

**Aceptación:** se comunica el fallo, se restaura el contenido y el estado anterior cuando es
posible, se informa cualquier fallo de recuperación y no se modifican datos ajenos. También se
comprueba que el flujo exitoso y `--dry-run` conservan su comportamiento.

## 3. Comprobar correctamente la escucha de Valkey

**Objetivo:** no declarar válida la restricción a loopback si `ss` falla.

1. Capturar y comprobar el estado de `ss` antes de evaluar su salida.
2. Rechazar listeners externos y tratar explícitamente la ausencia de resultados, sin confundirla
   con una consulta fallida.
3. Probar salida local válida, listener externo, fallo de `ss` y los efectos de recuperación.

**Aceptación:** un fallo de inspección no produce éxito falso y se conservan las comprobaciones de
TCP y socket existentes. Los tests usan comandos simulados y no alteran Valkey del host.

## 4. Aclarar el alcance de `--services`

**Objetivo:** hacer visible que keyd, PostgreSQL y Valkey se procesan en orden y que un fallo no
revierte automáticamente los servicios anteriores.

1. Documentar la aplicación parcial y la recuperación limitada de cada helper.
2. Evaluar una selección individual de servicios solo si se acuerda ampliar la interfaz; definir sus
   opciones, interacción con `--non-interactive`, ayuda y compatibilidad antes de implementarla.
3. Probar orden, selección, fallos y ausencia de efectos en servicios no seleccionados cuando la
   selección individual esté autorizada.

**Aceptación:** la documentación coincide con el comportamiento real; cualquier opción nueva es
explícita, comprobada y compatible con los usos existentes de `--services`.

## 5. Hacer reproducible la instalación de fuentes

**Objetivo:** instalar artefactos identificables y comprobados, sin sustituir archivos ajenos por
accidente.

1. Seleccionar versiones publicadas de las fuentes y obtener sus hashes de fuentes oficiales,
   registrando origen y versión; no inventar valores ni depender de `latest`.
2. Verificar cada descarga antes de extraer o modificar el destino; fallar sin instalar ante una
   discrepancia.
3. Definir cómo actualizar el directorio gestionado y tratar fuentes antiguas sin borrar archivos de
   propiedad incierta. Preservar backups o detenerse cuando no pueda establecerse la propiedad.
4. Probar versión fijada, hash correcto e incorrecto, fallo de descarga, repetición y `--dry-run`,
   usando artefactos locales simulados.

**Aceptación:** una misma versión fijada produce la misma entrada verificable; un artefacto inválido
no cambia las fuentes instaladas ni ejecuta `fc-cache`.

## 6. Alinear el contrato de `cleanup`

**Objetivo:** que ayuda, confirmaciones, modo de prueba y efectos coincidan.

1. Decidir si `--dry-run` debe pedir confirmación y si puede escribir auditoría. Actualmente crea un
   log y el flujo de confirmación depende de `--yes`; reflejar la decisión en ayuda y documentación.
2. Sustituir la ejecución de comandos construidos como texto con `bash -c` por argumentos separados
   o despachos explícitos, sin alterar los elementos seleccionados ni las API existentes de Omarchy.
3. Probar selección, confirmación, auditoría, nombres con espacios, fallos y preservación de
   componentes no seleccionados con dobles; no desinstalar aplicaciones reales en las pruebas.

**Aceptación:** el comportamiento observable coincide con la ayuda; el modo de prueba no elimina
componentes, y cualquier escritura de auditoría se declara expresamente.

## 7. Simplificar sin ocultar diferencias

**Objetivo:** reducir duplicación solo donde la abstracción facilite mantener y comprobar el código.

1. Comparar las rutinas de estado y recuperación de PostgreSQL y Valkey después de estabilizar los
   pasos 2 y 3.
2. Extraer una biblioteca pequeña únicamente si existe lógica realmente idéntica y su interfaz queda
   clara. Conservar los helpers de servicio y sus diferencias de recarga, reinicio y validación.
3. Si la abstracción aumenta el acoplamiento o no aporta claridad, registrar la decisión y mantener
   la duplicación explícita.

**Aceptación:** las pruebas existentes y nuevas verifican el mismo comportamiento antes y después;
la simplificación no modifica contratos ni elimina recuperaciones específicas.

## Verificación y entrega

- Para cada regla determinista, escribir una prueba que falle antes de implementar y comprobar que
  pasa después; conservar pruebas del comportamiento existente afectado.
- Ejecutar pruebas aisladas con directorios temporales y dobles para `sudo`, systemd, red y
  paquetes. No ejecutar instalaciones reales, modificar servicios del host ni borrar datos durante
  las pruebas.
- Ejecutar las pruebas focalizadas, `./tests/run.sh omarchy`, `bash -n` sobre los scripts
  modificados y `git diff --check`. Actualizar ayuda y documentación cuando cambie una opción o
  mensaje.
- Completar la verificación independiente exigida para cambios de alto riesgo y seguir el resultado
  de la revisión nativa cuando corresponda. Una revisión aprobada no sustituye las pruebas ni la
  verificación independiente.
- Conservar los cambios existentes y reportar pruebas fallidas, omitidas o bloqueos. No crear
  commits, publicar ni aplicar cambios al sistema sin la autorización correspondiente.
