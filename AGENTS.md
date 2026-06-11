# AGENTS.md — Dotfiles Autanasoft

## Repository Purpose

This repository contains personal configuration files (dotfiles) for two work environments:

| Environment | Main Stack |
|-------------|------------|
| **Omarchy** (Arch + Hyprland) | Hyprland, Alacritty/Foot, Zellij, Neovim/LazyVim, Mako, Waybar, Walker |
| **WSL2-Fedora** | WezTerm, Zellij, Neovim/LazyVim, Zsh, Starship, Git, SSH |

The structure follows a symbolic link hierarchy:

```
~/.config/<x>/<file> --> <env>/config/<x>/<file> --> ../shared/<x>/<file>
```

- `shared/` contains the canonical configurations valid for both environments.
- Each environment may have specific configurations that diverge from shared.
- Only files diverging from upstream defaults are versioned.

______________________________________________________________________

## Applied Conventions

### Organization Conventions

| Convention | Details |
|------------|---------|
| **`p-` prefix** | In Hyprland, files with `p-` prefix are personal and survive `omarchy update` |
| **Canonical source** | `shared/` content is signed from omarchy; wsl2 follows omarchy |
| **Removal policy** | Comment lines with `# Reason:` instead of deleting |

### Formatting Conventions

| File Type | Indentation |
|-----------|-------------|
| Default | 2 spaces |
| KDL, Shell, Hyprland `.conf` | 4 spaces |
| Markdown | Exempt from trailing whitespace trimming |

### Main Tools

**Shared across both environments:**

- **Zellij** — terminal workspace manager, `Alt-first` keybindings, `locked` mode by default
- **Starship** — cross-shell prompt with modules for AWS, Docker, Git, Go, Node, Python, Rust, etc.
- **Neovim + LazyVim** — plugin manager with `lazy-lock.json` versioned
- **opencode.nvim** — AI integration, different keybindings per environment

**Omarchy (Arch + Hyprland):**

- Hyprland (Wayland compositor), Alacritty/Foot (terminals), Mako (notifications)
- Waybar, Walker (app launcher), custom Omarchy theme
- `hyprctl` for reload and monitor control

**WSL2-Fedora:**

- WezTerm, Zsh (with autosuggestions and syntax highlighting)
- Homebrew Linuxbrew at `/home/linuxbrew/.linuxbrew`
- `mise` for runtime activation, `direnv`, `fzf`

______________________________________________________________________

## Conventions to Follow

### Before Making Changes

1. **Verify the canonical source** — if the file exists in `shared/`, that is the canonical source. Specific environments only diverge when necessary.
1. **Understand the symlink flow** — any change in `shared/` affects both environments.
1. **Comment instead of delete** — use `# Reason:` to document why something is disabled.

### After Making Changes

1. **Reload the affected service:**
   - Hyprland: `hyprctl reload` followed by `hyprctl configerrors`
   - Zellij: close and reopen the session or `zellij -l <layout>`
   - Neovim: restart or `:Lazy reload` if it's a plugin
1. **Validate** — confirm there are no configuration errors.

### Change Workflow

1. Edit the file in the repository
1. The symlink makes the change immediately visible to the live system
1. Reload the affected service and validate

______________________________________________________________________

## Forbidden Paths

These paths are managed by the system and overwritten on updates:

- `~/.local/share/omarchy/` — managed by omarchy, do not touch
- SSH private keys, `known_hosts`, machine-specific tokens
- Hyprland/Mako/Waybar/Walker configs specific to omarchy (not shared)

______________________________________________________________________

## Communication Rules

### Language

- **Communication with the developer:** neutral Latin American Spanish
- No regionalisms like Argentine/Uruguayan voseo or Mexican slang
- Soft, professional tuteo
- Technical text in English: variable names, functions, code comments

### Execution Rules

1. **Do not commit, push, or PR** without explicit request from the developer
1. **If there are doubts about the requirement,** clarify with the developer before executing
1. **Verify before affirming** — if the developer makes an incorrect technical claim, explain why with evidence

### Response Format

- Short answers by default
- Expand only when the developer asks or the task genuinely requires it
- One question at a time; wait for answer before continuing

______________________________________________________________________

## Artifacts and Documentation

- Markdown files use 2-space indentation
- Configuration files (`.conf`, shell scripts) use 4-space indentation
- System documentation is in `/docs` within each environment
