-- ------------------------------------------------------------------------------
-- WSL2-specific overrides
-- ------------------------------------------------------------------------------
-- This file is auto-sourced by the wsl2 init.lua (pcall dofile). It carries
-- per-env settings that do not belong in the shared `lua/config/*.lua` files
-- (which are canonical = omarchy).
--
-- When adding new shared-level settings, edit `shared/nvim/lua/config/*.lua`
-- instead. Use THIS file only for true wsl2-only deltas.

-- Spell: enable es/en for prose-heavy work in Spanish + English
vim.opt.spell = true
vim.opt.spelllang = { "es", "en" }
vim.opt.spellfile = vim.fn.stdpath("data") .. "/site/spell/custom.utf-8.add"

-- Toggle spell priority es <-> en
vim.keymap.set("n", "<leader>ue", function()
  if vim.opt.spelllang:get()[1] == "es" then
    vim.opt.spelllang = { "en", "es" }
  else
    vim.opt.spelllang = { "es", "en" }
  end
end, { desc = "Toggle spell priority es/en" })
