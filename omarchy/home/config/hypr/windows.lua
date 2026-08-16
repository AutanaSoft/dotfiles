local widescreen_float = { float = true, center = true, size = { 1043, 587 } }
local opacity_config = { opacity = "1 1" }

-- o.window("^org.gnome.Nautilus$", widescreen_float)
-- o.window("^Spotify$", widescreen_float)
-- o.window("^org\\.omarchy\\.cliamp$", widescreen_float)
-- o.window("^org\\.omarchy\\.nvim$", widescreen_float)
-- o.window("^Alacritty$", widescreen_float)
-- o.window("^foot$", widescreen_float)
o.window("^discord$", widescreen_float, opacity_config)

o.window("^chrome-www\\.netflix\\.com__-Default$", opacity_config)
-- o.window("^chrome-web\\.whatsapp\\.com__-Default$", widescreen_float)
o.window("^chrome-www\\.youtube\\.com__-Default$", opacity_config)

-- Extend Omarchy's PiP title match for the Spanish title used by Chromium.
o.window({ title = "[Pp]antalla.?en.?[Pp]antalla" }, { tag = "+pip" })
o.window({ tag = "pip" }, { size = { 1043, 587 }, border_size = 0 })
