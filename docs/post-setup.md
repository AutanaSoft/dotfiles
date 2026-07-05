# Post-Setup

`./setup --dots` installs packages, Nerd Fonts, and links the dotfiles into
`~/` and `~/.config/`. A handful of host-specific items stay manual: some need
`sudo`, others need credentials or hardware that no script can provision.
Run them once after a fresh install. Each step is independent, so rerun any
single step without touching the others.

## Sudo Password Feedback

By default, sudo prints nothing while you type the password. A sudoers
drop-in restores asterisks:

```bash
sudo tee /etc/sudoers.d/10-pwfeedback >/dev/null <<'EOF'
Defaults pwfeedback
EOF
sudo chmod 0440 /etc/sudoers.d/10-pwfeedback
sudo visudo -c
```

Reload the shell and verify with `sudo -K && sudo true`.

## Personal fstab

Personal partitions live in the repo at
[`src/etc/fstab`](../src/etc/fstab). The file holds only user data mounts
(btrfs subvols under `/home/lcardenas/`); system partitions stay on the
host. Edit the source file in the repo, then apply on the target machine:

```bash
# from inside the dotfiles repo
sudo install -m 644 src/etc/fstab /etc/fstab
sudo systemctl daemon-reload
sudo mount -a
```

Use `nofail` for any drive that may be detached, so a missing disk does
not block boot.

## SSH

Setup copies the tracked safe template at `src/home/ssh/config` to
`~/.ssh/config` (mode 600) the first time you run it; after that the
local file stays. Edit `~/.ssh/config` to replace the placeholders
(`your.server.ip.or.domain`, `your-user`, identity-file paths) with real
values. This workflow uses direct key files, not ssh-agent/ssh-add.

Make sure the key files referenced in the config are present on the host
with the correct permissions:

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

Setup does not install `wireguard-tools`. On Omarchy-family hosts the
kernel module is built-in, but you need the userland tools to manage
tunnels:

```bash
yay -S --needed wireguard-tools
```

Drop the peer configuration under `/etc/wireguard/` and start the template
unit:

```bash
sudo install -m 600 /path/to/wg0.conf /etc/wireguard/wg0.conf
sudo systemctl enable --now wg-quick@wg0.service
sudo wg show
```

Replace `wg0` with the interface name from the config file. The
`enable --now` brings the tunnel up at boot; `wg show` confirms the
handshake.

## Related Files

- `setup` — dispatcher run before this checklist.
- `src/etc/fstab` — repo source for personal `/etc/fstab`.
- `src/home/ssh/config` — SSH client template (placeholders; copied
  to `~/.ssh/config` once).