-- nvim-lint configuration
-- Loads the lint config from lua/config/lint.lua

return {
  {
    "mfussenegger/nvim-lint",
    lazy = false,
    config = function()
      local lint_config = vim.fn.stdpath("config") .. "/lua/config/lint.lua"
      if vim.fn.filereadable(lint_config) == 1 then
        dofile(lint_config)
      end
    end,
  },
}
