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

## Tasks

- T1 | S1-S3 | delegated, context backstop | blocked | Implementation and focused writer checks
  passed; awaiting user disposition because independent safety proof is unavailable. No commit.
- T2 | S1-S3 | independent verification + parent spot check | blocked | Awaiting independent
  evidence supplied by the user; verifier setup failed and will not be retried. No commit.

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
