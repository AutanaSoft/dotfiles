-- YAML formatter: prefer the yamlls LSP over prettier.
-- Prettier is kept in the list as a no-op fallback (its condition fails in
-- this repo because there is no `package.json`); with `lsp_format = "prefer"`
-- conform tries yamlls first and only falls back to prettier if yamlls is not
-- attached or cannot format the buffer.

return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        yaml = { "prettier", lsp_format = "prefer" },
      },
    },
  },
}
