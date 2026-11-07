# Post-Setup

Run-once manual steps that `./setup --profile omarchy --dots` cannot finish for you — sudo tweaks,
partition mounts, secrets, and service auth. Each section is independent; rerun any single one
without touching the rest.

## Sudo Password Feedback

By default, sudo prints nothing while you type the password. A sudoers drop-in restores asterisks:

```bash
# 1. Drop in the sudoers file
sudo tee /etc/sudoers.d/10-pwfeedback >/dev/null <<'EOF'
Defaults pwfeedback
EOF

# 2. Lock permissions
sudo chmod 0440 /etc/sudoers.d/10-pwfeedback

# 3. Validate
sudo visudo -c
```

Reload the shell and verify with `sudo -K && sudo true`.

## Personal fstab

The personal `fstab` lives in the repo at [`omarchy/etc/fstab`](../omarchy/etc/fstab). Edit it
there, then apply on the host:

```bash
# 1. Install from the repo
sudo install -m 644 omarchy/etc/fstab /etc/fstab

# 2. Reload systemd
sudo systemctl daemon-reload

# 3. Mount everything
sudo mount -a
```

Use `nofail` for any drive that may be detached, so a missing disk does not block boot.

## SSH

The Omarchy manifest does not currently manage `~/.ssh/config`; create and maintain that file
locally so host names and key paths stay machine-specific. This repository does not provide an SSH
template. If you use direct key files, the files should have the right permissions:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519_*
chmod 644 ~/.ssh/id_ed25519_*.pub
```

## GitHub CLI Auth

`./setup --profile omarchy --dots` does not authenticate against GitHub. Run:

```bash
gh auth login
```

Pick SSH or HTTPS and follow the prompts. Confirm:

```bash
gh auth status
ssh -T git@github.com   # if SSH
```

## WireGuard

Install the declared tools with `--deps`, then place your private peer configuration on the host;
never add `wg0.conf` or private keys to this repository. The services phase integrates the approved
boot behavior without bringing the tunnel up during setup:

```bash
./setup --profile omarchy --deps
sudo install -m 600 /path/to/wg0.conf /etc/wireguard/wg0.conf
./setup --profile omarchy --services
```

`--services` enforces root ownership and mode `0600`, installs the tracked non-secret systemd
connectivity/retry drop-in, then reloads systemd after installing it or verifying an identical
existing copy. Reruns therefore retry a previously failed reload before enabling
`wg-quick@wg0.service` for boot. It does not start, stop, or restart WireGuard. If the config is
absent, setup reports the skip and leaves any existing unit enablement state unchanged; the
non-secret drop-in may still be installed. Rerun `--services` after placing the config to enable
boot. A symlink or other unsafe config path is rejected. An identical local drop-in is reused, but a
differing one is preserved and reported as a conflict. Required tools must already be available; the
services phase does not install packages.

The unit checks for full NetworkManager connectivity before starting and retries a failed start
after 15 seconds. Review the host's `/etc/wireguard/wg0.conf` separately when verifying the tunnel.

## Databases through Docker DB

Manage PostgreSQL and Redis instances through Omarchy Docker DB, independently of this repository.
The Omarchy profile does not install, initialize, configure, or start native database servers;
`./setup --profile omarchy --services` manages only keyd.

Removing packages from the profile does not uninstall servers already on a machine. Before retiring
native PostgreSQL or Valkey, inventory their databases and dependencies, create and verify backups,
and establish a recovery path. Stop and disable only the identified native services, then remove
only their server packages. Preserve data directories and configuration; do not remove shared client
libraries or touch Docker containers and volumes. Data migration is a separate manual operation.

## Related Files

- `setup` — dispatcher run before this checklist.
- `omarchy/etc/fstab` — repo source for personal `/etc/fstab`.
- `omarchy/home/ssh/config` — SSH client template (placeholders; copied to `~/.ssh/config` once).
