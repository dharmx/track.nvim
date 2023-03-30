local M = {}

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

    options.cwd = options.track_options.root_path()
    local display, display_hl = utils.transform_path(options, entry.value.path), ""
    if entry.value.focused_path  == entry.value.absolute then
      display_hl = "TrackViewsFocusedDisplay"
      marker, marker_hl = icons.focused, "TrackViewsFocused"
    end

    local icon, icon_hl = utils.get_devicons(entry.value.path, disable_devicons)
    if not icon_hl then icon, icon_hl = icons.file, "TrackViewsFileIcon" end
    local listed, listed_hl = icons.unlisted, "TrackViewsMarkUnlisted"
    for _, info in ipairs(vim.fn.getbufinfo({ loaded = 1 })) do
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
    entry.focused_path = vim.fn.fnamemodify(vim.fn.bufname(), ":p")
    return make_entry.set_default_entry_mt({
      value = entry,
      ordinal = entry.index .. " : " .. entry.path,
      display = make_display,
    }, options)
  end
end

return M
