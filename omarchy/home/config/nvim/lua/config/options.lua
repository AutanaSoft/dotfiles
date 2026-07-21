------------------------------------------------------------------------------
-- Mason: Prepend Mason bin to PATH so tools installed via Mason
-- (prettier, markdownlint-cli2, etc.) are invokable by conform.nvim,
-- nvim-lint, and other plugins. Without this, formatters and linters
-- fail silently because Mason is lazy-loaded and never adds its bin
-- to PATH on its own.
------------------------------------------------------------------------------
-- vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

------------------------------------------------------------------------------
-- Options: Display And Wrap
------------------------------------------------------------------------------
vim.opt.relativenumber = false
vim.opt.textwidth = 100
vim.opt.signcolumn = 'yes:2'
vim.opt.smartindent = true
vim.opt.wrap = false

-- tmp files
vim.opt.swapfile = false
vim.opt.scrolloff = 20
------------------------------------------------------------------------------
-- Spell: Bilingual Es En
------------------------------------------------------------------------------
vim.opt.spell = true
vim.opt.spelllang = 'es,en'
vim.opt.spellfile = vim.fn.stdpath('config') .. '/spell/custom.utf-8.add'
