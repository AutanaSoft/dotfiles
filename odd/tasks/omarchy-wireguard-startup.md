# Omarchy WireGuard startup

Objective: integrate the approved host setup into the Omarchy profile without tracking VPN secrets.
Branch: feature/omarchy-wireguard-startup. Verification: `./tests/run.sh omarchy`, `./tests/run.sh`.
No commits or publishing without a new explicit request (AGENTS.md).

## Specs

- S1: User request: "Ok, en base a esta implementación necesito ver la posibilidad de incluirla en
  el perfil para un mercado, de tal manera que se instale el WideWord Tool y se instalen las
  configuraciones necesarias que hicimos ahorita para que se ejecute al iniciar el sistema."
- S2: Accepted clarification: "¿Te refieres al **perfil `omarchy` de este repositorio**, para que
  instale `wireguard-tools` y configure el inicio de `wg-quick@wg0` con la comprobación de
  conectividad y los reintentos que acabamos de aplicar, **sin guardar claves privadas ni el
  contenido de `wg0.conf` en Git**?" Response: "Sí, me refiero al perfil de Omarchy."
- S3: Previously approved implementation plan: "Sí, creo que la segunda opción es la más indicada.
  ¿Me podrías dar el plan para implementar la segunda opción?" Authorization: "Si me parece bien,
  vamos a aplicar esta configuración junto con las otras que había recomendado anteriormente."

- S4: Manual review conclusion: "Conclusión: requiere correcciones. Reproduje los dos problemas
  pendientes: una segunda ejecución puede declarar éxito sin reintentar daemon-reload, y la prueba
  de WireGuard inspecciona el directorio del drop-in fuera de su raíz de prueba."

## Tasks

- T1 | S1-S4 | delegated, context backstop | done | Both manual-review findings corrected with
  observed RED/GREEN, four isolated tests and doc checks passing. Original commit: e6a3746;
  corrections remain uncommitted.
- T2 | S1-S4 | parent targeted recheck + manual independent evidence | done | Parent checks and
  independent manual review approved both corrections; seven isolated invocations exit 0, including
  the sandbox directory decoy. Limits retained in L13; corrections remain uncommitted.

## Log

- L1: "Ok, en base a esta implementación necesito ver la posibilidad de incluirla en el perfil para
  un mercado, de tal manera que se instale el WideWord Tool y se instalen las configuraciones
  necesarias que hicimos ahorita para que se ejecute al iniciar el sistema."
- L2: "Sí, me refiero al perfil de Omarchy."
- L3: Existing dependencies already include wireguard-tools and systemd-resolvconf. Integrate
  through the explicit --services phase, preserving deps-only and dots-only behavior. The approved
  host drop-in sets StartLimitIntervalSec=0, ExecStartPre=/bin/sh -c 'test "$$(/usr/bin/timeout 5s
  /usr/bin/nmcli --wait 3 networking connectivity)" = full', Restart=on-failure, RestartSec=15s.
  Secure an existing wg0.conf to 0600 and enable boot without --now; do not create/import a VPN
  profile or start/restart the tunnel. Absent config is reported and never causes disabling an
  existing service. Identical drop-ins are reusable; differing local content must be preserved and
  reported, not silently overwritten. Dry-run must not escalate or mutate.
- L4: Baseline 3ebd7ba893e77a04d374b585239e2aad57212c12, clean tree. Risk: items 2 and 5 (root-owned
  secret permissions and system service installation). Forecast: one cohesive behavior unit,
  approximately 300-450 authored changed lines including isolated tests and documentation; report
  actual review load without cosmetic shrinking. No PR or commit requested. Real offline boot
  testing remains outside scope because interruption was not authorized.
- L5: Writer produced the integration, tests and docs. RED: missing helper, exit 1. GREEN: focused
  WireGuard contracts, exit 0; parent reran and confirmed exit 0. Both current and baseline
  `3ebd7ba893e77a04d374b585239e2aad57212c12` Omarchy suites fail with exit 1 at the same untouched
  assertion: `FAIL: missing Pi manifest entry: agent/settings.json`. This is now a verified
  pre-existing failure; no permission to change the Pi test is implied. Full suite also failed at
  that assertion in writer checks. Independent verification is running; T1 remains open until any
  in-scope blockers are resolved. Native read-only assessment was unassessable due to untracked
  files; its returned high-risk plan requires writer checks plus independent verification. RDD is
  off; no native review lifecycle operations were run.
- L6: Independent verifier stopped before probes because its scratch copy used unsupported
  `cp --exclude=.git` (exit 1). Independent verification is unavailable; no verifier retry or
  replacement is authorized by the current bounded workflow. S1-S3 remain independently unverified.
  Static concerns, not reproduced: a daemon-reload failure after installation may be masked by an
  identical-drop-in rerun, and the test sudo shim does not remap the drop-in directory (only its
  file). These concerns were not fixed or declared proven. Needs user decision on retaining the
  unverified diff for manual review; at that stop there was no commit, no host application, and no
  claim of completion.
