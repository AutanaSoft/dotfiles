# Neovim

LazyVim configuration shared across both environments. Canonical source: `shared/nvim/`,
exposed at runtime as a single folder symlink (`<env>/config/nvim/` → `shared/nvim/`). See
[`docs/shared-layer.md`](shared-layer.md) for the symlink model.

## Quick path

1. Press `Esc` to return to normal mode.
1. `Space e` opens the file explorer (`snacks.nvim`); `Space gg` opens Lazygit.
1. `Space ff` finds files; `Space /` greps the project.
1. `Ctrl+s` saves; `Ctrl+h`/`j`/`k`/`l` moves between windows.
1. Forgot a key? Jump to [Neovim Keybindings](nvim-keymaps.md).

## Where to find what

| Need | Page |
|------|------|
| Most-used keys (forget-me-not) | [Neovim Keybindings](nvim-keymaps.md) |
| Full per-mode reference | [Normal](nvim/normal-mode.md) · [Insert](nvim/insert-mode.md) · [Visual](nvim/visual-mode.md) |
| File explorer (`snacks.nvim`) | [Explorer](nvim/explorer.md) |
| Git inside Neovim | [Lazygit](nvim/lazygit.md) |
| OpenCode CLI integration | [OpenCode](nvim/opencode.md) |

## Managed files

| Path | Role |
|------|------|
| `shared/nvim/lazyvim.json` | Enabled LazyVim extras |
| `shared/nvim/lazy-lock.json` | Shared plugin lockfile |
| `shared/nvim/lua/plugins/` | One file per plugin or concern |
| `shared/nvim/lua/config/` | LazyVim config overrides (`lazy`, `autocmds`, `keymaps`, `options`, `lint`) |
| `shared/nvim/plugin/after/transparency.lua` | Transparent highlight overrides |
| `shared/nvim/markdownlint.json` | Shared markdown lint rules |

## Formatting & Linting

LazyVim/Mason installs the editor tools from the enabled extras in `shared/nvim/lazyvim.json`.
Run `:Lazy sync` after changing plugins or extras.

| Type | Formatter | Diagnostics |
| --- | --- | --- |
| Markdown | `prettier` | `markdownlint-cli2` |
| TypeScript / JavaScript | `prettier` | ESLint LSP |
| Go | `goimports` + `gofumpt` | `golangci-lint` |

Manual fallback, only if the binaries are needed outside Neovim:

```sh
npm i -g prettier markdownlint-cli2 markdown-toc
```

## Related docs

- [`docs/nvim-keymaps.md`](nvim-keymaps.md) — most-used keys quick reference
- [`docs/shared-layer.md`](shared-layer.md) — symlink model for shared config
