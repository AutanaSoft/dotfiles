-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

------------------------------------------------------------------------------
-- Markdown: Override LazyVim's wrap_spell autocmd to disable wrap in markdown
------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = false
  end,
})

------------------------------------------------------------------------------
-- Spell: Visible Error Highlights
------------------------------------------------------------------------------
local function set_spell_highlights()
  -- Highlights misspelled words.
  vim.api.nvim_set_hl(0, "SpellBad", {
    fg = "#ff6b6b",
    bg = "#3b1f29",
    -- underline = true,
  })

  -- Highlights incorrect capitalization.
  vim.api.nvim_set_hl(0, "SpellCap", {
    fg = "#f1c40f",
    underline = true,
  })

  -- Highlights uncommon but valid words.
  vim.api.nvim_set_hl(0, "SpellRare", {
    fg = "#b48ead",
    underline = true,
  })

  -- Highlights words that differ by language region.
  vim.api.nvim_set_hl(0, "SpellLocal", {
    fg = "#5dade2",
    underline = true,
  })
end

-- Applies the highlights when this file loads.
set_spell_highlights()

-- Reapplies the highlights after changing colorschemes.
vim.api.nvim_create_autocmd("ColorScheme", {
  callback = set_spell_highlights,
})
