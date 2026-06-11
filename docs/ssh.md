# SSH Guide

This repo keeps an SSH config example, not the real SSH config.

## Quick Path

1. Copy `home/.ssh/config.example` to `~/.ssh/config`.
2. Replace the example hosts, users, and key paths.
3. Set strict permissions on `~/.ssh` and the config file.

## File

| File | Purpose |
| --- | --- |
| `home/.ssh/config.example` | Safe template for SSH host definitions |

## Why This Is An Example

| Real SSH config contains | Why it stays out of the repo |
| --- | --- |
| Hostnames or IPs | Sensitive infrastructure details |
| Usernames | Operational details |
| Identity file names | Can reveal account structure |

## Template Structure

The example covers these patterns:

- GitHub host using a dedicated key
- Generic server host
- Generic database host
- Generic work host

## Never Version

- private keys like `id_ed25519_*`
- `known_hosts`
- real production hostnames or IPs
- real usernames tied to servers

## Related Files

- `home/.ssh/config.example`
- `wsl2-fedora/README.md#setup-on-a-new-machine`
