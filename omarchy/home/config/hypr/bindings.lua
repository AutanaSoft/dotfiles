-- Replace only the Omarchy defaults that have a personal equivalent.
for _, keys in ipairs({
  "SUPER + SHIFT + B",
  "SUPER + SHIFT + C",
  "SUPER + SHIFT + D",
  "SUPER + SHIFT + E",
  "SUPER + SHIFT + N",
  "SUPER + SHIFT + S",
  "SUPER + SHIFT + W",
  "SUPER + SHIFT + Y",
  "SUPER + ALT + RETURN"
}) do
  hl.unbind(keys)
end

o.bind("SUPER + SHIFT + T", "Tmux", { omarchy = "terminal-tmux" })
o.bind("SUPER + ALT + RETURN", "Zellij", 'omarchy-launch-terminal bash -c "exec zellij attach --create AutanaSoft"')
o.bind("SUPER + SHIFT + B", "Browser (private)", { omarchy = "browser --private" })
o.bind("SUPER + SHIFT + C", "Calculator", "omacalc")
o.bind("SUPER + SHIFT + D", "Discord", { launch = "discord", focus = "^discord$" })
o.bind("SUPER + SHIFT + E", "Editor", { omarchy = "editor" })
o.bind("SUPER + SHIFT + CTRL + D", "Docker", { tui = "lazydocker" })
-- Keep the Omarchy webapp binding as a reference; launch Netflix explicitly with Chromium.
-- o.bind("SUPER + SHIFT + N", "Netflix", { webapp = "https://www.netflix.com/" })
o.bind("SUPER + SHIFT + N", "Netflix", { launch = "chromium --app=https://www.netflix.com/" })
o.bind("SUPER + SHIFT + R", "Raadio TUI", { tui = "cliamp", focus = true })
o.bind("SUPER + SHIFT + S", "Spotify", { omarchy = "spotify" })
o.bind("SUPER + SHIFT + W", "WhatsApp", { webapp = "https://web.whatsapp.com/", focus = true })
o.bind("SUPER + SHIFT + Y", "YouTube", { webapp = "https://www.youtube.com/" })
