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

`wireguard-tools` is not pre-installed:

```bash
# 1. Install the userland tools
yay -S --needed wireguard-tools

# 2. Drop in your peer config (replace /path/to/wg0.conf)
sudo install -m 600 /path/to/wg0.conf /etc/wireguard/wg0.conf

# 3. Start on boot and bring the tunnel up
sudo systemctl enable --now wg-quick@wg0.service

# 4. Confirm the handshake
sudo wg show
```

Replace `wg0` with the interface name from your config file.

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
