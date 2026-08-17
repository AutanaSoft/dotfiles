-- These master defaults provide workspace 1's 67/33 split and retain its first window as master.
hl.config({
  master = {
    mfact = 0.67,
    new_status = "slave",
  },
})

-- Limit the master layout itself to workspace 1; its stack stays on the right.
hl.workspace_rule({
  workspace = "1",
  layout = "master",
  layout_opts = {
    orientation = "left",
  },
})
