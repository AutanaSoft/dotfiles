-- Primary monitor: AOC on DP-2.
-- Temporary secondary monitor: ASUS VG259QR on DP-1, placed to the left.
-- Both displays use 1080p with aligned top edges.
hl.monitor({ output = "DP-1", mode = "1920x1080@165", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-2", mode = "1920x1080@165", position = "1920x0", scale = 1 })
