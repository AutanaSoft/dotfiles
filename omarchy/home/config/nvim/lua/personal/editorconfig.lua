-------------------------------------------------------------------------------
-- Editor: Defaults, Markdown, And EditorConfig
-------------------------------------------------------------------------------
return {
  {
    'LazyVim/LazyVim',
    init = function()
      -- Keep source files compact while leaving room for signs and diagnostics.
      vim.opt.textwidth = 100
      vim.opt.signcolumn = 'yes:2'
      vim.opt.smartindent = true
      vim.opt.wrap = false
      vim.opt.swapfile = false
      vim.opt.scrolloff = 20

      -- LazyVim enables wrapping for prose; this setup keeps Markdown consistent.
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'markdown',
        callback = function()
          vim.opt_local.wrap = false
        end,
      })
    end,
  },
  -- Respect per-project .editorconfig settings after applying the base defaults.
  {
    'editorconfig/editorconfig-vim',
    lazy = false,
    priority = 1000,
  },
}
