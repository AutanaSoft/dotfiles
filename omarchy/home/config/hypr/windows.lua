-- Custom tag
o.window({ tag = "full-opacity" }, { tag = "-default-opacity", opacity = "1 1" })

-- Remove default opacity
o.window({ class = "^discord$" }, { tag = "+full-opacity" })
o.window("^chrome-www\\.netflix\\.com__-Default$", { tag = "+full-opacity" })
o.window("^chrome-www\\.youtube\\.com__-Default$", { tag = "+full-opacity" })
-- o.window("^chrome-web\\.whatsapp\\.com__-Default$", { tag = "+full-opacity" })

-- Extend Omarchy's PiP title match for the Spanish title used by Chromium.
o.window({ title = "[Pp]antalla.?en.?[Pp]antalla" }, { tag = "+pip" })
-- o.window({ tag = "pip" }, { size = { 1043, 587 }, border_size = 0 })
