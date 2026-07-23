-- Personal LazyVim configuration entrypoint.
-- Each module returns one or more plugin specifications merged by lazy.nvim.
local specs = {}

for _, module in ipairs({
  'personal.editorconfig',
  'personal.render-markdown',
  'personal.snacks',
  'personal.opencode',
}) do
  vim.list_extend(specs, require(module))
end

return specs
