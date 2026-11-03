local source = "omarchy/home/config/hypr/workspaces.lua"

local function check(monitor, workspace_id)
  local config, rule, requested_monitor, requested_slot
  hl = {
    config = function(value) config = value end,
    get_monitor = function(name)
      assert(name == "DP-1")
      return monitor
    end,
    workspace_rule = function(value) rule = value end,
  }
  o = { workspaces = {
    workspace_id = function(value, slot)
      requested_monitor, requested_slot = value, slot
      return workspace_id
    end,
  } }
  dofile(source)
  assert(config.master.mfact == 0.67 and config.master.new_status == "slave")
  if monitor and not monitor.is_mirror then
    assert(requested_monitor == monitor and requested_slot == 1)
    assert(rule.workspace == string.format("r[%d-%d] m[DP-1]", workspace_id, workspace_id))
    assert(rule.layout == "master" and rule.layout_opts.orientation == "left")
  else
    assert(rule == nil and requested_monitor == nil)
  end
end

check({ name = "DP-1" }, 1)
check({ name = "DP-1" }, 11)
check(nil)
check({ name = "DP-1", is_mirror = true })
print("workspace configuration tests passed")
