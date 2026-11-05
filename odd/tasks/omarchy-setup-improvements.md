# Omarchy setup improvements

Scope: improve profile setup safety and simplify where justified. No commits without an explicit
request. Delivery: user-authorized local implementation commit; verification:
`./tests/run.sh omarchy`; independent proof remains pending as recorded below.

## Specs

- S1: «analiza @omarchy/ luego necesito a nalices los script que configuran ese perfil. necesito que
  me des un resumen de como el script implementa la configuraciones, tambien si podemos mejorar y
  simplificar los script para la configuracion del perfil.»
- S2: «ok comienza»
- S3: «necesito que leas @docs/omarchy-setup-improvements-plan.md y vamos a implementarlo.»
- S4: «si» — approval of moving distinct destination symlinks themselves into backup, including
  dangling links, preserving correct links and preview-only dry-run; excludes parent symlinks and
  obsolete monitor cleanup.
- S5: «si» — authorization to advance to services while retaining T1 explicitly incomplete. Scope:
  steps 2 and 3 of `docs/omarchy-setup-improvements-plan.md`; preserve existing interfaces.
- S6: «Ok, podemos avanzar con las siguientes fases de la implementación, o sea, la T3 o la T4, no
  sé cuál es la que sigue.»
- S7: «Sí, apruebo la política.» — preserve existing fonts of uncertain ownership and stop on
  collisions without automatic deletion or overwrite; identify newly installed fonts for updates.
- S8: «Sí, debe conservar la confirmación y el registro de la auditoría sin la eliminación de los
  componentes.»
- S9: «Bueno, pues nada, entonces vamos a dar el plan como implementado y vamos a generar el comi de
  los cambios.»

## Tasks

- [ ] T1 (S1–S2): Prevalidate dotfiles manifest; blocked on unavailable independent proof; code
      committed in 032c61c before this session; do not retry verifier.
- [x] T5 (S3–S4): Preserve distinct destination symlinks; done; route inline (one bounded behavior);
      Risk: item 5 (installer); commit: user-authorized implementation changeset.
- [ ] T2 (S3, S5): Improve service installation recovery and Valkey listener validation; blocked on
      maintainer disposition of remaining proof and parent timeout; route delegated (runtime context
      backstop); Risk: item 5 (installer); commit: user-authorized implementation changeset.
- [ ] T3 (S3, S6–S8): Font and cleanup implementation present; CLEANUP independently verified; FONT
      independent proof unavailable, so T3 remains blocked; route delegated (context backstop);
      Risk: item 5 (installer/removal tooling); commit: user-authorized implementation changeset.
- [x] T4 (S3, S6): Evaluate safe shared simplification and document ordered partial services; done;
      no shared library justified; route delegated exploration + inline help/docs; commit: not
      authorized.
- [ ] T6 (S3): Close global verification; blocked on unavailable independent T1/FONT proof and
      partial terminal T2 result; no further automatic verification; route maintainer disposition;
      commit: user-authorized implementation changeset.

## Log

- L1: «analiza @omarchy/ luego necesito a nalices los script que configuran ese perfil. necesito que
  me des un resumen de como el script implementa la configuraciones, tambien si podemos mejorar y
  simplificar los script para la configuracion del perfil.»
- L2: «ok comienza»
- Review: suggested prevalidation, service recovery and Valkey validation, font reproducibility,
  cleanup consistency, and cautious shared extraction. Repository policy prohibits commits without
  an explicit request.
- T1: Added prevalidation and focused regression tests. Observed RED for a late invalid action;
  focused test, Omarchy suite, Bash syntax and `git diff --check` passed after the change.
- T1 blocker: independent verifier admission rejected the launch because the task did not include a
  recognized Risk declaration; it must not be retried. Native assessment was unassessable because
  untracked files require selection. Changes remain uncommitted; T2–T4 have not started.
- Native review `review-8051ff83a9e23ce2` approved and acknowledged for the two T1 source/test
  files, excluding this untracked task document. Non-blocking findings: R3-001 (`setup-dots:119`),
  R4-001 (`setup-dots:118`). Native review does not replace the unavailable independent verifier.
- L3: «ok ya las revise y estan bien.» User reports reviewing and accepting the changes; independent
  verifier remains unavailable.
- L4: «necesito que leas @docs/omarchy-setup-improvements-plan.md y vamos a implementarlo.»
- L5: «si» — approved destination-link backup policy, excluding parent links and obsolete monitor
  cleanup. Baseline is clean at 032c61c; historical uncommitted-state statements are stale. T5 is
  new behavior, not a retry of T1 verification.
- T5 evidence: RED failed with `FAIL: absolute/dry backup message missing`; GREEN passed the new
  isolated test and integrated `./tests/run.sh omarchy`, Bash syntax, Markdown formatting/lint, and
  `git diff --check`. New test covers absolute, relative, dangling, correct and file targets,
  collisions, dry-run and repeat. Independent T5 verification launched; results pending.
