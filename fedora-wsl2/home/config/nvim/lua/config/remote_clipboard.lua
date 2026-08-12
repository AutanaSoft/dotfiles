local M = {}

function M.setup()
  if vim.fn.executable("win32yank.exe") == 0 then
    return
  end

  vim.g.clipboard = {
    name = "win32yank-wsl",
    copy = {
      ["+"] = { "win32yank.exe", "-i", "--crlf" },
      ["*"] = { "win32yank.exe", "-i", "--crlf" },
    },
    paste = {
      ["+"] = { "win32yank.exe", "-o", "--lf" },
      ["*"] = { "win32yank.exe", "-o", "--lf" },
    },
    cache_enabled = 1,
  }
end

return M
