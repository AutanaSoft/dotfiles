# OpenCode in Neovim

This setup uses [`nickjvandyke/opencode.nvim`](https://github.com/nickjvandyke/opencode.nvim) inside the repo-managed LazyVim configuration. The plugin spec is shared via the symlink chain, so both envs get the same keymaps.

## Quick path

1. Open Neovim.
1. Let `lazy.nvim` install the plugin if needed.
1. Use the keymaps under `<leader>o`.

## Plugin location

| Area | Path |
|------|------|
| Plugin spec | `shared/nvim/lua/plugins/opencode.lua` (shared, omarchy-canonical) |
| Nvim base config | `shared/nvim/lua/config/{lazy,autocmds,keymaps,options}.lua` (shared) |
| Live Neovim config | `~/.config/nvim` → `<env>/config/nvim` (folder symlink) → `shared/nvim/` |

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
- WSL2 used to have a divergent `opencode.lua` with 2 keymaps (`<Space>aa`, `<Space>as`) and auto-submit; the configs were unified in favor of the omarchy version (6 keymaps, confirm-before-send).

## Verification

- Run `:Lazy` to confirm the plugin is installed.
- Run `:checkhealth opencode` after installation.
- Test one keymap, such as `<leader>oa`, from normal mode.
