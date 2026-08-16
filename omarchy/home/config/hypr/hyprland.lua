-- Personal Omarchy 4 entry point. Load packaged defaults first, then tracked
-- user modules so package updates do not overwrite this configuration.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

require("default.hypr.omarchy")
require("hypr.monitors")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.windows")

-- Load Omarchy's dynamic toggles and saved workspace layouts.
require("default.hypr.toggles")