- Assessment: native candidate unassessable pending explicit untracked selection; escalation item 5
  requires independent verification. No native review started for T5 yet.
- T5 independent verification found an in-scope blocker: failed canonical resolutions compared equal
  for distinct dangling source/destination links. Correction batch adds a regression (observed RED:
  `FAIL: dangling-source/dry backup message missing`), checks successful resolution before alias
  comparison, and retains exact direct links even for dangling sources. Added a correct
  canonical-alias preservation case. Limited blocker recheck passed in fresh isolated state: focused
  test and syntax both exited 0; original blocker resolved. T1 was not reassessed.
- T5: parent focused test, full Omarchy suite, syntax, Markdown lint and diff checks passed after
  the correction. Independent verification resolved its blocker. Native review
  `review-6c672bb29c2535b1` approved with three lenses; exact acknowledgement completed and
  authority burned for target
  `sha256:0673434d1b11328e208d63ad8db834ea1fa8ee82f372f59e2bf19080ec36b677`. T5 is complete; no
  source changes after review. T1 still lacks its independent proof, so step 1 as a whole remains
  incomplete; stop for maintainer disposition of that unavailable prerequisite, not another verifier
  attempt. T2–T4 remain unstarted at this point.
- L6: «si» — user authorized advancing to services with T1 explicitly incomplete. T2 starts as one
  bounded delegated unit due to runtime context backstop. Steps 2–3 only; no service selection,
  shared library extraction, commits, package installs, or host mutations.
- T2 writer returned implementation of partial install recovery and checked `ss` capture; reported
  RED for failed listener inspection and GREEN for focused test, Omarchy suite, syntax, docs lint
  and diff check. Parent repeated focused test, Omarchy suite and syntax in a fresh isolated copy:
  all passed. T2 is not complete: independent verification is running.
- T2 isolation defect: two added literal `: >"service_log"` redirections in setup-contract create an
  empty root artifact instead of truncating the temporary log. Artifact absent before writer,
  present afterward; preserved pending correction. Verifier informed; no real service effects.
- T2 independent verification blocked on caller-log isolation and two extra dry-run preview lines
  (baseline comparison proved changed output). Missing proof: full config/state recovery matrix,
  PostgreSQL restore failure, Valkey start failure and successful socket path. One bounded worker
  correction batch dispatched for these issues and tests; no T1 retry and no native review yet.
- T2 correction returned: caller-log variables fixed, exact original dry-run output restored,
  recovery matrices and remaining failure/success probes added. Worker demonstrated base Valkey
  leaves partial bytes whereas candidate restores prior bytes (both exit 1); baseline/candidate
  dry-run stdout/stderr/exit match for both services. Limited independent recheck running.
- Parent post-correction isolated command: focused test passed; combined Omarchy suite timed out at
  30 seconds after printing passing contract, monitor and symlink tests. The trailing recovery suite
  did not report completion; subsequent syntax/diff commands in that chain did not run. Timeout is a
  failed check, not success; do not retry or migrate this command automatically. Prior worker
  reports remain separate evidence. T2 is still incomplete.
- T2 limited recheck: original log-isolation and dry-run blockers resolved. Independent focused
  test, full Omarchy suite and syntax exited 0; existing caller-log SHA-256 preserved, absent log
  not created. Both services' partial-install matrices covered prior/absent config and all four
  enabled/active states; scratch `cmp` probes verified restored and backup bytes. PostgreSQL
  restore-failure reporting, Valkey start failure and successful TCP/socket/listener path passed.
- T2 remaining proof: full baseline/candidate success-path output comparison was not performed;
  verifier explicitly did not establish completion. Parent's separate timeout remains a failed check
  despite independent suite success. Limited correction/recheck has ended; no further automatic
  verification or native review. Needs maintainer disposition; T2 remains incomplete. Root
  service_log artifact remains preserved; no commits or host mutations.
- L7: «si confirmo que quiero deshabilitarlo para este clon» — RDD disabled for clone; native mode
  status confirmed clone-local off, global on. Independent proof boundaries unchanged.
- L8: «Ok, podemos avanzar con las siguientes fases de la implementación, o sea, la T3 o la T4, no
  sé cuál es la que sigue.» T3 discovery started; T1/T2 remain incomplete and are not retried.
  Read-only explorer maps fonts and cleanup decisions before source writes; T4 follows services.
- T3 exploration: fonts overwrite by name without ownership records; hashes not checked and two URLs
  use latest. Cleanup help and confirmation disagree; dry-run writes audit log. No tests or remote
  research run. Await font collision/ownership policy before source changes.
- L9: «Sí, apruebo la política.» Font preservation/collision policy approved; official-source
  release/hash research started before bounded implementation. No system installs or commits.
  Existing unmanaged fonts will not be adopted or overwritten silently; managed records must allow
  repeat runs and protect locally modified fonts. Cleanup contract remains undecided.
