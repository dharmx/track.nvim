local M = {}

local V = vim.fn

local entry_display = require("telescope.pickers.entry_display")
local utils = require("telescope.utils")
local util = require("track.util")
local make_entry = require("telescope.make_entry")

-- TODO: Add a way to match if the current focused_path is a command or, a manpage

function M.gen_from_view(opts)
  local icons = opts.icons
  local displayer = entry_display.create({
    separator = icons.separator,
    separator_hl = "TrackViewsDivide",
    items = {
      -- hardcoded
      { width = 2 },
      {},
      {},
      {},
      {},
    },
  })

  -- indicators (pretty colors, symbols and shiny things) @derhans would be displeased
  local function make_display(entry)
    local mark = entry.value
    local absolute = mark:absolute()
    local allowed = vim.tbl_contains({ "term", "man", "http", "https" }, mark.type)

    -- we may/may not have read permissions on that file - priority: 1
    local marker, marker_hl = icons.accessible, "TrackViewsAccessible"
    if not mark:readable() then
      marker, marker_hl = icons.inaccessible, "TrackViewsInaccessible"
    end

    -- the marked value might be deleted - priority: 2
    if allowed then
      marker, marker_hl = icons.locked, "TrackViewsLocked"
    elseif not mark:exists() then
      marker, marker_hl = icons.missing, "TrackViewsMissing"
    end

    -- file must be currently being edited - priority: 3
    local display, display_hl = absolute, ""
    if not allowed then
      display = utils.transform_path(opts, mark.path)
    elseif mark.type == "term" then
      display = util.transform_term_uri(mark.path)
    elseif mark.type == "man" then
      display = util.transform_man_uri(mark.path)
    elseif mark.type == "https" then
      display = util.transform_site_uri(mark.path)
    end

    if opts._focused == absolute then
      display_hl = "TrackViewsFocusedDisplay"
      marker, marker_hl = icons.focused, "TrackViewsFocused"
    end
    -- add more?

    local icon, icon_hl = util.get_icon(mark, icons, opts)

    -- is the buffer listed (is it opened in nvim currently)
    local listed, listed_hl = icons.unlisted, "TrackViewsMarkUnlisted"
    local buffers = V.getbufinfo({ bufloaded = 1 })
    for _, info in ipairs(buffers) do
      if info.name == absolute and info.listed == 1 then
        listed, listed_hl = icons.listed, "TrackViewsMarkListed"
        break
      end
    end

    return displayer({
      { entry.index, "TrackViewsIndex" },
      { marker, marker_hl },
      { listed, listed_hl },
      { icon, icon_hl },
      { display, display_hl },
    })
  end

  return function(entry)
    return make_entry.set_default_entry_mt({
      value = entry,
      ordinal = entry:absolute(),
      display = make_display,
    }, opts)
  end
end

function M.gen_from_bundle(opts)
  ---@type Root
  local root, _ = util.root_and_bundle()
  local icons = opts.icons
  local displayer = entry_display.create({
    separator = icons.separator,
    separator_hl = "TrackBundlesDivide",
    items = {
      { width = 2 }, -- hardcoded
      {}, -- views-marks
      {}, -- history-deleted
      {}, -- main / alternate / inactive
      {}, -- { remaining = true } is implied
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
      { entry.index, "TrackBundlesIndex" },
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
