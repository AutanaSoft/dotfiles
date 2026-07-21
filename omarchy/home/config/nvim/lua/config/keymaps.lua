------------------------------------------------------------------------------
-- Keymap: Spell Toggle
------------------------------------------------------------------------------
vim.keymap.set('n', '<leader>ss', function()
  local langs = vim.opt.spelllang:get()
  if langs[1] == 'es' then
    vim.opt.spelllang = 'en,es'
  else
    vim.opt.spelllang = 'es,en'
  end
end, { desc = 'Toggle spelllang es/en priority' })
