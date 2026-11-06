# Retire Omarchy native databases

Branch: `chore/omarchy-docker-db`; integrate locally into `main`. Remove native database support and
preserve host data. Commit and integration authorized; no push. Runner: `./tests/run.sh`.

## Specs

- S1: "ya omarchy ofrece por medio de Docker DB instancias de postgres y redis, por lo cual el
  soporte local para postgresql y valhey no son necesarios. debemos retirar el soporte en el perfil,
  y tambien vamos a eliminar las instalaciones locales."
- S2: "antes de aplicar dame el plan de implementacion."
- S3: "si, pero ejecuta en una nueva rama."
- S4: "si autorizo la lectura"
- S5: "no hay nada en el postgresql local, no lo habia usado. lo que si es que tienes que detener la
  ejecucion de los servicios de postgres y valkey y eliminar los servicios para que no se vuelvn a
  ejecutar."
- S6: "ok, como no podemos hacer esa revision tecnica independiente, ya que es algo compleja para yo
  realizarla, y tu no la pudes realizar y tomarla como idependiente. no queda solo generar el commit
  y integrar los cambios al main."

## Tasks

- T1 [S1, S3] inline — done: Removed Omarchy database dependencies, helpers, configurations and
  exclusive tests; updated current docs and marked historical plan; keyd and Fedora retained. Three
  retirement rules observed RED then GREEN; full suites pass. Commit:
  `d4d364554c73892292c00f156ff7adaa37891536`.
- T2 [S1, S6] inline + independent verify — dropped: Self-checks pass; independent verifier
  unavailable after runtime admission rejection, never executed or retried. User explicitly elects
  local commit/integration with that missing proof acknowledged. This is not independent approval.
  Native assessment remains unassessable; RDD stays off.
- T3 [S1, S4, S5] parent only — dropped: Read-only inventory completed; user states PostgreSQL was
  unused and declines client download/database backup. Database dump/recovery work is no longer
  authorized or required by the revised scope. No database contents will be deleted.
- T4 [S1, S5] parent only — done: Stopped native PostgreSQL/Valkey; removed Valkey package and both
  obsolete startup links. PostgreSQL package was already absent. Masked PostgreSQL, Valkey and Redis
  alias against future starts; verified inactive units, no server processes/listeners, absent
  packages, retained data/configuration copies and unchanged Docker inventory. Commit: not
  applicable.

- T5 [S6] inline — done: Implementation committed as `d4d364554c73892292c00f156ff7adaa37891536` on
  the feature branch and fast-forwarded into local main. Closing evidence recorded here; no push
  performed.

## Log

L1 User original request: "en el perfil de omarchy estamos instalado postgresql.\n\npero ahora
omarchy ofrece Docker DB, necesito eliminar la instalacion de postgresql local."

L2 User scope correction: "ya omarchy ofrece por medio de Docker DB instancias de postgres y redis,
por lo cual el soporte local para postgresql y valhey no son necesarios. debemos retirar el soporte
en el perfil, y tambien vamos a eliminar las instalaciones locales.\n\nantes de aplicar dame el plan
de implementacion."

L3 User approval: "si, pero ejecuta en una nueva rama."

L4 Approved plan: remove PostgreSQL and Valkey from Omarchy only; retain keyd services and Fedora
unchanged; remove exclusive helpers/configurations/tests, update current documentation and mark
prior plan historical. Test-first, full tests and shared dispatcher Fedora differential. Before
local uninstall identify actual native units/packages/dependents, validate backups and recovery,
show exact removal scope. Preserve existing data/configuration, users/groups and Docker. No
automatic migration, commits or push. Stop on unexpected dependencies, unavailable proof or required
permission.

L5 Branch created from clean main: `chore/omarchy-docker-db`. Initial package query reports Valkey
9.1.2-1 installed; PostgreSQL package identity remains unresolved. No host mutations performed.
Database test boundary exploration delegated read-only to gentle-ai-explore (mw5irsr4-1-nd4f).

L6 Verification: all three new retirement checks failed before implementation (exit 1) and passed
following changes (exit 0). Full `./tests/run.sh` passed (job-1, exit 0), including keyd, caller
isolation, dots, fonts, cleanup and Fedora contracts. Six Fedora differential cases against HEAD
matched stdout, stderr and exit status after normalizing checkout paths: services, deps, locale,
dots-only non-interactive dry-runs; rejected services+fonts dry-run; interactive dots dry-run.
Prettier ran before markdownlint-cli2 (exit 0); `bash -n` on all edited shell files and
`git diff --check` passed. Shellcheck is unavailable. Roughly 3,500 removed lines mostly delete the
obsolete Valkey configuration and database helpers/tests; no unrelated restructuring.

L7 Risk: item 5 (dependency and native service provisioning removal). Native ASSESS returned
unassessable because untracked files need declaration; no lifecycle operations or retries performed.
Independent verifier launch was rejected by runtime admission because it did not recognize a literal
Risk declaration in the task; verifier unavailable, not retried or escalated.

L8 Host inventory (read-only metadata only): Valkey 9.1.2-1 has no reverse dependencies and its
removal preview names only Valkey. Enabled valkey.service has redis.service as an alias. PostgreSQL
PID 1347 still runs `/usr/bin/postgres -D /var/lib/postgres/data`, but no PostgreSQL package, tools
or loaded unit file were found (unit LoadState=not-found, ActiveState=active). Valkey PID 1332 is
running; listeners on localhost 5432 and 6379 remain active. Docker listing failed with socket
permission denied. No service, package, database or Docker mutations occurred. Need path-specific
read authorization for native data/configuration, PostgreSQL process executable, package recovery
cache and Docker socket before inventory/backups can safely proceed.

