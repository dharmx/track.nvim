---@diagnostic disable: param-type-mismatch
if vim.version().minor < 8 then
  vim.notify("track.nvim requires at least nvim-0.8.0.")
  return
end

if vim.g.loaded_track == 1 then return end
vim.g.loaded_track = 1

local V = vim.fn
local cmd = vim.api.nvim_create_user_command
local HI = vim.api.nvim_set_hl

-- TODO: Implement bang, range, repeat, motions and bar.

cmd("Track", function(...)
  local function get_root_and_bundle_opted()
    local State = require("track.state")
    State.load()
    local cwd = vim.fn.getcwd()
    return {
      track = {
        root_path = cwd,
        bundle_label = State._roots[cwd] and State._roots[cwd].main or "main",
      }
    }
  end

  local args = (...).fargs
  if args[1] == "save" then
    require("track.state").save()
  elseif args[1] == "load" then
    require("track.state").load()
  elseif args[1] == "loadsave" then
    assert(args[2] and type(args[2]) == "string", "Needs a path value.")
    require("track.state").loadsave("wipe", args[2])
  elseif args[1] == "reload" then
    require("track.state").reload()
  elseif args[1] == "wipe" then
    require("track.state").wipe()
  elseif args[1] == "remove" then
    require("track.state").rm()
  elseif args[1] == "bundles" then
    require("telescope").extensions.track.bundles(get_root_and_bundle_opted())
  else
    require("telescope").extensions.track.views(get_root_and_bundle_opted())
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
  local Config = require("track.config").get()
  local Core = require("track.core")
  local cwd = V.getcwd()
  for _, file in ipairs(files) do
    Core.mark(cwd, file)
    Core.history(cwd, nil, Config.disable_history, Config.maximum_history)
  end
end, {
  complete = "file",
  desc = "Mark current file.",
  nargs = "*",
})

cmd("MarkOpened", function()
  local Config = require("track.config").get()
  local Core = require("track.core")
  local cwd = V.getcwd()
  local listed_buffers = V.getbufinfo({ listed = 1 })
  for _, info in ipairs(listed_buffers) do
    local name = V.bufname(info.bufnr)
    if name ~= "" and not name:match("^term://") then
      Core.mark(cwd, name)
      Core.history(cwd, nil, Config.disable_history, Config.maximum_history)
    end
  end
end, {
  desc = "Mark all opened files.",
  nargs = 0,
})

cmd("Unmark", function(...)
  local files = (...).fargs
  if vim.tbl_isempty(files) then table.insert(files, V.expand("%")) end
  local Core = require("track.core")
  local cwd = V.getcwd()
  for _, file in ipairs(files) do
    Core.unmark(cwd, file)
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
cmd("StashBundle", function()
  local Core = require("track.core")
  Core.stash(V.getcwd())
end, {
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
cmd("RestoreBundle", function() require("track.core").restore(V.getcwd()) end, {
  desc = "Restore stashed bundle.",
  nargs = 0,
})

cmd("DeleteBundle", function(...)
  local label = (...).args
  local Core = require("track.core")
  local cwd = V.getcwd()
  if label == "" then label = nil end
  Core.delete(cwd, label)
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
cmd("AlternateBundle", function()
  require("track.core").alternate(V.getcwd())
end, {
  desc = "Restore stashed bundle.",
  nargs = 0,
})

-- Highlights {{{
HI(0, "TrackViewsAccessible", { foreground = "#79DCAA" })
HI(0, "TrackViewsInaccessible", { foreground = "#F87070" })
HI(0, "TrackViewsFocusedDisplay", { foreground = "#7AB0DF" })
HI(0, "TrackViewsFocused", { foreground = "#7AB0DF" })
HI(0, "TrackViewsIndex", { foreground = "#54CED6" })
HI(0, "TrackViewsMarkListed", { foreground = "#4B5259" })
HI(0, "TrackViewsFileIcon", { foreground = "#FFE59E" })
HI(0, "TrackViewsDirectoryIcon", { foreground = "#FFE59E" })
HI(0, "TrackViewsMarkUnlisted", { foreground = "#C397D8" })
HI(0, "TrackViewsMissing", { foreground = "#FFE59E" })
HI(0, "TrackViewsTerminal", { foreground = "#36C692" })
HI(0, "TrackViewsManual", { foreground = "#5FB0FC" })
HI(0, "TrackViewsDivide", { foreground = "#4B5259" })

HI(0, "TrackBundlesInactive", { foreground = "#4B5259" })
HI(0, "TrackBundlesDisplayInactive", { foreground = "#4B5259" })
HI(0, "TrackBundlesMain", { foreground = "#7AB0DF" })
HI(0, "TrackBundlesDisplayMain", { foreground = "#7AB0DF" })
HI(0, "TrackBundlesAlternate", { foreground = "#36C692" })
HI(0, "TrackBundlesDisplayAlternate", { foreground = "#79DCAA" })
HI(0, "TrackBundlesMark", { foreground = "#FFE59E" })
HI(0, "TrackBundlesHistory", { foreground = "#F87070" })
HI(0, "TrackBundlesDivide", { foreground = "#4B5259" })
-- }}}