- L7: User requested: "vamos a generar el commit de los cambios." After the proposed message and
  explicit disclosure of incomplete independent verification, unproven concerns and the existing Pi
  suite failure, the user approved: "si". A local snapshot commit is authorized with subject
  `feat(omarchy): configure WireGuard boot connectivity checks`; this does not complete T1/T2,
  authorize applying setup to the host, or authorize publishing. Verification remains blocked.
- L8: User supplied the independent manual review below. This supersedes the absence of an
  independent finding reproduction, not the record of the earlier verifier infrastructure failure.
  Reopen T1/T2 for one bounded correction batch and a recheck limited to those findings. No live
  host operation, unrelated Pi fix, new commit, or retry of the unavailable verifier is authorized.

> Conclusión: requiere correcciones. Reproduje los dos problemas pendientes: una segunda ejecución
> puede declarar éxito sin reintentar daemon-reload, y la prueba de WireGuard inspecciona el
> directorio del drop-in fuera de su raíz de prueba.
>
> En feature/omarchy-wireguard-startup, git status --short, git diff y git diff --cached no
> mostraron cambios. Los tres archivos solicitados están bajo seguimiento. Revisé el helper
> (omarchy/utils/bash/setup-services-wireguard), el drop-in
> (omarchy/etc/systemd/system/wg-quick@wg0.service.d/90-networkmanager-connectivity.conf), la prueba
> de WireGuard (tests/omarchy/setup-wireguard.sh), las otras tres pruebas solicitadas y sus helpers
> compartidos.
>
> El helper no contiene operaciones para crear ni imprimir claves; conserva el contenido de wg0.conf
> y rechaza un drop-in local diferente. Para una configuración existente, solicita root:root y modo
> 0600; habilita el servicio sin iniciarlo ni reiniciarlo. Su --dry-run termina antes de ejecutar
> operaciones privilegiadas. Los errores comprobados se notifican, salvo el problema de recuperación
> siguiente:
>
> - Al simular un fallo de daemon-reload, la primera ejecución devolvió 1. La segunda reutilizó el
>   archivo instalado, ejecutó enable y devolvió 0, sin volver a intentar la recarga. La condición
>   está en el helper, línea 86 (omarchy/utils/bash/setup-services-wireguard:86).
> - El shim de la prueba, línea 35 (tests/omarchy/setup-wireguard.sh:35) redirige el archivo del
>   drop-in, pero no su directorio. Para verificarlo sin consultar el /etc real, creé un enlace
>   simbólico en el /etc aislado: la prueba cambió de PASS a FAIL: expected status 0, got 1.
>
> Ejecuté las cuatro pruebas mediante bwrap, con /etc y /tmp temporales y el resto del sistema
> montado de solo lectura. Con un shim de omarchy que informa la versión 4.0.0, todas devolvieron 0:
>
> - bash tests/omarchy/setup-wireguard.sh
> - bash tests/omarchy/setup-contract.sh
> - bash tests/omarchy/setup-services-recovery.sh
> - bash tests/omarchy/setup-native-db-retirement.sh
>
> Sin ese shim, WireGuard pasó, pero las otras tres pruebas fallaron al no poder determinar la
> versión de Omarchy. La simulación adicional de daemon-reload usó sustitutos para los comandos
> privilegiados y no operó sobre la VPN.
>
> No ejecuté el instalador sobre la instalación actual, no usé una máquina virtual ni comprobé
> cambios reales de propietario o de estado de systemd: las pruebas interceptan esas operaciones.
> Tampoco ejecuté la prueba de Pi. El repositorio permanece sin cambios.

- L9: The bounded correction worker added unverified reload-recovery and symlink-directory
  regression cases in tests/omarchy/setup-wireguard.sh, but did not change the production helper,
  directory mapping, or docs. bwrap preparation failed before behavior execution: exit 1,
  `/dev/null: Permission denied`, then `required command 'sudo' is not on PATH`. This is
  infrastructure failure, not RED for either reported bug. No GREEN, broad suite, or further
  correction verification ran. The worker stopped without retry; preserve its partial edits. Needs
  user decision: provide the known-working bwrap invocation/environment from the manual review
  before resuming. No commit, host changes, or VPN operations performed.
- L10: The user supplied the working sandbox prerequisite below. Resume the existing correction
  batch, not a new verification sweep or retry of the unavailable independent verifier. Use the
  supplied mounts including --dev-bind; preserve individual test exit codes and propagate any
  failure from the outer loop instead of accepting its final printf status.

> Usé esta invocación desde la raíz del repositorio. bwrap monta el sistema de archivos de solo
> lectura, crea /etc y /tmp temporales y expone /dev con --dev-bind, incluido /dev/null:

