-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
require('config.remote_clipboard').setup()
vim.opt.relativenumber = false
vim.g.autoformat = false

------------------------------------------------------------------------------
-- Options: Display And Wrap
------------------------------------------------------------------------------
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
