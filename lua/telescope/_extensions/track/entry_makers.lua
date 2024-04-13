local M = {}

local V = vim.fn

local entry_display = require("telescope.pickers.entry_display")
local utils = require("telescope.utils")
local make_entry = require("telescope.make_entry")

function M.gen_from_views(opts)
  local icons = opts.icons
  local disable_devicons = opts.disable_devicons
  local displayer = entry_display.create({
    separator = icons.separator,
    separator_hl = "TrackViewsDivide",
    items = {
      -- hardcoded
      { width = 1 },
      {},
      {},
      { width = 1 },
      { remaining = true },
    },
  })

  -- indicators (pretty colors, symbols and shiny things) @derhans would be displeased
  local function make_display(entry)
    ---@type Mark
    local mark = entry.value
    -- we may/may not have read permissions on that file - priority: 1
    local marker, marker_hl = icons.accessible, "TrackViewsAccessible"
    if not vim.loop.fs_access(mark.path, "R") then
      marker, marker_hl = icons.inaccessible, "TrackViewsInaccessible"
    end

    -- the marked value might be deleted - priority: 2
    if vim.startswith(mark.path, "term:/") then
      marker, marker_hl = icons.terminal, "TrackViewsTerminal"
    elseif vim.startswith(mark.path, "man:/") then
      marker, marker_hl = icons.manual, "TrackViewsManual"
    ---@diagnostic disable-next-line: undefined-field
    elseif not mark:exists() then
      marker, marker_hl = icons.missing, "TrackViewsMissing"
    end

    -- file must be currently being edited - priority: 3
    local display, display_hl = utils.transform_path(opts, mark.absolute), ""
    if entry.value.focused_path == mark.absolute then
      display_hl = "TrackViewsFocusedDisplay"
      marker, marker_hl = icons.focused, "TrackViewsFocused"
    end
    -- add more?

    -- if the entry is a directory
    -- if there is no icons of that filetype in the devicons db
    local icon, icon_hl = utils.get_devicons(entry.value.absolute, disable_devicons)
    if mark.type == "directory" then
      icon, icon_hl = icons.directory, "TrackViewsDirectoryIcon"
    elseif not icon_hl then
      icon, icon_hl = icons.file, "TrackViewsFileIcon"
    end

    -- is the buffer listed (is it opened in nvim currently)
    local listed, listed_hl = icons.unlisted, "TrackViewsMarkUnlisted"
    for _, info in ipairs(V.getbufinfo({ loaded = 1 })) do
      if info.name == mark.absolute and info.listed == 1 then
        listed, listed_hl = icons.listed, "TrackViewsMarkListed"
        break
      end
    end

    return displayer({
      { entry.value.index, "TrackViewsIndex" },
      { marker, marker_hl },
      { listed, listed_hl },
      { icon, icon_hl },
      { display, display_hl },
    })
  end

  return function(entry)
    entry.focused_path = V.fnamemodify(V.bufname(), ":p")
    return make_entry.set_default_entry_mt({
      value = entry,
      ordinal = entry.index .. ":" .. entry.absolute,
      display = make_display,
    }, opts)
  end
end

function M.gen_from_bundles(opts)
  ---@type Root
  local root = require("track.state")._roots[opts.track.root_path]
  local icons = opts.icons
  local displayer = entry_display.create({
    separator = icons.separator,
    separator_hl = "TrackBundlesDivide",
    items = {
      {}, -- views-marks
      {}, -- history-deleted
      {}, -- main / alternate / inactive
      { remaining = true },
    },
  })

  local function make_display(entry)
    ---@type Bundle
    local bundle = entry.value
    local display, display_hl = bundle.label, "TrackBundlesInactive"
    local state, state_hl = icons.inactive, "TrackBundlesDisplayInactive"
    if root.main == bundle.label then
      state, state_hl = icons.main, "TrackBundlesMain"
      display, display_hl = bundle.label, "TrackBundlesDisplayMain"
    elseif root.previous == bundle.label then
      state, state_hl = icons.alternate, "TrackBundlesAlternate"
      display, display_hl = bundle.label, "TrackBundlesDisplayAlternate"
    end

    local mark, mark_hl = string.format("%s %s", icons.mark, #bundle.views), "TrackBundlesMark"
    local history, history_hl = string.format("%s %s", icons.history, #bundle.history), "TrackBundlesHistory"
    return displayer({
      { mark, mark_hl },
      { history, history_hl },
      { state, state_hl },
      { display, display_hl },
    })
  end

  return function(entry)
    return make_entry.set_default_entry_mt({
      value = entry,
      ordinal = entry.label,
      display = make_display,
    }, opts)
  end
end

return M