```bash
bwrap \
  --ro-bind / / \
  --tmpfs /etc \
  --tmpfs /tmp \
  --dev-bind /dev /dev \
  --proc /proc \
  -- bash -c '
    mkdir -p /tmp/review-bin
    printf "#!/usr/bin/env bash\nprintf '\''4.0.0\\n'\''\n" \
      > /tmp/review-bin/omarchy
    chmod +x /tmp/review-bin/omarchy
    export PATH="/tmp/review-bin:$PATH"

    for test_file in \
      tests/omarchy/setup-wireguard.sh \
      tests/omarchy/setup-contract.sh \
      tests/omarchy/setup-services-recovery.sh \
      tests/omarchy/setup-native-db-retirement.sh
    do
      printf "RUN %s\n" "$test_file"
      bash "$test_file"
      printf "EXIT %s: %s\n" "$test_file" "$?"
    done
  '
```

> Las cuatro pruebas devolvieron 0. El shim de Omarchy solo proporciona una versión 4.x para las
> comprobaciones de contrato; las propias pruebas crean sus sustitutos de sudo, systemctl y otros
> comandos en directorios temporales y los anteponen a PATH.
>
> No usé --unshare-net: en este entorno falló al crear el socket de loopback. El aislamiento de /etc
> sigue siendo relevante porque el shim original de WireGuard no redirige la inspección del
> directorio del drop-in. La invocación anterior no permite escribir en el repositorio; para
> desarrollar las correcciones hay que editarlas fuera de bwrap y volver a ejecutar las pruebas
> dentro.

- L11: The supplied sandbox worked. Separate REDs reproduced both findings: reload-retry exited 1
  with `FAIL: second invocation did not retry daemon-reload`; symlink-directory exited 1 with
  `FAIL: expected status 1, got 0`. Helper now reloads after installing or identical reuse before
  config mutation/enablement; test remaps the directory and rejects unmapped privileged /etc args.
  GREEN: all four affected isolated tests exit 0, syntax and docs checks pass. No host changes.
  Parent readback confirmed minimal helper change and regression coverage. High-risk assessment
  requires independent proof; the failed verifier will not be relaunched. Native assessment also
  returned reviewDue=true, reviewDueReason=high_risk and a review.status continuation; RDD is off,
  so no native lifecycle operation will be executed.
- L12: Parent targeted recheck initially failed before test setup because inherited TMPDIR pointed
  to /tmp/gpZSTxE2, hidden by the sandbox /tmp mount. Corrected only the sandbox environment to
  TMPDIR=/tmp. Second local self-check exited 0: reload-retry, reload-failure and symlink-directory
  cases plus all four affected test scripts passed (7 command invocations), with exact exit codes
  propagated. Syntax, Prettier, Markdown lint and diff whitespace checks passed. General suites were
  not rerun because of the verified pre-existing Pi manifest failure. No live ownership, systemd
  state, boot or VPN operations were tested. T2 awaits manual independent correction confirmation,
  not another automated verifier run. Corrections remain uncommitted; no host apply.

- L13: Independent manual correction review approved. Reviewer supplied the following evidence; T2
  is complete for the two findings only. The tracking document is parent-owned bookkeeping, not part
  of the reviewer-approved code diff. No new commit, publishing, or live host operation is
  authorized by this approval.

> Conclusión: aprobado para los dos fallos revisados.
>
> - Recuperación de daemon-reload: el helper recarga después de instalar o reutilizar el drop-in y
>   antes de modificar permisos o habilitar el servicio. Las pruebas verificaron el reintento tras
>   un fallo y que dos fallos consecutivos no habilitan el servicio ni modifican el perfil. El
>   código conserva el rechazo de contenido local diferente y no añade operaciones de inicio, parada
>   o reinicio.
> - Aislamiento del directorio: el shim redirige tanto el directorio como el archivo y rechaza las
>   rutas /etc/* no contempladas. El caso de directorio simbólico dentro de la raíz de prueba pasó;
>   también pasaron las siete ejecuciones con el enlace señuelo en el /etc temporal.
>
> | Ejecución                     | Salida |
> | ----------------------------- | -----: |
> | reload-retry                  |      0 |
> | reload-failure                |      0 |
> | symlink-directory             |      0 |
> | setup-wireguard.sh            |      0 |
> | setup-contract.sh             |      0 |
> | setup-services-recovery.sh    |      0 |
> | setup-native-db-retirement.sh |      0 |
> | Resultado global              |      0 |
>
> No encontré hallazgos dentro del alcance solicitado. Revisé el diff de el helper
> (omarchy/utils/bash/setup-services-wireguard), la prueba (tests/omarchy/setup-wireguard.sh) y la
> documentación indicada. El estado también muestra cambios en
> odd/tasks/omarchy-wireguard-startup.md, fuera del diff solicitado.
>
> La revisión usó shims y un /etc temporal: no verificó una recarga real de systemd ni aplicó el
> instalador al equipo. La prueba de Pi y el arranque real sin red quedaron fuera del alcance.
