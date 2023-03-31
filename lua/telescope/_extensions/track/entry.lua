local M = {}

local V = vim.fn
local entry_display = require("telescope.pickers.entry_display")
local utils = require("telescope.utils")
local make_entry = require("telescope.make_entry")

function M.views(options)
  local icons = options.icons
  local disable_devicons = options.disable_devicons
  local displayer = entry_display.create({
    separator = icons.separator,
    items = {
      { width = 2 },
      { width = 3 },
      { width = 2 },
      { width = 1 },
      { remaining = true },
    },
  })

  local function make_display(entry)
    local marker, marker_hl = icons.accessible, "TrackViewsAccessible"
    if not entry.value:exists() then
      marker, marker_hl = icons.inaccessible, "TrackViewsInaccessible"
    end

    local display, display_hl = utils.transform_path(options, entry.value.absolute), ""
    if entry.value.focused_path  == entry.value.absolute then
      display_hl = "TrackViewsFocusedDisplay"
      marker, marker_hl = icons.focused, "TrackViewsFocused"
    end

    local icon, icon_hl = utils.get_devicons(entry.value.absolute, disable_devicons)
    if not icon_hl then icon, icon_hl = icons.file, "TrackViewsFileIcon" end
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
      ordinal = entry.index .. " : " .. entry.absolute,
      display = make_display,
    }, options)
  end
end

return M
