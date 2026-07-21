# OpenCode in Neovim

Integration of OpenCode CLI in Neovim via
[`nickjvandyke/opencode.nvim`](https://github.com/nickjvandyke/opencode.nvim). Spec lives
in `omarchy/home/config/nvim/lua/plugins/opencode.lua`.

## Quick path

1. Open Neovim; let `lazy.nvim` install the plugin.
1. Use the keymaps under `<leader>o` (leader = `Space`).

## Plugin location

| Area | Path |
|------|------|
| Plugin spec | `omarchy/home/config/nvim/lua/plugins/opencode.lua` |
| Nvim base config | `omarchy/home/config/nvim/lua/config/{lazy,autocmds,keymaps,options}.lua` |
| Live Neovim config | `~/.config/nvim` → `omarchy/home/config/nvim/` (folder symlink) |

## Keymaps

| Keymap | Action |
|--------|--------|
| `<leader>oa` | Ask OpenCode about the current context |
| `<leader>oo` | Open the OpenCode selector |
| `<leader>or` | Send a motion or visual range to OpenCode |
| `<leader>ol` | Send the current line to OpenCode |
| `<leader>ou` | Scroll the OpenCode session up by half a page |
| `<leader>od` | Scroll the OpenCode session down by half a page |

## Verification

- Run `:Lazy` to confirm the plugin is installed.
- Run `:checkhealth opencode` after installation.
- Test one keymap, such as `<leader>oa`, from normal mode.
