-- nvim-lint configuration
-- Customizes markdownlint to use a global config file.

-- Add markdownlint to the linters for markdown
require("lint").linters_by_ft.markdown = { "markdownlint" }

local markdownlint = require("lint").linters.markdownlint
markdownlint.args = {
  "--config",
  vim.fn.stdpath("config") .. "/markdownlint.json",
}

-- Optional: add more linter customizations here
-- e.g. for other linters:
-- local eslint = require("lint").linters.eslint
-- eslint.args = { "--config", vim.fn.stdpath("config") .. "/.eslintrc.json" }
