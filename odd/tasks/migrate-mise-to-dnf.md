# Migrate Mise to DNF

## Goal

Replace the standalone Mise installation with the official Fedora COPR package managed by DNF, while
preserving the existing Mise configuration and installed tools.

## Scope

- Update the Fedora WSL2 dotfiles installer to install Mise through `jdxcode/mise` COPR and DNF.
- Resolve Mise through `PATH` during shell activation instead of assuming `~/.local/bin/mise`.
- Update repository tests and documentation affected by the installation contract.
- Install the RPM in the current environment, verify it, and remove the old standalone binary only
  after successful installation.

## Tasks

- [x] Record the migration plan and current installation evidence.
- [x] Adapt dotfiles, tests, and documentation for DNF-managed Mise.
- [x] Install the DNF-managed package and remove the standalone binary safely.
- [x] Run focused repository checks and `mise doctor`.
- [ ] Resolve the pre-existing Herdr pin mismatch that prevents the complete Fedora contract suite
      from running.

## Evidence

- Installed package: `mise-2026.9.11-1.fc44.x86_64` from `jdxcode/mise` COPR.
- Active executable: `/usr/sbin/mise`, owned by the Mise RPM.
- Removed standalone executable: `~/.local/bin/mise`.
- `mise reshim` restored all managed shims; `mise doctor` reports no problems and one existing
  PATH-order warning for `~/.pi/agent/bin`.
- Bash syntax, Prettier, markdownlint, and `git diff --check` passed.
- The Fedora contract suite stops on an unrelated existing mismatch: the test expects Herdr `0.8.2`,
  while both `HEAD` and the current configuration use `latest`.
- Work-unit commit: `chore(mise): install Mise through Fedora COPR`.
