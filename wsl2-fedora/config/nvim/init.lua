-- ------------------------------------------------------------------------------
-- Bootstrap
-- ------------------------------------------------------------------------------

require("config.lazy")

-- WSL2-only per-env overrides (spell config, wsl2-specific keymaps).
-- LazyVim does not auto-source `local.lua`; we pcall-do it here so the file
-- is optional (omarchy does not have one).
pcall(dofile, vim.fn.stdpath("config") .. "/lua/config/local.lua")
