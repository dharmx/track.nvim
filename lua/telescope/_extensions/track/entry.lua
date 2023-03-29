local M = {}

local entry_display = require("telescope.pickers.entry_display")
local strings = require("plenary.strings")
local utils = require("telescope.utils")
local make_entry = require("telescope.make_entry")

function M.views(options)
  local icons = options.icons
  local disable_devicons = options.disable_devicons
  local icon_width = 0
  if not disable_devicons then
    local icon, _ = utils.get_devicons("fname", disable_devicons)
    icon_width = strings.strdisplaywidth(icon)
  end

  local display = entry_display.create({
    separator = icons.separator,
    items = {
      { width = 2 },
      { width = 3 },
      { width = 2 },
      { width = icon_width },
      { remaining = true },
    },
  })

  local function make_display(entry)
    local icon, hl = utils.get_devicons(entry.value.path, disable_devicons)
    local marker, marker_hl = icons.accessible, "TrackViewsAccessible"

    if not entry.value:exists() then
      marker, marker_hl = icons.inaccessible, "TrackViewsInaccessible"
    end
    local display_path, display_hl = entry.value.path, ""
    if entry.value.name == entry.value.path then
      display_hl = "TrackViewsFocusedDisplay"
      marker, marker_hl = icons.focused, "TrackViewsFocused"
    end
    if options.display_path then
      assert(type(options.display_path) == "function", "views_path should be false|nil|fun(path: string): string")
      display_path = options.display_path(entry.value.path)
    end

    local listed, listed_hl = " ", ""
    for _, info in ipairs(vim.fn.getbufinfo({ listed = 1 })) do
      if info.name == entry.value.absolute then
        listed, listed_hl = icons.listed, "TrackViewsMarkListed"
        break
      end
    end

    return display({
      { entry.value.index, "TrackViewsIndex" },
      { marker, marker_hl },
      { listed, listed_hl },
      { icon, hl },
      { display_path, display_hl },
    })
  end

  return function(entry)
    entry.name = vim.fn.bufname()
    return make_entry.set_default_entry_mt({
      value = entry,
      ordinal = entry.index .. " : " .. entry.path,
      display = make_display,
    }, options)
  end
end

return M
