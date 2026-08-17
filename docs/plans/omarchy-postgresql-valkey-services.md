# Servicios PostgreSQL y Valkey en Omarchy

## Objetivo

Extender `./setup --profile omarchy --services` para configurar y validar PostgreSQL y Valkey,
preservando el comportamiento existente de keyd y ratbagd. La implementación debe ser idempotente,
admitir `--dry-run` y `--non-interactive`, proteger los datos existentes y ofrecer recuperación
cuando falle una operación de configuración o de servicio.

Este plan no instala Omarchy ni reemplaza la fase de dependencias. PostgreSQL y Valkey continúan
siendo paquetes declarados en `omarchy/deps-manifest`; la fase de servicios presupone que `--deps`
ya los instaló.

## Estado actual

- `omarchy/utils/bash/setup-services` instala `/etc/keyd/default.conf`, habilita keyd y ratbagd,
  recarga keyd y restaura la configuración y el estado de las unidades en caso de fallo.
- `omarchy/utils/bash/setup-omarchy` despacha `--services`, pero actualmente consume
  `--non-interactive` sin propagarlo.
- `omarchy/deps-manifest` ya declara `postgresql` y `valkey`.
- Fedora WSL2 tiene implementaciones para PostgreSQL y Valkey, pero sus comandos de paquetes,
  usuarios, rutas y comportamiento de unidades son específicos de Fedora y no pueden copiarse a Arch
  sin verificación.

## Alcance

### Incluido

- Preservar el comportamiento de configuración y reversión de keyd y ratbagd.
- Inicializar un clúster PostgreSQL nuevo solamente cuando sea seguro.
- Instalar y validar la configuración de autenticación local de PostgreSQL.
- Configurar y validar una instancia local y un socket Unix de Valkey.
- Añadir vistas previas en seco, idempotencia, respaldos y reversión cuando sea seguro.
- Propagar la ejecución no interactiva a los helpers de servicios.
- Añadir pruebas de contrato del setup y documentación para el usuario.

### Excluido

- Aprovisionamiento de bases de datos, roles o esquemas de aplicaciones.
- Acceso de red a PostgreSQL más allá de localhost.
- Gestión de respaldos o migraciones de PostgreSQL.
- Replicación, clustering, TLS o acceso remoto de Valkey.
- Almacenamiento de contraseñas de servicios u otros secretos en el repositorio.
- Eliminación de un clúster PostgreSQL inicializado durante una reversión.

## Decisiones de diseño

### Preservar la interfaz pública

El comando público se mantiene:

```bash
./setup --profile omarchy --services
```

Una ejecución completa continúa usando:

```bash
./setup --profile omarchy --dots --deps --fonts --services --locale
```

No se requieren nuevos flags públicos de fases. La fase de servicios configura todos los servicios
administrados por el perfil Omarchy.

### Separar las responsabilidades de los servicios

Convertir `omarchy/utils/bash/setup-services` en un orquestador y trasladar el comportamiento
específico de cada servicio a helpers:

```text
omarchy/utils/bash/setup-services
omarchy/utils/bash/setup-services-input
omarchy/utils/bash/setup-services-postgresql
omarchy/utils/bash/setup-services-valkey
```

El orden de ejecución será: servicios de entrada, PostgreSQL y luego Valkey. Un fallo detendrá los
helpers posteriores. Separar la implementación mantiene la reversión existente de los dispositivos
de entrada independiente de las reglas de recuperación de las bases de datos.

### Usar el grupo `valkey` suministrado por el paquete

Usar el usuario y grupo `valkey` creados por el paquete oficial de Arch. El socket pertenecerá a
`valkey:valkey`, por lo que no se crearán `valkey-clients`, otros grupos dedicados ni un drop-in con
`SupplementaryGroups=` para el servicio.

`SupplementaryGroups=` solo agrega grupos a las credenciales del proceso iniciado por una unidad de
systemd; no modifica las credenciales de la sesión interactiva del usuario. Las pertenencias a
grupos son credenciales de cada proceso y los procesos ya iniciados no se actualizan cuando cambia
`/etc/group`. Por lo tanto, esa directiva no evita que el usuario tenga que iniciar un proceso con
las nuevas credenciales.

El setup podrá añadir al usuario que lo ejecuta al grupo `valkey`. La pertenencia tendrá efecto tras
iniciar una nueva sesión. Como alternativa manual, `newgrp valkey` puede abrir un subshell con el
grupo activo sin cerrar la sesión, pero no debe automatizarse: está diseñado para uso interactivo,
crea un entorno de shell nuevo y puede perder estado no exportado. El setup informará ambas opciones
sin intentar modificar las credenciales del proceso que lo invocó.

Esta decisión está respaldada por:

