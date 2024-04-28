if vim.version().minor < 8 then
  vim.notify("track.nvim requires at least nvim-0.8.0.")
  return
end

if vim.g.loaded_track == 1 then return end
vim.g.loaded_track = 1

local V = vim.fn
local cmd = vim.api.nvim_create_user_command
local function HI(...) vim.api.nvim_set_hl(0, ...) end

-- TODO: Implement bang, range, repeat, motions and bar.

cmd("Track", function(...)
  local args = (...).fargs
  if args[1] == "save" then
    require("track.state").save()
  elseif args[1] == "load" then
    require("track.state").load()
  elseif args[1] == "loadsave" then
    assert(args[2] and type(args[2]) == "string", "Needs a path value.")
    require("track.state").load_save("wipe", args[2])
  elseif args[1] == "reload" then
    require("track.state").reload()
  elseif args[1] == "wipe" then
    require("track.state").wipe()
  elseif args[1] == "remove" then
    require("track.state").remove()
  elseif args[1] == "bundles" then
    require("telescope").extensions.track.bundles()
  elseif args[1] == "views" then
    require("telescope").extensions.track.views()
  else
    require("telescope").extensions.track.views()
  end
end, {
  desc = "State operations like: save, load, loadsave, reload, wipe and remove. marks for showing current mark list.",
  nargs = "*",
  complete = function()
    return {
      "save",
      "load",
      "loadsave",
      "reload",
      "wipe",
      "remove",
      "menu",
      "bundles",
    }
  end,
})

cmd("Mark", function(...)
  local files = (...).fargs
  if vim.tbl_isempty(files) then table.insert(files, V.expand("%")) end
  local config = require("track.config").get()
  local core = require("track.core")
  for _, file in ipairs(files) do
    core:mark(file):history(config.disable_history, config.maximum_history)
  end
end, {
  complete = "file",
  desc = "Mark current file.",
  nargs = "*",
})

cmd("MarkOpened", function()
  local config = require("track.config").get()
  local core = require("track.core")
  local listed_buffers = V.getbufinfo({ listed = 1 })
  for _, info in ipairs(listed_buffers) do
    local name = V.bufname(info.bufnr)
    if name ~= "" and not name:match("^term://") then
      core:mark(name):history(config.disable_history, config.maximum_history)
    end
  end
end, {
  desc = "Mark all opened files.",
  nargs = 0,
})

cmd("Unmark", function(...)
  local files = (...).fargs
  if vim.tbl_isempty(files) then table.insert(files, V.expand("%")) end
  local core = require("track.core")
  for _, file in ipairs(files) do
    core:unmark(file)
  end
end, {
  complete = function()
    local cwd = V.getcwd()
    local root = require("track.state")._roots[cwd]
    if root then
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
cmd("StashBundle", function() require("track.core"):stash() end, {
  complete = function()
    local cwd = V.getcwd()
    local root = require("track.state")._roots[cwd]
    if root then return root.bundles("string") end
    return {}
  end,
  desc = "Stash current bundle.",
  nargs = "*",
})

---@todo
cmd("RestoreBundle", function() require("track.core"):restore() end, {
  desc = "Restore stashed bundle.",
  nargs = 0,
})

cmd("DeleteBundle", function(...)
  local label = (...).args
  if label == "" then label = nil end
  require("track.core"):delete(label)
end, {
  desc = "Delete bundle.",
  nargs = "?",
  complete = function()
    local cwd = V.getcwd()
    local root = require("track.state")._roots[cwd]
    if root then return root.bundles("string") end
    return {}
  end,
})

---@todo
cmd("AlternateBundle", function() require("track.core"):alternate() end, {
  desc = "Restore stashed bundle.",
  nargs = 0,
})

-- Highlights {{{
HI("TrackPadTitle", { link = "TelescopeResultsTitle" })

HI("TrackViewsAccessible", { foreground = "#79DCAA" })
HI("TrackViewsInaccessible", { foreground = "#F87070" })
HI("TrackViewsFocusedDisplay", { foreground = "#7AB0DF" })
HI("TrackViewsFocused", { foreground = "#7AB0DF" })
HI("TrackViewsIndex", { foreground = "#54CED6" })
HI("TrackViewsMarkListed", { foreground = "#4B5259" })
HI("TrackViewsMarkUnlisted", { foreground = "#C397D8" })
HI("TrackViewsMissing", { foreground = "#FFE59E" })
HI("TrackViewsFile", { foreground = "#FFE59E" })
HI("TrackViewsDirectory", { foreground = "#FFE59E" })
HI("TrackViewsSite", { foreground = "#66B3FF" })
HI("TrackViewsTerminal", { foreground = "#36C692" })
HI("TrackViewsManual", { foreground = "#5FB0FC" })
HI("TrackViewsDivide", { foreground = "#4B5259" })
HI("TrackViewsLocked", { foreground = "#E37070" })

HI("TrackBundlesInactive", { foreground = "#4B5259" })
HI("TrackBundlesDisplayInactive", { foreground = "#4B5259" })
HI("TrackBundlesMain", { foreground = "#7AB0DF" })
HI("TrackBundlesDisplayMain", { foreground = "#7AB0DF" })
HI("TrackBundlesAlternate", { foreground = "#36C692" })
HI("TrackBundlesDisplayAlternate", { foreground = "#79DCAA" })
HI("TrackBundlesMark", { foreground = "#FFE59E" })
HI("TrackBundlesHistory", { foreground = "#F87070" })
HI("TrackBundlesDivide", { foreground = "#151A1F" })
HI("TrackBundlesIndex", { foreground = "#54CED6" })
-- }}}
