# Neovim Quick Reference

This setup uses `LazyVim` with a mostly stock configuration. The base config is shared via
`shared/nvim/` (omarchy-canonical); each env adds its own plugins. Each page below covers a
specific mode or tool. See [`docs/shared-layer.md`](shared-layer.md) for the shared mapping.

## Quick Path

1. Press `Esc` to return to normal mode.
1. Use `Space e` to open or close the file explorer.
1. Use `Ctrl+h/j/k/l` to move between windows.
1. Use `Shift+h` and `Shift+l` to switch buffers.
1. Use `Ctrl+s` to save.

## Quick Reference

The 25 keys that cover ~90% of daily editing. For full reference, see the subdocs.

### Movement & Edit

| Action                 | Shortcut        |
| ---------------------- | --------------- |
| Move                   | `h` `j` `k` `l` |
| Word forward / back    | `w` / `b`       |
| Line start / end       | `0` / `$`       |
| File start / end       | `gg` / `G`      |
| Insert / append        | `i` / `a`       |
| New line below / above | `o` / `O`       |
| Delete line            | `dd`            |
| Copy / paste           | `yy` / `p`      |
| Undo / redo            | `u` / `Ctrl+r`  |

### Navigation

| Action                 | Shortcut              |
| ---------------------- | --------------------- |
| Search                 | `/` then `n` / `N`    |
| Find files             | `Space ff`            |
| Live grep              | `Space /`             |
| File explorer          | `Space e`             |
| Previous / next buffer | `Shift+h` / `Shift+l` |
| Move window            | `Ctrl+h` `j` `k` `l`  |

### Save & Quit

| Action               | Shortcut     |
| -------------------- | ------------ |
| Save                 | `Ctrl+s`     |
| Quit / save and quit | `:q` / `:wq` |

### Code (LSP)

| Action           | Shortcut   |
| ---------------- | ---------- |
| Go to definition | `gd`       |
| Find references  | `gr`       |
| Hover docs       | `K`        |
| Code actions     | `Space ca` |
| Rename symbol    | `Space cr` |

### Project-specific

| Action                   | Shortcut   |
| ------------------------ | ---------- |
| Toggle spelllang `es/en` | `Space sp` |
| Open Lazygit             | `Space gg` |
| Ask opencode             | `Space oa` |

## Modes

| Mode   | How to Enter              | Purpose                          |
| ------ | ------------------------- | -------------------------------- |
| Normal | `Esc` from any other mode | Move, delete, copy, run commands |
| Insert | `i`, `a`, `o`, `O`        | Write text                       |
| Visual | `v`, `V`, `Ctrl+v`        | Select text to operate on        |

## Reference Pages

| Page                               | Content                                                                    |
| ---------------------------------- | -------------------------------------------------------------------------- |
| [Normal Mode](nvim/normal-mode.md) | Full normal-mode reference (movement, edit, search, windows, buffers, LSP) |
| [Insert Mode](nvim/insert-mode.md) | Quick edits while typing, `Ctrl+o` trick                                   |
| [Visual Mode](nvim/visual-mode.md) | Selection types, operations, text objects                                  |
| [Explorer](nvim/explorer.md)       | File tree navigation and file operations (snacks.nvim)                     |
| [Lazygit](nvim/lazygit.md)         | Git operations inside Neovim                                               |
| [OpenCode](nvim/opencode.md)       | OpenCode CLI integration via `opencode.nvim`                               |

## Linters & Formatters

This setup uses LazyVim defaults. The chain is split by responsibility:

- **Formatters** run on save (`:FormatWrite` / `conform.nvim`) and never diagnose.
- **Linters** run on change (`:Lint` / `nvim-lint`) and report diagnostics; some can also autofix.
- **LSP** provides diagnostics from language servers (e.g. `ts_ls`, `gopls`).

| Language / Type         | Formatter (save)              | Linter (diagnostics)                    | Source                                                     |
| ----------------------- | ----------------------------- | --------------------------------------- | ---------------------------------------------------------- |
| Markdown                | `prettier` (+ `markdown-toc`) | `markdownlint-cli2`                     | LazyVim default; config at `shared/nvim/markdownlint.json` |
| TypeScript / JavaScript | `prettier`                    | ESLint LSP (via `linting.eslint` extra) | LazyVim default + extra enabled in `lazyvim.json`          |
| JSON / YAML             | `prettier`                    | (LSP only)                              | LazyVim default                                            |
| SQL                     | `sqlfluff`                    | `sqlfluff`                              | LazyVim default                                            |
| Go                      | `goimports` + `gofumpt`       | `golangci-lint`                         | LazyVim default                                            |
| Tailwind / Prisma       | (language-specific)           | (LSP only)                              | LazyVim default                                            |

