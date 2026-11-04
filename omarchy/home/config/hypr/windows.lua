-- Treat windows tagged as PiP by Omarchy like normal tiled windows.
o.window({ tag = "pip" }, {
  float = false,
  pin = false,
})
