-- editorconfig-vim: applies the repo's .editorconfig rules on file
-- open. Without this, Neovim does NOT respect .editorconfig
-- natively. The plugin sets local options (expandtab, tabstop,
-- shiftwidth, etc.) based on the .editorconfig match for the file.
--
-- lazy = false + high priority so the plugin is loaded early in the
-- startup sequence, before any other plugin reads file-type-specific
-- options.

return {
  {
    "editorconfig/editorconfig-vim",
    lazy = false,
    priority = 1000,
  },
}
