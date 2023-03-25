local M = {}

-- WARN: Do not import track.config in track.util.
local util = require("track.util")

-- TODO: Implement validation (vim.validate) and config fallback.
-- TODO: Defaults (M.defaults) will be used if config values are invalid.
-- TODO: Implement a way to show hidden files.

M._defaults = {
  savepath = "/tmp/track.json",
  prompt_prefix = " 粒 ",
  previewer = false,
  initial_mode = "insert",
  save = {
    on_close = true,
    on_mark = false,
    on_unmark = false,
    on_swap = false,
    on_move = false,
    on_stash = false,
  },
  layout_config = {
    preview_cutoff = 1,
    width = function(_, max_columns, _) return math.min(max_columns, 50) end,
    height = function(_, _, max_lines) return math.min(max_lines, 15) end,
  },
  callbacks = {
    before_save = util.mute,
    on_reload = util.mute,
    on_open = util.mute,
    on_close = util.mute,
    on_save = util.mute,
    on_load = util.mute,
    on_delete = util.mute,
    on_choose = function(_, picker)
      local entries = vim.F.if_nil(picker:get_multi_selection(), {})
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
  options = vim.F.if_nil(options, {})
  M._current = vim.tbl_deep_extend("keep", options, M._current)
end

function M.get() return M._current end

return M