## Tool Installation & Dependencies

Tool binaries are managed by LazyVim/Mason through the enabled extras in
`lazyvim.json` — manual `npm install -g` is **not** the source of truth and is only a
fallback (see below).

- **Markdown** — `lang.markdown` extra ensures `markdownlint-cli2` and `markdown-toc`
  via Mason. `prettier` is **not** part of the markdown extra; it is pulled in by the
  `formatting.prettier` extra (enabled in both envs), which registers `prettier` for
  Markdown (and JS/TS/JSON/YAML/HTML/CSS/etc.) via `conform.nvim`.
- **Go** — `lang.go` extra ensures `goimports`, `gofumpt`, `gomodifytags`, `impl`,
  `golangci-lint`, and `delve` via Mason. Nothing extra to enable.
- **Node / ESLint** — `linting.eslint` extra wires the ESLint LSP into `nvim-lspconfig`
  and `conform.nvim`. The **project's own** ESLint, plugins, and shared configs
  (`eslint`, `eslint-config-*`, `eslint-plugin-*`) remain per-project
  `devDependencies` — the editor integration does not replace them and should not be
  used as a justification to hoist them to a global install.

**After pulling these changes** run `:Lazy sync` inside Neovim; Mason will install
`prettier`, `markdownlint-cli2`, and `markdown-toc` on first launch. `mdformat` is
**not** used by this setup and must not be installed for it.

**Manual `npm install` fallback** — only when Mason is not desired (e.g. you want the
binary on `PATH` outside Neovim, or are scripting formatters from the shell):

```sh
npm i -g prettier markdownlint-cli2 markdown-toc
```

For per-project Node tooling (ESLint and its plugins/configs), keep them in the
project's own `devDependencies` — do not install them globally.

## Notes

- This setup uses `LazyVim`.
- The project explorer is provided by `snacks.nvim`.
- If something feels wrong, press `Esc` first.

## Related Files

All plugin specs live in `shared/nvim/lua/plugins/`. Each env's `lua/plugins/` is a mirror of
symlinks to the shared files (lazy.nvim discovers plugins via `{ import = "plugins" }`, so the
symlinks make shared files appear in the per-env plugin directory).

- `shared/nvim/lua/config/options.lua` — shared options + the one custom keymap (`Space sp`)
- `shared/nvim/lua/config/keymaps.lua` — empty by design (LazyVim provides defaults)
- `shared/nvim/lua/config/lazy.lua`, `autocmds.lua` — shared lazy/autocmd config
- `shared/nvim/lua/config/lint.lua` — wires `nvim-lint` to `markdownlint-cli2` + the shared config
- `shared/nvim/markdownlint.json` — shared `markdownlint-cli2` config (rules, line length, etc.)
- `<env>/config/nvim/markdownlint.json` — per-env symlink into the shared file (read by `nvim-lint` via `stdpath('config')`)
- `omarchy/config/nvim/lazyvim.json`, `wsl2-fedora/config/nvim/lazyvim.json` — LazyVim extras; `linting.eslint` is enabled in both
- `shared/nvim/lua/plugins/opencode.lua` — opencode.nvim keymaps (`<Space>oa/oo/or/ol/ou/od`)
- `shared/nvim/lua/plugins/theme.lua` — tokyonight colorscheme spec
- `shared/nvim/lua/plugins/theme-hotreload.lua` — theme hot-reload on `LazyReload`
- `shared/nvim/lua/plugins/all-themes.lua` — preloads all theme plugins for hot-reload
- `shared/nvim/lua/plugins/editorconfig.lua` — `.editorconfig` support
- `shared/nvim/lua/plugins/snacks-animated-scrolling-off.lua` — disables snacks scroll animations
- `shared/nvim/lua/plugins/nvim-lint-config.lua` — wires nvim-lint to the shared lint config
- `shared/nvim/lua/plugins/disable-news-alert.lua` — disables LazyVim/Neovim news popups
- `omarchy/config/nvim/lua/plugins/`, `wsl2-fedora/config/nvim/lua/plugins/` — per-env symlink mirrors of the above
