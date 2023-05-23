local M = {}

local V = vim.fn

local entry_display = require("telescope.pickers.entry_display")
local utils = require("telescope.utils")
local make_entry = require("telescope.make_entry")

function M.gen_from_views(options)
  local icons = options.icons
  local disable_devicons = options.disable_devicons
  local displayer = entry_display.create({
    separator = icons.separator,
    items = {
      -- hardcoded
      { width = 2 },
      { width = 3 },
      { width = 2 },
      { width = 1 },
      { remaining = true },
    },
  })

  -- indicators (pretty colors, symbols and shiny things) @derhans would be displeased
  local function make_display(entry)
    -- we may/may not have read permissions on that file - priority: 1
    local marker, marker_hl = icons.accessible, "TrackViewsAccessible"
    if not vim.loop.fs_access(entry.value.path, "R") then
      marker, marker_hl = icons.inaccessible, "TrackViewsInaccessible"
    end

    -- the marked value might be deleted - priority: 2
    if vim.startswith(entry.value.path, "term:/") then
      marker, marker_hl = icons.terminal, "TrackViewsTerminal"
    elseif vim.startswith(entry.value.path, "man:/") then
      marker, marker_hl = icons.manual, "TrackViewsManual"
    elseif not entry.value:exists() then
      marker, marker_hl = icons.missing, "TrackViewsMissing"
    end

    -- file must be currently being edited - priority: 3
    local display, display_hl = utils.transform_path(options, entry.value.absolute), ""
    if entry.value.focused_path  == entry.value.absolute then
      display_hl = "TrackViewsFocusedDisplay"
      marker, marker_hl = icons.focused, "TrackViewsFocused"
    end
    -- add more?

    -- if there is no icons of that filetype in the devicons db
    local icon, icon_hl = utils.get_devicons(entry.value.absolute, disable_devicons)
    if not icon_hl then icon, icon_hl = icons.file, "TrackViewsFileIcon" end

    -- is the buffer listed (is it opened in nvim currently)
    local listed, listed_hl = icons.unlisted, "TrackViewsMarkUnlisted"
    for _, info in ipairs(V.getbufinfo({ loaded = 1 })) do
      if info.name == entry.value.absolute and info.listed == 1 then
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
    }, options)
  end
end

return M
