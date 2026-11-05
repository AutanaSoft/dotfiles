-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
end
-- Essential application bindings.
o.rebind("SUPER + SHIFT + E", "Editor", { omarchy = "editor" })

-- Bindings for preinstalled Omarchy applications, TUIs, and web apps.
hl.unbind("SUPER + SHIFT + Q")
hl.unbind("SUPER + SHIFT + ALT + G")
o.rebind("SUPER + SHIFT + C", "Calculator", "omacalc")
if o.cmd_present("lazydocker") then
  o.rebind("SUPER + SHIFT + CTRL + D", "Docker", { tui = "omarchy-launch-docker-tui" })
end
o.rebind("SUPER + SHIFT + A", "Codex", "codex-desktop")
o.rebind("SUPER + SHIFT + W", "WhatsApp", { webapp = "https://web.whatsapp.com/", focus = true })
o.rebind("SUPER + SHIFT + D", "Discord", { launch = "discord", focus = "^discord$" })
o.rebind("SUPER + SHIFT + N", "Netflix", { webapp = "https://www.netflix.com/" })
