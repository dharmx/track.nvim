if vim.version().minor < 8 then
  vim.notify("nvim-colo requires at least nvim-0.8.0.")
  return
end

if vim.g.loaded_track == 1 then return end
vim.g.loaded_track = 1

local cmd = vim.api.nvim_create_user_command
local V = vim.fn

-- TODO: Implement bang, range, repeat, motions and bar.

cmd("Track", function(...)
  local args = (...).fargs
  local State = require("track.state")
  local save = require("track.config").get().save

  if args[1] == "save" then
    State.save(save.before_save, save.on_save)
  elseif args[1] == "load" then
    State.load(save.on_load)
  elseif args[1] == "loadsave" then
    assert(args[2] and type(args[2]) == "string", "Needs a path value.")
    State.loadsave("wipe", args[2], save.on_load)
  elseif args[1] == "reload" then
    State.reload(save.on_reload)
  elseif args[1] == "wipe" then
    State.wipe()
  elseif args[1] == "remove" then
    State.rm()
  else
    require("telescope").extensions.track.track()
  end
end, {
  desc = "State operations like: save, load, loadsave, reload, wipe and remove. marks for showing current mark list.",
  nargs = "*",
  complete = function() return { "save", "load", "loadsave", "reload", "wipe", "remove", "menu" } end,
})

cmd("TrackPick", function(...)
  local args = (...).args
  local tele = require("telescope")
  local open = tele.extensions.track[args]
  if args == "" or not open then
    tele.extensions.track.track()
    return
  end
  open()
end, {
  desc = "Open a picker.",
  nargs = "?",
})

cmd("TrackMark", function()
  local Config = require("track.config").get()
  require("track.core").mark(V.getcwd(), V.expand("%"), nil, Config.save.on_mark)
end, {
  desc = "Mark current file.",
  nargs = 0,
})

cmd("TrackUnmark", function()
  local Config = require("track.config").get()
  require("track.core").unmark(V.getcwd(), V.expand("%"), nil, Config.save.on_unmark)
end, {
  desc = "Unmark current file.",
  nargs = 0,
})

cmd("TrackStashBundle", function()
  local Config = require("track.config").get()
  require("track.core").stash(V.getcwd(), Config.save.on_bundle)
end, {
  desc = "Stash current bundle.",
  nargs = 0,
})

cmd("TrackRestoreBundle", function()
  local Config = require("track.config").get()
  require("track.core").restore(V.getcwd(), Config.save.on_bundle)
end, {
  desc = "Restore stashed bundle.",
  nargs = 0,
})

cmd("TrackAlternateBundle", function()
  local Config = require("track.config").get()
  require("track.core").alternate(V.getcwd(), Config.save.on_alternate)
end, {
  desc = "Restore stashed bundle.",
  nargs = 0,
})
