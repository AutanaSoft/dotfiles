# Post-Setup

Run-once manual steps that `./setup --dots` cannot finish for you — sudo
tweaks, partition mounts, secrets, and service auth. Each section is
independent; rerun any single one without touching the rest.

## Sudo Password Feedback

By default, sudo prints nothing while you type the password. A sudoers
drop-in restores asterisks:

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

The personal `fstab` lives in the repo at
[`omarchy/etc/fstab`](../omarchy/etc/fstab). Edit it there, then apply on the
host:

```bash
# 1. Install from the repo
sudo install -m 644 omarchy/etc/fstab /etc/fstab

# 2. Reload systemd
sudo systemctl daemon-reload

# 3. Mount everything
sudo mount -a
```

Use `nofail` for any drive that may be detached, so a missing disk does
not block boot.

## SSH

Setup copies the safe template at `omarchy/home/ssh/config` to
`~/.ssh/config` the first time. Edit the placeholders
(`your.server.ip.or.domain`, `your-user`, key paths) with your real
values. This workflow uses direct key files, not ssh-agent/ssh-add.

The referenced key files must have the right permissions:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519_*
chmod 644 ~/.ssh/id_ed25519_*.pub
```

## GitHub CLI Auth

`./setup --dots` does not authenticate against GitHub. Run:

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

## PostgreSQL

`postgresql` is already installed. Set up the cluster and auth:

```bash
# 1. Init the cluster (first time only — errors if already initialized)
sudo -u postgres initdb -D /var/lib/postgres/data

# 2. Start the service
sudo systemctl enable --now postgresql

# 3. Set the superuser password
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';"
```

Open the auth config in nvim and make sure it matches the example
below — the `# comment` lines are part of the file and explain each
rule:

```bash
sudo -u postgres nvim /var/lib/postgres/data/pg_hba.conf
```

```conf
# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            scram-sha-256
# IPv6 local connections:
host    all             all             ::1/128                 scram-sha-256
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            scram-sha-256
host    replication     all             ::1/128                 scram-sha-256
```

Save the file, then apply:

```bash
sudo systemctl reload postgresql
```

Verify both auth paths:

```bash
# TCP with the password you just set — should print the version
PGPASSWORD=postgres psql -h 127.0.0.1 -U postgres -c "SELECT version();"

# TCP without a password — must fail with "password authentication failed"
psql -h 127.0.0.1 -U postgres -c "SELECT 1;" || echo "good: rejected without password"

# Unix socket as the postgres OS user — must work without typing a password
sudo -u postgres psql -c "SELECT current_user;"
```

Note: `postgres / postgres` is a dev convenience (same credential the
official Docker image uses). Do not reuse it on anything reachable
from outside the host.

## Valkey

`valkey` is already installed. Enable both transports:

```bash
# 1. Start the service
sudo systemctl enable --now valkey

# 2. Open the config
sudo nvim /etc/valkey/valkey.conf
```

Make the Unix socket block match this — the `# comment` lines are part of the file and explain the directive:

```conf
# Unix socket.
#
# Specify the path for the Unix socket that will be used to listen for
# incoming connections. There is no default, so the server will not listen
# on a unix socket when not specified.
#
unixsocket /run/valkey/valkey.sock
# unixsocketgroup wheel
unixsocketperm 770
```

Save the file, then restart and grant your user access:

```bash
# 3. Restart to pick up the new config
sudo systemctl restart valkey

# 4. Add your user to the valkey group
sudo usermod -aG valkey "$(whoami)"
```

Verify both transports. The socket path is what the running service
actually has, not what we wrote above — read it back so this stays
true if the package changes:

```bash
# Confirm the socket directive the service is using
redis-cli CONFIG GET unixsocket

# TCP — should print PONG
redis-cli -h 127.0.0.1 -p 6379 PING

# Unix socket — should print PONG
redis-cli -s /run/valkey/valkey.sock PING
```

If the socket command errors with `Permission denied`, log out and
back in so the new `valkey` group membership takes effect.

The default config binds to `127.0.0.1` only, so `protected-mode`
keeps external traffic blocked without a password. If you ever need
remote access, set `requirepass` and allowlist the source — do not
bind to `0.0.0.0` without auth.

## Related Files

- `setup` — dispatcher run before this checklist.
- `omarchy/etc/fstab` — repo source for personal `/etc/fstab`.
- `omarchy/home/ssh/config` — SSH client template (placeholders; copied
  to `~/.ssh/config` once).