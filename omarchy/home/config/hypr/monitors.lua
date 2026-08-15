-- Primary monitor: 24" AOC on DP-2.
-- Secondary monitor: 27" AOC on HDMI-A-1, placed to the left.
-- The 1080p display is vertically centered against the 1440p display.
hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@143.91", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-2", mode = "1920x1080@165", position = "2560x180", scale = 1 })
