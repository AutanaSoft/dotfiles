-------------------------------------------------------------------------------
-- Snacks: Picker Paths And Scroll
-------------------------------------------------------------------------------
-- Surface project metadata and personal documentation while hiding Git internals.
local include_paths = { '.atl', 'openspec', 'backup', 'docs/ideas', '.gitignore' }
local exclude_paths = { '.git' }

return {
  {
    'folke/snacks.nvim',
    opts = {
      picker = {
        sources = {
          files = {
            include = include_paths,
            exclude = exclude_paths,
          },
          explorer = {
            include = include_paths,
            exclude = exclude_paths,
          },
        },
      },
      scroll = { enabled = false },
    },
  },
}
