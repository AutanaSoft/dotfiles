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

Setup copies the safe template at `omarchy/home/ssh/config` to `~/.ssh/config` the first time. Edit
the placeholders (`your.server.ip.or.domain`, `your-user`, key paths) with your real values. This
workflow uses direct key files, not ssh-agent/ssh-add.

The referenced key files must have the right permissions:

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

## PostgreSQL and Valkey

`./setup --profile omarchy --services` initializes an absent or empty PostgreSQL cluster and
configures both services. It never creates databases, PostgreSQL roles, or passwords.

PostgreSQL keeps the Arch-standard socket at `/run/postgresql`. Local socket connections use `peer`;
TCP connections are restricted to localhost and require SCRAM passwords. Create a role for the
current system user when needed:

```bash
sudo -u postgres createuser --login "$(whoami)"
```

Interactive service setup offers to update the `postgres` role password without exposing it in the
command line. If that step was declined, configure it safely with `psql`:

```bash
sudo -u postgres psql --command='\password postgres'
```

Then verify both transports:

```bash
PGPASSWORD='choose-a-secret' psql -h 127.0.0.1 -U postgres -c 'SELECT 1;'
sudo -u postgres psql -h /run/postgresql -d postgres -c 'SELECT 1;'
```

Valkey listens on loopback TCP port 6379 and `/run/valkey/valkey.sock`. The socket is owned by
`valkey:valkey` with mode `0770`. In an interactive setup, accept the optional group enrollment,
then start a new session before using the socket. `newgrp valkey` can open an immediate subshell for
manual use.

```bash
valkey-cli -h 127.0.0.1 -p 6379 ping
valkey-cli -s /run/valkey/valkey.sock ping
```

Both commands should return `PONG`. Do not expose either service beyond loopback without separately
reviewing authentication and firewall requirements.

## Related Files

- `setup` — dispatcher run before this checklist.
- `omarchy/etc/fstab` — repo source for personal `/etc/fstab`.
- `omarchy/home/ssh/config` — SSH client template (placeholders; copied to `~/.ssh/config` once).