- [`systemd.exec`](https://www.freedesktop.org/software/systemd/man/latest/systemd.exec.html), que
  define `SupplementaryGroups=` como grupos adicionales del proceso ejecutado por la unidad.
- [`credentials(7)`](https://man7.org/linux/man-pages/man7/credentials.7.html), que documenta los
  grupos suplementarios como credenciales por proceso, heredadas al crear procesos.
- [`newgrp(1p)`](https://man7.org/linux/man-pages/man1/newgrp.1p.html), que documenta la creación de
  un nuevo entorno de shell con el grupo solicitado.

## Fases de implementación

### 1. Verificar los contratos de Arch y Omarchy

Antes de implementar comportamiento privilegiado, verificar los contratos de Omarchy 4 instalado y
de los paquetes actuales de Arch mediante metadatos oficiales de paquetes de Arch, archivos de
unidades empaquetados y documentación upstream. Registrar las versiones y URL verificadas en las
notas de implementación o en los comentarios pertinentes de los scripts. Confirmar:

- Nombres de los paquetes PostgreSQL y Valkey.
- Comando de inicialización de PostgreSQL y argumentos admitidos.
- Nombre del servicio, cuenta de servicio, directorio de datos y ruta activa de `pg_hba.conf` de
  PostgreSQL.
- Nombre del servicio, cuenta de servicio, ruta de configuración, directorio de ejecución y comando
  de inicio de Valkey.
- Si la configuración empaquetada de Valkey admite un archivo include apropiado para overrides
  administrados.
- Que el paquete crea el usuario y grupo `valkey`, y que la unidad se ejecuta con ambos.
- Propietarios y modos requeridos para cada archivo instalado.

No inferir estos valores desde Fedora WSL2 ni de memoria. Detenerse y revisar este plan si los
contratos de los paquetes de Arch requieren un diseño materialmente diferente.

### 2. Refactorizar los servicios de entrada sin cambios de comportamiento

Mover la implementación actual de keyd y ratbagd a `setup-services-input`. Mantener intactos su
salida de dry-run, estrategia de respaldo, registro del estado de las unidades y comportamiento de
reversión.

Cambiar `setup-services` para:

1. Procesar `--dry-run` y `--non-interactive`.
2. Validar que cada helper exista y sea ejecutable.
3. Propagar las opciones seleccionadas a todos los helpers.
4. Ejecutar los helpers en el orden documentado.

Añadir pruebas de regresión antes de introducir el comportamiento de PostgreSQL y Valkey para evitar
que la refactorización debilite silenciosamente la recuperación de los servicios de entrada.

### 3. Propagar el modo no interactivo

Actualizar `omarchy/utils/bash/setup-omarchy` para conservar `--non-interactive` en una variable
booleana e incluirla en `helper_args`. Cada helper de servicios debe aceptar el flag, incluso si no
realiza preguntas.

Comportamiento requerido:

- `--dry-run` nunca pregunta.
- `--non-interactive` nunca pregunta.
- Las preguntas interactivas solo aparecen cuando la entrada estándar es una terminal.
- Rechazar acciones opcionales no hace fallar una configuración de servicios que, por lo demás, fue
  exitosa.

### 4. Implementar la configuración de PostgreSQL

Añadir:

```text
omarchy/etc/postgresql/pg_hba.conf
omarchy/utils/bash/setup-services-postgresql
```

El helper deberá:

1. Verificar los comandos requeridos antes de cualquier modificación.
2. Resolver únicamente rutas e identidades de servicio de Arch verificadas.
3. Inspeccionar el directorio de datos:
   - preservarlo cuando exista `PG_VERSION`;
   - inicializarlo únicamente cuando no exista o esté vacío;
   - abortar cuando no esté vacío, pero no contenga `PG_VERSION`.
4. Comparar el `pg_hba.conf` administrado con el archivo instalado.
5. Respaldar un archivo existente modificado bajo `DOTFILES_BACKUP_DIR`.
6. Instalarlo con propietario, grupo y modo verificados.
7. Habilitar e iniciar PostgreSQL cuando sea necesario.
8. Recargar o reiniciar únicamente cuando cambie la configuración y el servicio empaquetado lo
   requiera.
9. Validar la disponibilidad con `pg_isready` y una consulta local mínima.

La configuración conservará el comportamiento estándar de Arch y PostgreSQL:

- socket Unix en la ubicación compilada por el paquete, bajo `/run/postgresql`;
- TCP habilitado únicamente en `localhost`, mediante `listen_addresses = 'localhost'`;
- autenticación peer para conexiones por socket Unix;
- autenticación `scram-sha-256` para conexiones TCP por loopback IPv4 e IPv6;
- ningún registro que permita redes remotas;
- sin administrar `unix_socket_group` ni `unix_socket_permissions`.

Para un clúster nuevo, `initdb` recibirá explícitamente `--auth-local=peer` y
`--auth-host=scram-sha-256`. Para un clúster existente se preservará `postgresql.conf`, salvo que el
contrato aprobado requiera corregir un `listen_addresses` que exponga PostgreSQL fuera de localhost;
cualquier cambio de ese tipo debe mostrarse, respaldarse y requerir reinicio.

En modo interactivo, el helper puede ofrecer configurar la contraseña del rol `postgres`. El manejo
de la contraseña debe evitar exponerla en la línea de comandos, logs, archivos temporales o archivos
del repositorio. Debe omitirse en los modos dry-run y no interactivo.

La reversión restaura un archivo de autenticación reemplazado y el estado anterior de la unidad
cuando sea posible. Nunca debe eliminar automáticamente un clúster inicializado ni datos existentes
de bases de datos.

### 5. Implementar la configuración de Valkey

Añadir la configuración mínima mantenible que admita el paquete de Arch verificado. Los archivos
preferidos son:

```text
omarchy/etc/valkey/valkey.conf
omarchy/utils/bash/setup-services-valkey
```

Si la configuración empaquetada admite fragmentos include administrados, preferir un fragmento en
lugar de mantener una copia completa de la configuración upstream. La política administrada deberá:

- enlazar TCP únicamente a los loopbacks IPv4 e IPv6;
- mantener habilitado el modo protegido;
- mantener TCP habilitado en el puerto estándar `6379`;
- crear `/run/valkey/valkey.sock` simultáneamente;
- asignar el socket al grupo `valkey` suministrado por el paquete;
- establecer los permisos del socket en `0770`;
- preservar los valores predeterminados del paquete no relacionados con el acceso local.

El helper deberá:

1. Verificar los comandos requeridos y que existan la cuenta y el grupo `valkey`.
2. Gestionar la inscripción opcional del usuario en el grupo `valkey` según el contrato de
   interacción aprobado.
3. Respaldar e instalar los archivos de configuración modificados con propietarios y modos
   verificados.
4. Habilitar e iniciar Valkey cuando sea necesario.
5. Reiniciar únicamente cuando cambie la configuración.
6. Validar `PONG` mediante TCP en `127.0.0.1:6379`.
7. Validar `PONG` mediante `/run/valkey/valkey.sock` cuando las credenciales del proceso de prueba
   permitan acceder al grupo.
8. Verificar que el puerto `6379` no esté enlazado a interfaces distintas de loopback.

En caso de fallo, restaurar los archivos administrados y el estado anterior de la unidad. Si se
añadió correctamente una nueva pertenencia al grupo `valkey`, informar que esta no afecta a la
sesión actual, ofrecer `newgrp valkey` como alternativa manual para un subshell y no intentar
eliminar la pertenencia durante una reversión no relacionada del servicio.

### 6. Añadir helpers reutilizables para operaciones privilegiadas

Cuando la duplicación lo justifique, introducir una pequeña biblioteca cargada mediante `source`
bajo `omarchy/utils/bash/` para:

- comparar e instalar archivos privilegiados;
- crear respaldos con marca temporal;
- registrar los estados habilitado y activo de las unidades;
- restaurar el estado de las unidades;
- mostrar acciones de dry-run.

No extraer helpers prematuramente si el propietario o la semántica de reversión específica del
servicio pierde claridad. Las funciones compartidas no deben ocultar llamadas a `sudo` ni debilitar
las garantías de dry-run.

### 7. Ampliar las pruebas de contrato

Extender `tests/omarchy/setup-contract.sh` o separar las pruebas de servicios en un ejecutable
dedicado cargado por la suite de Omarchy si el archivo se vuelve difícil de mantener.

Cubrir:

- `--services` despacha los helpers de entrada, PostgreSQL y Valkey en orden.
- `--deps` y `--dots-only` no despachan servicios.
- `--non-interactive` llega a los helpers de servicios.
- Dry-run no realiza escrituras, llamadas a `sudo`, operaciones de paquetes ni cambios de servicios.
- Los contratos actuales de dry-run y reversión de keyd y ratbagd permanecen intactos.
- PostgreSQL reconoce un clúster existente.
- PostgreSQL inicializa únicamente un directorio de datos ausente o vacío.
- PostgreSQL rechaza directorios de datos ambiguos que no estén vacíos.
- PostgreSQL inicializa autenticación peer para socket y SCRAM para TCP.
- PostgreSQL conserva TCP restringido a localhost y no administra permisos personalizados del
  socket.
- PostgreSQL no pregunta en modo dry-run ni no interactivo.
- PostgreSQL recarga o reinicia únicamente después de un cambio de configuración.
- PostgreSQL falla cuando la validación de disponibilidad falla.
- Valkey exige que el paquete haya creado el usuario y grupo `valkey`.
- Valkey no añade silenciosamente usuarios al grupo en modo no interactivo.
- Valkey no instala un drop-in con `SupplementaryGroups=`.
- Valkey reinicia únicamente después de un cambio de configuración.
- Valkey valida `PONG` tanto por TCP como por el socket configurado.
- Valkey mantiene TCP restringido a loopback.
- Una validación fallida de servicios ejercita la recuperación de configuración y estado de las
  unidades.

Usar comandos simulados y raíces temporales en lugar de requerir PostgreSQL, Valkey o systemd
activos, o privilegios root, en las pruebas de contrato.

### 8. Actualizar la documentación

Actualizar:

- `README.md` con el resumen ampliado de los servicios de Omarchy.
- `docs/setup.md` con el comportamiento de PostgreSQL y Valkey, las reglas de interacción y la
  semántica de dry-run.
- `docs/post-setup.md` con ejemplos de conexión local por TCP y socket, requisitos de sesión para el
  grupo `valkey`, uso manual opcional de `newgrp` y comandos de diagnóstico si son acciones de
  usuario en lugar de contratos del setup.

Documentar que la fase de servicios puede inicializar un clúster PostgreSQL nuevo, pero no crea
automáticamente bases de datos ni credenciales para aplicaciones.

## Archivos previstos

### Modificados

```text
omarchy/utils/bash/setup-omarchy
omarchy/utils/bash/setup-services
tests/omarchy/setup-contract.sh
README.md
docs/setup.md
docs/post-setup.md
```

### Nuevos

```text
omarchy/utils/bash/setup-services-input
omarchy/utils/bash/setup-services-postgresql
omarchy/utils/bash/setup-services-valkey
omarchy/etc/postgresql/pg_hba.conf
omarchy/etc/valkey/valkey.conf
```

El conjunto final de archivos de Valkey puede usar un fragmento include en lugar de un `valkey.conf`
completo, según el contrato verificado del paquete de Arch.

## Verificación

Ejecutar el formateo antes del lint de la documentación y luego la suite completa de contratos:

```bash
prettier --write README.md docs/setup.md docs/post-setup.md \
  docs/plans/omarchy-postgresql-valkey-services.md
markdownlint-cli2 README.md docs/setup.md docs/post-setup.md \
  docs/plans/omarchy-postgresql-valkey-services.md
./tests/run.sh omarchy
./tests/run.sh
git diff --check
```

Realizar la validación manual en un host de prueba con Omarchy 4 después de que pasen las pruebas de
contrato:

1. Ejecutar la fase completa de servicios en modo dry-run y confirmar que no haya modificaciones.
2. Ejecutarla en un host sin bases de datos inicializadas.
3. Ejecutarla nuevamente y confirmar que no haya respaldos ni reinicios innecesarios.
4. Confirmar la autenticación peer de PostgreSQL por socket y SCRAM por TCP en loopback.
5. Confirmar que PostgreSQL no escuche en interfaces externas.
6. Confirmar que Valkey responda `PONG` por TCP y por su socket Unix.
7. Confirmar que Valkey no escuche en interfaces externas.
8. Confirmar que keyd y ratbagd permanezcan habilitados y funcionales.
9. Probar una configuración inválida controlada para verificar la recuperación sin arriesgar datos
   reales.

## Criterios de aceptación

- Se preserva el comportamiento existente de keyd y ratbagd.
- PostgreSQL se inicializa únicamente cuando es seguro y queda disponible localmente después del
  setup.
- PostgreSQL usa peer por socket, SCRAM por TCP y limita TCP a localhost.
- Los datos existentes de PostgreSQL nunca se eliminan ni reinicializan.
- Valkey está restringido al acceso local y responde tanto por TCP como por su socket Unix.
- El socket de Valkey pertenece al grupo `valkey` suministrado por el paquete.
- No se usa `SupplementaryGroups=` para intentar modificar las credenciales de la sesión del
  usuario.
- Los modos dry-run y no interactivo no realizan preguntas ni modificaciones no previstas.
- Las ejecuciones repetidas no producen respaldos, escrituras de configuración ni reinicios de
  servicios innecesarios.
- Los archivos privilegiados modificados se respaldan y pueden recuperarse.
- Los fallos de servicios intentan restaurar la configuración y el estado anterior de las unidades,
  e informan claramente la recuperación manual residual.
- Pasan las pruebas de contrato de Omarchy y del repositorio completo.

## Política de pertenencia al grupo Valkey

El setup interactivo preguntará si debe añadir al usuario actual al grupo `valkey`. El modo no
interactivo no modificará la pertenencia a grupos. Después de añadir el usuario, el setup indicará
que debe iniciar una nueva sesión para que todos sus procesos reciban las nuevas credenciales y
mostrará `newgrp valkey` únicamente como alternativa manual para abrir un subshell inmediato.
