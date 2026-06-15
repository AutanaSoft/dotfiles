-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Toggle spell priority es <-> en
vim.keymap.set("n", "<leader>sp", function()
  local langs = vim.opt.spelllang:get()
  if langs[1] == "es" then
    vim.opt.spelllang = "en,es"
  else
    vim.opt.spelllang = "es,en"
  end
end, { desc = "Toggle spelllang es/en priority" })
