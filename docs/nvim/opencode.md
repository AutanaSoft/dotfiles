# OpenCode in Neovim

This setup uses [`nickjvandyke/opencode.nvim`](https://github.com/nickjvandyke/opencode.nvim) inside the repo-managed LazyVim configuration.

## Quick path

1. Open Neovim.
2. Let `lazy.nvim` install the plugin if needed.
3. Use the keymaps under `<leader>o`.

## Plugin location

| Area | Path |
|------|------|
| Plugin spec | `omarchy/config/nvim/lua/plugins/opencode.lua` (per-env) |
| Nvim base config | `shared/nvim/lua/config/{lazy,autocmds,keymaps,options}.lua` (symlinked into each env) |
| Live Neovim config | `~/.config/nvim` -> symlink to `omarchy/config/nvim` |

## Why this plugin

This configuration uses `nickjvandyke/opencode.nvim` as a bridge between Neovim and OpenCode.

It was chosen instead of alternative `opencode.nvim` plugins because it is simpler and fits the current repo-managed workflow better.

## Keymaps

| Keymap | Action |
|--------|--------|
| `<leader>oa` | Ask OpenCode about the current context |
| `<leader>oo` | Open the OpenCode selector |
| `<leader>or` | Send a motion or visual range to OpenCode |
| `<leader>ol` | Send the current line to OpenCode |
| `<leader>ou` | Scroll the OpenCode session up by half a page |
| `<leader>od` | Scroll the OpenCode session down by half a page |

## Notes

- `<leader>` is the LazyVim leader key and is mapped to `Space`.
- The OpenCode mappings were moved under `<leader>o` to match the existing LazyVim keymap style.
- Previous global remaps for `+` and `-` were removed to avoid changing default Neovim behavior.

## Verification

- Run `:Lazy` to confirm the plugin is installed.
- Run `:checkhealth opencode` after installation.
- Test one keymap, such as `<leader>oa`, from normal mode.
