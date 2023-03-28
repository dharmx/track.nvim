local M = {}

-- WARN: Do not import track.config in track.util.
local util = require("track.util")

-- TODO: Implement validation (vim.validate) and config fallback.
-- TODO: Defaults (M.defaults) will be used if config values are invalid.
-- TODO: Implement a way to show hidden files.
-- TODO: Asyncify saving.
-- TODO: disable_devicons = boolean
-- TODO: Add view = "metadata"|"contents"

M._defaults = {
  savepath = "/tmp/track.json",
  prompt_prefix = " 粒 ",
  previewer = false,
  initial_mode = "insert",
  save = {
    on_views_close = true,
    on_marks_close = false,
    on_bundles_close = false,
    on_roots_close = false,
    on_track_close = false,
  },
  layout_config = {
    preview_cutoff = 1,
    width = function(_, max_columns, _) return math.min(max_columns, 50) end,
    height = function(_, _, max_lines) return math.min(max_lines, 15) end,
  },
  hooks = {
    on_track_close = util.mute,
    on_views_close = util.mute,
    on_roots_close = util.mute,
    on_bundles_close = util.mute,
    on_marks_close = util.mute,

    on_track_open = util.mute,
    on_views_open = util.mute,
    on_roots_open = util.mute,
    on_bundles_open = util.mute,
    on_marks_open = util.mute,

    on_views_choose = function(_, picker)
      local entries = vim.F.if_nil(picker:get_multi_selection(), {})
      if #entries == 0 then table.insert(entries, picker:get_selection()) end
      vim.tbl_map(function(entry) vim.cmd("confirm edit " .. entry.value.path) end, entries)
    end,
    on_roots_choose = util.mute,
    on_bundles_choose = util.mute,
    on_track_choose = function(_, picker)
      local entry = picker:get_selection()
      require("telescope").extensions.track[entry.value:lower()]()
    end,
    on_marks_choose = util.mute,
  },
  mappings = {
    track = function(_, map)
      local actions = require("telescope.actions")
      map("i", "<C-K>", actions.move_selection_previous)
      map("i", "<C-J>", actions.move_selection_next)
      map("i", "<C-E>", actions.close)
    end,
    roots = function(_, map)
      local actions = require("telescope.actions")
      map("i", "<C-K>", actions.move_selection_previous)
      map("i", "<C-J>", actions.move_selection_next)
      map("i", "<C-E>", actions.close)
    end,
    views = function(_, map)
      local actions = require("telescope.actions")
      map("i", "<C-K>", actions.move_selection_previous)
      map("i", "<C-J>", actions.move_selection_next)
      map("i", "<C-E>", actions.close)
    end,
    marks = function(_, map)
      local track_actions = require("telescope._extensions.track.actions")
      map("n", "dd", track_actions.delete)
      map("i", "<C-D>", track_actions.delete)

      local actions = require("telescope.actions")
      map("i", "<C-K>", actions.move_selection_previous)
      map("i", "<C-J>", actions.move_selection_next)
      map("i", "<C-S>", actions.file_split)
      map("i", "<C-V>", actions.file_vsplit)
      map("i", "<C-E>", actions.close)
    end,
    bundles = function(_, map)
      local track_actions = require("telescope._extensions.track.actions")
      map("n", "dd", track_actions.delete)
      map("i", "<C-D>", track_actions.delete)

      local actions = require("telescope.actions")
      map("i", "<C-K>", actions.move_selection_previous)
      map("i", "<C-J>", actions.move_selection_next)
      map("i", "<C-S>", actions.file_split)
      map("i", "<C-V>", actions.file_vsplit)
      map("i", "<C-E>", actions.close)
    end,
  },
  core = {
    bundle = "main",
    root = function() return vim.fn.getcwd() end
  },
  icons = {
    disable_devicons = false,
    separator = " ",
    accessible = " ",
    inaccessible = " ",
    focused = "ﱤ ",
  },
  views_path = function(path)
    return vim.fn.pathshorten(path)
  end,
  log = {
    plugin = "track.nvim",
    level = "error",
  },
}
M._current = vim.deepcopy(M._defaults)

function M.merge(options)
  options = vim.F.if_nil(options, {})
  M._current = vim.tbl_deep_extend("keep", options, M._current)
end

function M.extend(options) return vim.tbl_deep_extend("keep", options, M._current) end

function M.get() return M._current end

return M
