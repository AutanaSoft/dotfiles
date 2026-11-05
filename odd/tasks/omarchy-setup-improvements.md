# Omarchy setup improvements

Scope: improve profile setup safety and simplify where justified. No commits without an explicit request.
Delivery: existing branch; verification: `./tests/run.sh omarchy`.

## Specs

- S1: «analiza @omarchy/ luego necesito a nalices los script que configuran ese perfil.
necesito que me des un resumen de como el script implementa la configuraciones, tambien si podemos mejorar y simplificar los script para la configuracion del perfil.»
- S2: «ok comienza»

## Tasks

- [ ] T1 (S1–S2): Prevalidate dotfiles manifest before application; route inline; commit: not authorized.
- [ ] T2 (S1–S2): Improve service installation recovery and Valkey listener validation; route inline; commit: not authorized.
- [ ] T3 (S1–S2): Address font reproducibility and cleanup consistency; route inline; commit: not authorized.
- [ ] T4 (S1–S2): Evaluate safe shared simplification and complete verification; route inline; commit: not authorized.

## Log

- L1: «analiza @omarchy/ luego necesito a nalices los script que configuran ese perfil.
necesito que me des un resumen de como el script implementa la configuraciones, tambien si podemos mejorar y simplificar los script para la configuracion del perfil.»
- L2: «ok comienza»
- Review: suggested prevalidation, service recovery and Valkey validation, font reproducibility, cleanup consistency, and cautious shared extraction. Repository policy prohibits commits without an explicit request.
- T1: Added prevalidation and focused regression tests. Observed RED for a late invalid action; focused test, Omarchy suite, Bash syntax and `git diff --check` passed after the change.
- T1 blocker: independent verifier admission rejected the launch because the task did not include a recognized Risk declaration; it must not be retried. Native assessment was unassessable because untracked files require selection. Changes remain uncommitted; T2–T4 have not started.
- Native review `review-8051ff83a9e23ce2` approved and acknowledged for the two T1 source/test files, excluding this untracked task document. Non-blocking findings: R3-001 (`setup-dots:119`), R4-001 (`setup-dots:118`). Native review does not replace the unavailable independent verifier.
- L3: «ok ya las revise y estan bien.» User reports reviewing and accepting the changes; independent verifier remains unavailable.
