local wezterm = require("wezterm")

return {
  -- ------------------------------------------------------------------------------
  -- Windows WSL
  -- Active only when running WezTerm on Windows with WSL integration.
  -- Copy this file to the Windows user's home
  -- (e.g. C:\Users\<USER>\.wezterm.lua) and uncomment the options below
  -- to enable them.
  -- ------------------------------------------------------------------------------
  default_domain = "WSL:Fedora",

  -- ------------------------------------------------------------------------------
  -- Rendering
  -- ------------------------------------------------------------------------------
  max_fps = 120,

  -- ------------------------------------------------------------------------------
  -- Font
  -- ------------------------------------------------------------------------------
  font = wezterm.font("Monaspace Krypton NF"),
  font_size = 9,

  -- ------------------------------------------------------------------------------
  -- Theme
  -- ------------------------------------------------------------------------------
  color_scheme = "Tokyo Night",

  -- ------------------------------------------------------------------------------
  -- Window
  -- ------------------------------------------------------------------------------
  hide_tab_bar_if_only_one_tab = true,
  window_background_opacity = 0.96,
  initial_cols = 140,
  initial_rows = 36,
  window_padding = { left = 1, right = 1, top = 0, bottom = 0 },
  enable_scroll_bar = false,

  -- ------------------------------------------------------------------------------
  -- Loading
  -- ------------------------------------------------------------------------------
  automatically_reload_config = true,

  -- ------------------------------------------------------------------------------
  -- Rendering polish
  -- ------------------------------------------------------------------------------
  use_resize_increments = true,
  unicode_version = 14,
  warn_about_missing_glyphs = true,

  -- ------------------------------------------------------------------------------
  -- Cursor
  -- ------------------------------------------------------------------------------
  default_cursor_style = "SteadyBlock",
  cursor_blink_rate = 500,
  cursor_blink_ease_in = "Constant",
  cursor_blink_ease_out = "Constant",

  -- ------------------------------------------------------------------------------
  -- Neovim
  -- ------------------------------------------------------------------------------
  -- underline_thickness = 2,
  -- underline_position = -2,
  scrollback_lines = 10000,
  selection_word_boundary = " \t\n\"'`.,;:{}()[]",

  -- ------------------------------------------------------------------------------
  -- Key bindings
  -- ------------------------------------------------------------------------------
  disable_default_key_bindings = true,
  keys = {
    { key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") },
    { key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },
  },
}
