local M = {}

-- WARN: Do not import track.config in track.util.
local util = require("track.util")
local if_nil = vim.F.if_nil

-- TODO: Implement validation (vim.validate) and config fallback.
-- TODO: Defaults (M.defaults) will be used if config values are invalid.
-- TODO: Implement a way to show hidden files.

M._defaults = {
  savepath = "/tmp/track.json",
  prompt_prefix = " 粒 ",
  previewer = false,
  initial_mode = "insert",
  save = {
    on_mark = false,
    on_unmark = false,
    on_position_mark = false,
    on_position_unmark = false,
    on_line_mark = false,
    on_line_unmark = false,
    on_close = true,
    on_stash = false,
    on_swap = false,
  },
  layout_config = {
    preview_cutoff = 1,
    width = function(_, max_columns, _) return math.min(max_columns, 50) end,
    height = function(_, _, max_lines) return math.min(max_lines, 15) end,
  },
  callbacks = {
    on_open = util.mute,
    on_close = util.mute,
    on_save = util.mute,
    on_load = util.mute,
    on_delete = function(_, picker)
      local entries = if_nil(picker:get_multi_selection(), {})
      if #entries == 0 then table.insert(entries, picker:get_selection()) end
      vim.tbl_map(function(entry) require("track.mark").unmark_file(entry.value) end, entries)
    end,
    on_choose = function(_, picker)
      local entries = if_nil(picker:get_multi_selection(), {})
      if #entries == 0 then table.insert(entries, picker:get_selection()) end
      vim.tbl_map(function(entry) vim.cmd("confirm edit " .. entry.value) end, entries)
    end,
  },
  log = {
    plugin = "track.nvim",
    level = "error",
  },
  roots = {},
  ---@todo disable_devicons = boolean
  ---@todo view = "metadata"|"contents"
}
M._current = vim.deepcopy(M._defaults)

function M.merge(options)
  options = if_nil(options, {})
  M._current = vim.tbl_deep_extend("keep", options, M._current)
end

function M.get() return M._current end

return M