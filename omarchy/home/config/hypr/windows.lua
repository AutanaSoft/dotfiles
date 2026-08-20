-- Custom tag
o.window({ tag = "full-opacity" }, { tag = "-default-opacity", opacity = "1 1" })

-- Remove default opacity
o.window({ class = "^discord$" }, { tag = "+full-opacity" })
o.window("^chrome-www\\.netflix\\.com__-Default$", { tag = "+full-opacity" })
o.window("^chrome-www\\.youtube\\.com__-Default$", { tag = "+full-opacity" })
-- o.window("^chrome-web\\.whatsapp\\.com__-Default$", { tag = "+full-opacity" })

-- Mark regular Chrome PiP windows only.
-- The generic "PIP" pattern is omitted to avoid matching Meet.
local chrome_pip_title = "[Pp]antalla.?en.?[Pp]antalla|[Pp]icture.?in.?[Pp]icture"
o.window({ title = chrome_pip_title }, { tag = "+no-pip" })

-- Regular Chrome PiP: remove inherited PiP behavior.
o.window({ tag = "no-pip" }, { tag = "-pip" })
o.window({ tag = "no-pip" }, { tag = "-default-opacity" })
o.window({ tag = "no-pip" }, {
  float = false,
  pin = false,
  size = { 1043, 587 },
  keep_aspect_ratio = true,
  opacity = "1 1",
})

-- Meet keeps Omarchy's behavior; only override its size.
o.window({ tag = "chromium-based-browser", title = "^Meet - .+" }, {
  size = { 1043, 587 },
})
