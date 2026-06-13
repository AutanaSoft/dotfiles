local wezterm = require("wezterm")

return {
  -- ------------------------------------------------------------------------------
  -- WSL
  --
  -- This domain auto-launches a WSL distro when WezTerm starts on Windows.
  -- Remove or comment this line if running WezTerm directly on Linux/macOS or
  -- if your WSL distro name differs from "Fedora".
  -- ------------------------------------------------------------------------------

  default_domain = "WSL:Fedora",

  -- ------------------------------------------------------------------------------
  -- Rendering
  -- ------------------------------------------------------------------------------

  -- front_end = "OpenGL",
  max_fps = 120,

  -- ------------------------------------------------------------------------------
  -- Font
  -- ------------------------------------------------------------------------------

  font = wezterm.font("Monaspace Krypton NF"),
  font_size = 10,

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
  -- window_padding = { top = 0, right = 0, left = 0, bottom = 0 },
  enable_scroll_bar = false,

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

  enable_csi_u_key_encoding = true,
  underline_thickness = 2,
  underline_position = -2,
  scrollback_lines = 10000,
  enable_kitty_graphics = true,

  -- ------------------------------------------------------------------------------
  -- Keybindings
  -- ------------------------------------------------------------------------------

  keys = {
    {
      key = "Enter",
      mods = "ALT",
      action = wezterm.action.DisableDefaultAssignment,
    },
  },
}
