if vim.version().minor < 8 then
  vim.notify("nvim-colo requires at least nvim-0.8.0.")
  return
end

if vim.g.loaded_track == 1 then return end
vim.g.loaded_track = 1

local V = vim.fn
local cmd = vim.api.nvim_create_user_command
local highlight = vim.api.nvim_set_hl

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
  complete = function()
    return { "bundles", "marks", "roots", "track", "views" }
  end,
  desc = "Open a picker.",
  nargs = "?",
})

cmd("TrackMark", function(...)
  local files = (...).fargs
  if vim.tbl_isempty(files) then table.insert(files, V.expand("%")) end
  local Config = require("track.config").get()
  local Core = require("track.core")
  local cwd = V.getcwd()
  for _, file in ipairs(files) do Core.mark(cwd, file, nil, Config.save.on_mark) end
end, {
  complete = "file",
  desc = "Mark current file.",
  nargs = "*",
})

cmd("TrackUnmark", function(...)
  local files = (...).fargs
  if vim.tbl_isempty(files) then table.insert(files, V.expand("%")) end
  local Config = require("track.config").get()
  local Core = require("track.core")
  local cwd = V.getcwd()
  for _, file in ipairs(files) do Core.unmark(cwd, file, nil, Config.save.on_unmark) end
end, {
  complete = function()
    local cwd = V.getcwd()
    local root = require("track.state")._roots[cwd]
    if root and not root:empty() then
      local bundle = root:get_main_bundle()
      if bundle then return bundle.marks("string") end
      return {}
    end
    return {}
  end,
  desc = "Unmark current file.",
  nargs = "*",
})

---@todo
cmd("TrackStashBundle", function()
  local Config = require("track.config").get()
  local Core = require("track.core")
  Core.stash(V.getcwd(), Config.save.on_bundle)
end, {
  complete = function()
    local cwd = V.getcwd()
    local root = require("track.state")._roots[cwd]
    if root and not root:empty() then return root.bundles("string") end
    return {}
  end,
  desc = "Stash current bundle.",
  nargs = "*",
})

---@todo
cmd("TrackRestoreBundle", function()
  local Config = require("track.config").get()
  require("track.core").restore(V.getcwd(), Config.save.on_bundle)
end, {
  desc = "Restore stashed bundle.",
  nargs = 0,
})

---@todo
cmd("TrackAlternateBundle", function()
  local Config = require("track.config").get()
  require("track.core").alternate(V.getcwd(), Config.save.on_alternate)
end, {
  desc = "Restore stashed bundle.",
  nargs = 0,
})

highlight(0, "TrackViewsAccessible", {
  foreground = "#79DCAA",
})

highlight(0, "TrackViewsInaccessible", {
  foreground = "#FFE59E",
})

highlight(0, "TrackViewsFocusedDisplay", {
  foreground = "#7AB0DF",
  bold = true,
})

highlight(0, "TrackViewsFocused", {
  foreground = "#7AB0DF",
})

highlight(0, "TrackViewsIndex", {
  foreground = "#54CED6",
})

highlight(0, "TrackViewsMarkListed", {
  foreground = "#4B5259"
})
