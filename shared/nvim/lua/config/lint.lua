-- nvim-lint configuration
-- Wires the markdown linter to a shared config file
-- (shared/nvim/markdownlint.json, symlinked into the per-env nvim config root)
-- so the same rules apply in omarchy and wsl2-fedora.

-- Register markdownlint-cli2 as the markdown linter
require("lint").linters_by_ft.markdown = { "markdownlint-cli2" }

-- Point markdownlint-cli2 at the shared config
local markdownlint_cli2 = require("lint").linters["markdownlint-cli2"]
markdownlint_cli2.args = {
  "-",
  "--config",
  vim.fn.stdpath("config") .. "/markdownlint.json",
}
