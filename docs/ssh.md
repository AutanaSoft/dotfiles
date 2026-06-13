# SSH

`shared/home/.ssh/config` is a tracked safe template: no secrets, no
real hostnames, no real identity paths — only placeholders. All other
files under `shared/home/.ssh/` are gitignored.

Real SSH values live only in each host's `~/.ssh/config`. Setup copies
the template to that path only when the target is missing; an existing
local file is never overwritten.

## Quick path

1. Run `./setup --omarchy`. Setup copies the template to
   `~/.ssh/config` (`700`/`600` modes) only if it is missing.
1. On Fedora, run the manual copy in
   [`fedora/README.md`](../fedora/README.md#create-the-ssh-config).
1. Edit `~/.ssh/config` directly to add real per-host values.

## Never commit

- `shared/home/.ssh/config` filled with real values
- private keys (`id_ed25519_*`)
- `known_hosts`
- real production hostnames, IPs, or usernames
