-- ------------------------------------------------------------------------------
-- Custom Plugins
-- ------------------------------------------------------------------------------

return {
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      style = "night",
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      input = {},
      picker = {
        sources = {
          files = {
            hidden = true,
          },
        },
        actions = {
          opencode_send = function(...)
            return require("opencode").snacks_picker_send(...)
          end,
        },
        win = {
          input = {
            keys = {
              ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
            },
          },
        },
      },
    },
  },
  {
    "nickjvandyke/opencode.nvim",
    version = "*",
    keys = {
      { "<leader>aa", desc = "Ask opencode" },
      { "<leader>as", desc = "Select opencode" },
    },
    config = function()
      vim.g.opencode_opts = {}
      vim.o.autoread = true

      vim.keymap.set({ "n", "x" }, "<leader>aa", function()
        require("opencode").ask("@this: ", { submit = true })
      end, { desc = "Ask opencode" })

      vim.keymap.set({ "n", "x" }, "<leader>as", function()
        require("opencode").select()
      end, { desc = "Select opencode" })
    end,
  },
}
