# Neovim Quick Reference

This setup uses `LazyVim` with a mostly stock configuration. The full config is shared via
`shared/nvim/` (omarchy-canonical). Per-env trees at `omarchy/config/nvim/` and
`wsl2-fedora/config/nvim/` are **relative symlinks** into `shared/nvim/`; there are no per-env
overrides by default. Each page below covers a specific mode or tool. See
[`docs/shared-layer.md`](shared-layer.md) for the shared mapping.

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

**Canonical location:** every Neovim config file (plugin specs, LazyVim extras, lockfile,
runtime config) lives in `shared/nvim/`. Per-env paths are relative symlinks into `shared/`. Any
edit in `shared/nvim/` is visible to both environments on next launch.

**Ignore policy:** Neovim config is shared, but ignore policy is repository-level only. The
only `.gitignore` in this repo is the root one; per-tool `.gitignore` files carried over from
upstream starters (e.g. the LazyVim starter's scratch-file rules) are not part of this repo's
policy and are not tracked.

### Shared root files (`shared/nvim/`)

- `init.lua` — entry point, `require("config.lazy")` (identical in both envs)
- `lazyvim.json` — LazyVim extras; `linting.eslint` is enabled (identical in both envs)
- `lazy-lock.json` — **shared lockfile** (omarchy-canonical). Keep it in sync; do not duplicate
  per env. Any plugin present here is installed in both envs.
- `.neoconf.json` — neodev/neoconf config (lua_ls enabled)
- `LICENSE` — Apache 2.0 (LazyVim attribution; required when distributing)
- `plugin/after/transparency.lua` — makes a curated set of highlight groups transparent so the
  terminal background shows through. Loaded after LazyVim's own `plugin/after/*.lua`.

### Shared plugin/config sources (`shared/nvim/lua/`)

All plugin specs and LazyVim config overrides live in `shared/nvim/lua/`. Each env's
`lua/config/` and `lua/plugins/` is a per-file relative symlink mirror so lazy.nvim's
`{ import = "plugins" }` discovery sees the shared files at the expected paths.

- `shared/nvim/lua/config/options.lua` — shared options + the one custom keymap (`Space sp`)
- `shared/nvim/lua/config/keymaps.lua` — empty by design (LazyVim provides defaults)
- `shared/nvim/lua/config/lazy.lua`, `autocmds.lua` — shared lazy/autocmd config
- `shared/nvim/lua/config/lint.lua` — wires `nvim-lint` to `markdownlint-cli2` + the shared config
- `shared/nvim/markdownlint.json` — shared `markdownlint-cli2` config (rules, line length, etc.)
- `shared/nvim/stylua.toml` — shared Lua formatter config
- `shared/nvim/lua/plugins/opencode.lua` — opencode.nvim keymaps (`<Space>oa/oo/or/ol/ou/od`)
- `shared/nvim/lua/plugins/theme.lua` — tokyonight colorscheme spec
- `shared/nvim/lua/plugins/theme-hotreload.lua` — theme hot-reload on `LazyReload`
- `shared/nvim/lua/plugins/all-themes.lua` — preloads all theme plugins for hot-reload
- `shared/nvim/lua/plugins/editorconfig.lua` — `.editorconfig` support
- `shared/nvim/lua/plugins/snacks-animated-scrolling-off.lua` — disables snacks scroll animations
- `shared/nvim/lua/plugins/nvim-lint-config.lua` — wires nvim-lint to the shared lint config
- `shared/nvim/lua/plugins/disable-news-alert.lua` — disables LazyVim/Neovim news popups

### Per-env mirror paths

These exist **only** as relative symlinks to `shared/nvim/...` — never as actual files. To
override a file, replace the symlink with a real file in that env (and update the shared-layer
mapping to mark it as per-env).

- `omarchy/config/nvim/{init.lua,lazyvim.json,lazy-lock.json,.neoconf.json,LICENSE,plugin/after/transparency.lua}`
- `wsl2-fedora/config/nvim/{init.lua,lazyvim.json,lazy-lock.json,.neoconf.json,LICENSE,plugin/after/transparency.lua}`
- `omarchy/config/nvim/lua/config/*.lua`, `omarchy/config/nvim/lua/plugins/*.lua`
- `wsl2-fedora/config/nvim/lua/config/*.lua`, `wsl2-fedora/config/nvim/lua/plugins/*.lua`
- `omarchy/config/nvim/{markdownlint.json,stylua.toml}`,
  `wsl2-fedora/config/nvim/{markdownlint.json,stylua.toml}`

## Lockfile policy

`shared/nvim/lazy-lock.json` is the single source of truth for plugin versions. **Do not
duplicate the lockfile per env** and do not introduce environment-specific plugins there. If
a plugin must be enabled in only one env, the right place is a per-env spec file under
`<env>/config/nvim/lua/plugins/` (replacing the symlink with a real file), not a per-env
lockfile. Past drift between the omarchy and WSL2 lockfiles was resolved by unifying on the
shared lockfile; per-env lockfile entries are no longer permitted.
