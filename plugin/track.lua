if vim.version().minor < 8 then
  vim.notify("track.nvim requires at least nvim 0.8.0")
  return
end

if vim.g.loaded_track == 1 then return end
vim.g.loaded_track = 1

local V = vim.fn
local A = vim.api
local if_nil = vim.F.if_nil

local cmd = A.nvim_create_user_command
local function HI(...) A.nvim_set_hl(0, ...) end

cmd("Track", function(data)
  local args = data.fargs
  if args[1] == "save" then
    require("track.state").save()
  elseif args[1] == "load" then
    require("track.state").load()
  elseif args[1] == "savefile" then
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
    require("track.core").pad:toggle()
  end
end, {
  desc = "track.nvim state operations.",
  nargs = "*",
  complete = function()
    return {
      "save",
      "load",
      "savefile",
      "reload",
      "wipe",
      "remove",
      "menu",
      "views",
      "pad",
      "bundles",
    }
  end,
})

cmd("Mark", function(data)
  local uri = vim.trim(data.args)
  uri = uri ~= "" and uri or A.nvim_buf_get_name(0)
  local uri_type = require("track.util").filetype(uri)
  local core = require("track.core")
  local P = require("plenary.path")
  if uri_type == "file" then uri = P:new(uri):make_relative(core.root_path) end
  core:mark(uri)
end, {
  complete = "file",
  desc = "Mark current file.",
  nargs = "?",
})

cmd("Unmark", function(data)
  local uri = vim.trim(data.args)
  uri = uri ~= "" and uri or A.nvim_buf_get_name(0)
  local uri_type = require("track.util").filetype(uri)
  local core = require("track.core")
  local P = require("plenary.path")
  if uri_type == "file" then uri = P:new(uri):make_relative(core.root_path) end
  core:unmark(uri)
end, {
  complete = function()
    local _, bundle = require("track.util").root_and_bundle()
    return bundle and bundle.views or {}
  end,
  desc = "Unmark current file.",
  range = true,
  nargs = "?",
})

cmd("MarkOpened", function()
  local buffers = V.getbufinfo({ buflisted = 1 })
  for _, info in ipairs(buffers) do
    local name = A.nvim_buf_get_name(info.bufnr)
    if name ~= "" and not name:match("^term://") then vim.cmd.Mark(name) end
  end
end, {
  desc = "Mark all opened files.",
  nargs = 0,
})

cmd("StashBundle", function()
  local core = require("track.core")
  core:stash()
  core(require("track.util").cwd())
end, {
  complete = function()
    local root, _ = require("track.util").root_and_bundle()
    return root and root.bundles("string") or {}
  end,
  desc = "Stash current bundle.",
  nargs = "?",
})

cmd("RestoreBundle", function()
  local core = require("track.core")
  core:restore()
  core(require("track.util").cwd())
end, {
  desc = "Restore stashed bundle.",
  nargs = 0,
})

cmd("DeleteBundle", function(data)
  local label = data.args
  local core = require("track.core")
  core:delete(label ~= "" and label or nil)
  core(require("track.util").cwd())
end, {
  desc = "Delete bundle.",
  nargs = "?",
  complete = function()
    local root, _ = require("track.util").root_and_bundle()
    return root and root.bundles("string") or {}
  end,
})

cmd("AlternateBundle", function()
  local core = require("track.core")
  core:alternate()
  core(require("track.util").cwd())
end, {
  desc = "Restore stashed bundle.",
  nargs = 0,
})

cmd("SelectMark", function(data)
  local args = vim.trim(data.args)
  ---@diagnostic disable-next-line: cast-local-type
  args = if_nil(tonumber(args), args)
  require("track.core"):select(args, require("track.config").get_hooks().on_select)
end, {
  desc = "Select a mark (view)",
  nargs = 1,
  complete = function()
    local _, bundle = require("track.util").root_and_bundle()
    return bundle and bundle.views or {}
  end,
})

-- Highlights {{{
HI("TrackPadTitle", { link = "TelescopeResultsTitle" })
HI("TrackPadEntryFocused", { foreground = "#7AB0DF" })
HI("TrackPadAccessible", { foreground = "#79DCAA" })
HI("TrackPadInaccessible", { foreground = "#F87070" })
HI("TrackPadFocused", { foreground = "#7AB0DF" })
HI("TrackPadMarkListed", { foreground = "#4B5259" })
HI("TrackPadMarkUnlisted", { foreground = "#C397D8" })
HI("TrackPadMissing", { foreground = "#FFE59E" })
HI("TrackPadLocked", { foreground = "#E37070" })
HI("TrackPadDivide", { foreground = "#4B5259" })

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
