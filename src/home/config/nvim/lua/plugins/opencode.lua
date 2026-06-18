return {
  {
    "nickjvandyke/opencode.nvim",
    version = "*",
    dependencies = {
      {
        "folke/snacks.nvim",
        optional = true,
        opts = {
          input = {},
          picker = {
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
    },
    config = function()
      vim.g.opencode_opts = {}

      vim.o.autoread = true

      vim.keymap.set({ "n", "x" }, "<leader>oa", function()
        require("opencode").ask("@this: ")
      end, { desc = "Ask opencode" })

      vim.keymap.set({ "n", "x" }, "<leader>oo", function()
        require("opencode").select()
      end, { desc = "Select opencode" })

      vim.keymap.set({ "n", "x" }, "<leader>or", function()
        return require("opencode").operator("@this ")
      end, { desc = "Add range to opencode", expr = true })

      vim.keymap.set("n", "<leader>ol", function()
        return require("opencode").operator("@this ") .. "_"
      end, { desc = "Add line to opencode", expr = true })

      vim.keymap.set("n", "<leader>ou", function()
        require("opencode").command("session.half.page.up")
      end, { desc = "Scroll opencode up" })

      vim.keymap.set("n", "<leader>od", function()
        require("opencode").command("session.half.page.down")
      end, { desc = "Scroll opencode down" })
    end,
  },
}
