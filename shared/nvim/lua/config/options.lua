-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.relativenumber = false
vim.opt.textwidth = 100

-- Spell: English and Spanish dictionaries for prose-heavy work
vim.opt.spell = true
vim.opt.spelllang = "es,en"
vim.opt.spellfile = vim.fn.stdpath("data") .. "/site/spell/custom.utf-8.add"

-- Toggle spell priority es <-> en
vim.keymap.set("n", "<leader>sp", function()
    local langs = vim.opt.spelllang:get()
    if langs[1] == "es" then
        vim.opt.spelllang = "en,es"
    else
        vim.opt.spelllang = "es,en"
    end
end, { desc = "Toggle spelllang es/en priority" })
