-- Keep the 67/33 split and first window as master when using the master layout.
hl.config({
  master = {
    mfact = 0.67,
    new_status = "slave",
  },
})

-- Resolve the slot at config load; DP-1 must be connected at that time.
local monitor = hl.get_monitor("DP-1")
if monitor and not monitor.is_mirror then
  local workspace = o.workspaces.workspace_id(monitor, 1)
  hl.workspace_rule({
    workspace = string.format("r[%d-%d] m[DP-1]", workspace, workspace),
    layout = "master",
    layout_opts = { orientation = "left" },
  })
end