L9 User authorization: "si autorizo la lectura". Read scope: `/var/lib/postgres/`,
`/run/postgresql/`, `/etc/valkey/`, `/var/lib/valkey/`, `/proc/1347/exe`, `/var/cache/pacman/pkg/`,
`/var/run/docker.sock`. Current continuation is read-only on the host; no backup creation, package
restore or service stop has been performed.

L10 Read-only inspection found cached PostgreSQL 18.6-4 and Valkey 9.1.2-1 packages. `pacman -Qip`
reports the PostgreSQL signature valid with full trust; archive contains the server binary and
service unit, but not `psql`, `pg_dump`, `pg_dumpall` or `pg_restore`. No cached postgresql-libs
package was found. Recovery therefore remains unproven. Explorer confirmed Valkey file configuration
uses `/var/lib/valkey/dump.rdb`, appendonly disabled, no active include or auth directives; runtime
state is checked separately. Privileged read-only inventory launched as job-2; completed
successfully (exit 0), authenticated through native pkexec.

L11 Read-only results: PostgreSQL executable resolves to `/usr/bin/postgres (deleted)` and
`PG_VERSION` is 18; approximately 40.6 MB of cluster files remain. This confirms that stopping the
process before establishing recovery could leave it unable to restart. Valkey reports an empty
keyspace, zero changes since last save, appendonly disabled, successful RDB persistence status and
an 89-byte dump.rdb. Docker daemon query succeeded and reported no containers, including stopped
ones; no Docker mutation occurred. PostgreSQL database contents have NOT been inventoried: no client
tools are installed. Pacman metadata offers postgresql-libs 18.6-4 (client binaries and libraries),
absent both from installed packages and cache; local file-list query also unavailable. Next proposed
step needs authorization beyond the latest read-only grant: obtain compatible client tools in
repository-local scratch space, inventory databases, create and validate backups under backup/, and
establish recovery without reinstalling a native server. No backups, downloads, extractions,
reinstalls, service stops or package removals have been performed. Independent verification remains
unavailable as recorded in L7; it was not retried.

L12 User revised disposition (verbatim): "no hay nada en el postgresql local, no lo habia usado. lo
que si es que tienes que detener la ejecucion de los servicios de postgres y valkey y eliminar los
servicios para que no se vuelvn a ejecutar."

L13 No PostgreSQL tools download, reinstall or database backup. User explicitly authorizes stopping
and retiring both native services; preserve existing data/configuration, Docker and unrelated work.
Current metadata confirms PostgreSQL running with package/unit absent, and only Valkey 9.1.2-1 in
the removal transaction. Cached Valkey install script has only post_upgrade, no removal callback;
package owns service units and two configuration files, not data files. Preserve both configuration
files before removal, disable service startup before package removal, and reload systemd. Parent
only performs maintenance; independent verifier remains unavailable and is not retried.

L14 Parent maintenance job-3 completed with exit 0 under native pkexec consent. Configuration copies
verified with SHA-256 before removal and retained under
`backup/local-db-retirement-20261106T221817Z/valkey-config/` (root-only parent directory). Disabled
Valkey, stopped both native services, removed the proven obsolete PostgreSQL startup symlink, and
uninstalled only Valkey 9.1.2-1 (no recursive dependency removal). Pacman also retained modified
Valkey configuration as `/etc/valkey/valkey.conf.pacsave`. Masked postgresql.service, valkey.service
and redis.service; all three verified LoadState=masked, ActiveState=inactive, MainPID=0. Package
absence checks returned expected exit 1 for PostgreSQL, PostgreSQL libraries (already absent) and
Valkey. pgrep found no postgres/valkey-server/redis-server processes (expected exit 1); ss on ports
5432/6379 returned exit 0 with empty output. PostgreSQL PG_VERSION and Valkey dump.rdb remain
present; Docker inventory before/after is identical (empty). No database dump, client download,
server reinstall, database deletion, Docker mutation, commit or push occurred. Full functional
output: `/tmp/gpydM7NE/gentle-jobs-Ffe3nK/job-3.log`. No failing functional checks; repository
independent verification remains unavailable (T2), with no retry or escalation.

L15 User authorization (verbatim): "ok, como no podemos hacer esa revision tecnica independiente, ya
que es algo compleja para yo realizarla, y tu no la pudes realizar y tomarla como idependiente. no
queda solo generar el commit y integrar los cambios al main."

L16 Commit/integration authorized despite acknowledged unavailable independent proof; no claim that
manual acceptance substitutes for technical verification. Initial main and feature HEAD match
b5c678cc3641251272fc6ba98320d3d5b133259c. Preserve all task changes and exclude ignored host
backups. Implementation message: `chore(omarchy)!: retire native database provisioning`, with
breaking-change footer documenting that Omarchy deps/services no longer provision native
PostgreSQL/Valkey. No source changes since passing checks. Implementation commit first; local
fast-forward main; closing tracker evidence in a separate documentation commit. No push authorized.

L17 Implementation commit `d4d364554c73892292c00f156ff7adaa37891536`
(`chore(omarchy)!: retire native database provisioning`) created successfully (job-4, exit 0).
`git switch main` and `git merge --ff-only chore/omarchy-docker-db` succeeded; main HEAD now
contains the implementation commit. Feature changes are integrated without rewriting history. Only
this previously untracked task document remains for the closing documentation commit. The
independent review was unavailable, not completed or approved; user disposition is recorded verbatim
in L15. No new runtime checks or reviewer retries were introduced for delivery.