- T3 official research: API asset digests obtained for Monaspace v1.400 and Nerd Fonts v3.5.1
  FiraCode/FiraMono from githubnext/monaspace and ryanoasis/nerd-fonts releases. Pinned URLs are
  versioned but release metadata says immutable:false; enforce hashes before extraction/mutation.
  Bounded FONT writer launched with source URLs/digests and isolated tests. Full Omarchy suite is
  parent-owned background verification after return, not a 30-second foreground chain. Cleanup
  unchanged; no native review while RDD is off.
- T3 fonts writer returned partial only because parent suite and cleanup were pending. Reported RED
  for late download leaving early fonts installed; GREEN focused test, contract, syntax, Markdown
  and diff checks. Implemented pinned hashes, all-archive verification/staging and owned file hashes
  with collision/symlink/modified-file protection; old files are not pruned.
- T3 parent job-1: isolated `./tests/run.sh omarchy` and font/test Bash syntax completed with exit 0
  after 19 seconds, including the new font test. Independent FONT verification is running, scoped to
  step5; no native lifecycle while RDD off. T1/T2 outcomes remain unchanged.
- T3 independent FONT verifier setup was rejected because its preparation command contained
  `rm -rf "$d/work/.git"`. It ran no scratch preparation or executable checks; no scratch was
  created and no code defect was confirmed. Focused test, syntax and independent probes remain unrun
  by that verifier. It did not retry. Parent job-1 suite success and writer checks remain separate
  evidence, not a substitute. Verifier unavailable: do not retry or replace it.
- T3 FONT implementation remains incomplete on independent proof. Cleanup still awaits user's
  decision on retaining confirmation and audit logging in dry-run; no cleanup changes made.
- L10: «Sí, debe conservar la confirmación y el registro de la auditoría sin la eliminación de los
  componentes.» Cleanup contract approved: keep confirmation unless existing --yes bypass is used,
  retain audit log, no component removal in dry-run. Bounded cleanup writer starts; no font/T1/T2
  verification retries, real uninstallations, native review or commits.
- T3 cleanup writer reported RED for missing dry-run confirmation help and GREEN for focused
  contract, syntax, docs lint and diff check. Typed category dispatch replaces shell-text execution.
  Parent job-2 runs full isolated Omarchy suite and syntax; independent CLEANUP verifier runs its
  focused checks with copy-time .git exclusions and no preparation/disposal deletion commands.
  Results pending; no cleanup completion claimed, and FONT proof remains unavailable.
- T3 CLEANUP independent verdict: no confirmed blockers; S3/S6/S8 met within cleanup scope. Focused
  contract, syntax and independent mocked PTY probes passed for confirmation/rejection, --yes
  dry-run, selection, failures and invalid option combinations. Parent job-2 Omarchy suite and
  syntax exited 0 after 19 seconds. No real removals. Cleanup portion complete; font proof remains
  unavailable. Pre-existing same-second audit-filename collision is advisory, not scope.
- T4 read-only evaluation starts: compare stabilized service helpers and check plan step4 service
  scope documentation. No extraction unless identical logic clearly improves maintainability; no
  retry/substitution of unavailable T1/T2/FONT verification.
- T4 evaluation recommends keeping service helpers separate: installation ownership/mode,
  reload/restart, initialization, validation and enrollment differ. No shared library introduced.
  Added plan step4 ordered/fail-fast/non-global-rollback explanation to docs/setup.md and the help
  of setup and setup-services, without changing executable logic or flags.
- T4 help check RED: setup help omitted partial service application; GREEN both public --help checks
  passed after edits. Bash syntax, Prettier, Markdown lint and diff check passed. Assessment
  returned self-verification only; native assessment unassessable on untracked selection, no
  lifecycle operation while RDD off. Parent job-3 isolated Omarchy suite pending for this new
  help/docs candidate, not a retry or substitute of unavailable/partial independent proofs.
- T4 completion: job-3 Omarchy suite and setup/setup-services syntax exited 0 after 20 seconds.
  Evaluation and service-scope help/docs are complete; Risk: none for this help/docs-only slice.
  Moved global closure explicitly to T6 rather than marking missing verification complete.
- Final handoff: all planned source changes/evaluation are present, cleanup and destination-link
  units independently verified. T1 independent proof unavailable, T2 terminal partial comparison
  proof, and FONT independent setup rejection remain unresolved. RDD stays clone-local off. No code
  changes after job-3; only tracking updated. No commits/staging/publishing, actual package
  installs/uninstalls, service operations or font installs were performed. Root service_log artifact
  preserved. Global completion cannot be claimed until required proof has a supported disposition.
- L11: «Bueno, pues nada, entonces vamos a dar el plan como implementado y vamos a generar el comi
  de los cambios.» User authorizes the local implementation commit. Record implementation as
  incorporated, NOT all verification approved; retain T1/T2/FONT limitations and T6 blocked. Commit
  includes intended source/tests/docs/tracking only; root service_log remains untracked and
  untouched. No push or host application authorized. Message approval is pending per skill.
