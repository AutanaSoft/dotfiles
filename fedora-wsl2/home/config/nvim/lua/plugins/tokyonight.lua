-------------------------------------------------------------------------------
-- Tokyo Night
-------------------------------------------------------------------------------
return {
  {
    "folke/tokyonight.nvim",
    opts = {
      -- Available styles: moon, storm, night, day.
      style = "night",
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
