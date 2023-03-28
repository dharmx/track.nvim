local M = {}

local entry_display = require("telescope.pickers.entry_display")
local strings = require("plenary.strings")
local utils = require("telescope.utils")
local make_entry = require("telescope.make_entry")

function M.views(options)
  local icon_width = 0
  if not options.icons.disable_devicons then
    local icon, _ = utils.get_devicons("fname", options.icons.disable_devicons)
    icon_width = strings.strdisplaywidth(icon)
  end

  local display = entry_display.create({
    separator = options.icons.separator,
    items = {
      { width = 2 },
      { width = 3 },
      { width = icon_width },
      { remaining = true },
    },
  })

  local make_display = function(entry)
    local icon, hl = utils.get_devicons(entry.value.path, options.icons.disable_devicons)
    local marker, marker_hl = options.icons.accessible, "String"
    if not entry.value:exists() then
      marker, marker_hl = options.icons.inaccessible, "ErrorMsg"
    end
    local display_path, display_hl = entry.value.path, ""
    if entry.value.name == entry.value.path then
      display_hl = "Define"
      marker, marker_hl = options.icons.focused, "Define"
    end
    if options.views_path then
      assert(type(options.views_path) == "function", "views_path should be false|nil|fun(path: string): string")
      display_path = options.views_path(entry.value.path)
    end
    return display({
      { entry.value.index, "TelescopeResultsNumber" },
      { marker, marker_hl },
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
