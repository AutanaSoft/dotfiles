-- ------------------------------------------------------------------------------
-- Spell
-- ------------------------------------------------------------------------------

vim.keymap.set("n", "<leader>ue", function()
  if vim.opt.spelllang:get()[1] == "es" then
    vim.opt.spelllang = { "en", "es" }
  else
    vim.opt.spelllang = { "es", "en" }
  end
end, { desc = "Toggle spell priority es/en" })
