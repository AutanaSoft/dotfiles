-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function copy_with_source_reference()
  local filename = vim.api.nvim_buf_get_name(0)
  if filename == "" or vim.bo.buftype ~= "" then
    vim.notify("Copy with source reference requires a file buffer", vim.log.levels.WARN)
    return
  end

  local lines
  local first = vim.fn.line(".")
  local last = first
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local start_pos = vim.fn.getpos("v")
    local end_pos = vim.fn.getpos(".")
    local opts = { type = mode }
    lines = vim.fn.getregion(start_pos, end_pos, opts)
    local positions = vim.fn.getregionpos(start_pos, end_pos, opts)
    first = positions[1][1][2]
    last = positions[#positions][2][2]
  else
    lines = { vim.api.nvim_get_current_line() }
  end

  local path = vim.fs.relpath(LazyVim.root(), filename) or filename
  local range = first == last and tostring(first) or (first .. "-" .. last)
  local reference = "@" .. path .. ":" .. range
  local text = table.concat(lines, "\n")

  -- Keep Markdown selections containing code fences valid when pasted.
  local fence_length = 3
  for backticks in text:gmatch("`+") do
    fence_length = math.max(fence_length, #backticks + 1)
  end
  local fence = string.rep("`", fence_length)
  local copied = reference .. "\n" .. fence .. vim.bo.filetype .. "\n" .. text .. "\n" .. fence
  vim.fn.setreg("+", copied, "v")
  vim.notify("Copied " .. reference)
end

vim.keymap.set({ "n", "x" }, "<leader>cy", copy_with_source_reference, {
  desc = "Copy with source reference",
})
