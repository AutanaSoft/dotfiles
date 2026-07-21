# AGENTS

Strict rules for any agent (human or AI) to work in this repository without breaking conventions.

If a rule here conflicts with an installed skill, this file takes precedence.

Read it completely before your first edit: each section states its scope and limits.

## Repository structure

See [README.md](README.md) for the structure and conventions specific to this repository.

## User communication

- Short, direct answers by default.
- One question at a time. After asking, STOP and wait.

## Commits and pushes

- **Commit**: Do not create or generate without the user's explicit request.
- **Push**: Do not push without the user's explicit request.
- **Skill:** Always use `commit-message` to create or generate commits.

## Inline comments and documentation

- **What to document**: exports (functions, classes, types, interfaces) when the contract is
  not obvious. Skip self-explanatory helpers and one-liners.
- **Content**: the why (intent, decision, gotcha), not the what.
- **Commented-out code**: forbidden. Delete it; git preserves history.

## Code generation

- **Plan before implementing**: before any change, deliver a plan with scope, affected files,
  and steps. Do not execute until the developer approves.
- **Zero assumptions**: do not invent APIs, conventions, or behaviors. Verify against official
  documentation (cite URL + version) or ask the developer. Memory and "probably" are not evidence.
- **No implicit changes**: do not touch files outside the scope declared in the plan.
- **If the user flags an error**: verify against documentation before accepting or rejecting.

## User changes to generated code

- **Assume intent**: any difference between the generated code and what is in the repository
  is, by default, intentional.
- **Do not revert without confirmation**: do not undo, rewrite, or "fix" those changes without
  explicit confirmation.
- **How to ask**: if something looks like an error or bug, raise the observation with evidence
  (URL, line, diff) and ask before touching anything.
- **Exception**: if the user explicitly asks to revert or adjust ("go back", "apply this instead
  of the previous one"), proceed.
