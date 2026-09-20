-------------------------------------------------------------------------------
-- Tokyo Night
-------------------------------------------------------------------------------
return {
  {
    "folke/tokyonight.nvim",
    opts = {
      -- Available styles: moon, storm, night, day.
      style = "night",
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
