-------------------------------------------------------------------------------
-- Spell: Bilingual Spanish And English
-------------------------------------------------------------------------------
return {
  {
    'LazyVim/LazyVim',
    init = function()
      vim.opt.spell = true
      vim.opt.spelllang = 'es,en'
      vim.opt.spellfile = vim.fn.stdpath('config') .. '/spell/custom.utf-8.add'

      -- Toggle the preferred language while retaining both dictionaries.
      vim.keymap.set('n', '<leader>ss', function()
        local langs = vim.opt.spelllang:get()
        vim.opt.spelllang = langs[1] == 'es' and 'en,es' or 'es,en'
      end, { desc = 'Toggle spelllang es/en priority' })
    end,
  },
}
