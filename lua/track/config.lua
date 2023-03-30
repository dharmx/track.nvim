local M = {}

-- WARN: Do not import track.config in track.util.
local Util = require("track.util")

-- TODO: Implement validation (vim.validate) and config fallback.
-- TODO: Defaults (M.defaults) will be used if config values are invalid.
-- TODO: Implement a way to show hidden files.
-- TODO: Asyncify saving.
-- TODO: Add view = "metadata"|"contents"

M._defaults = {
  savepath = "/tmp/track.json",
  save = {
    on_views_close = true,
    on_marks_close = false,
    on_bundles_close = false,
    on_roots_close = false,
    on_track_close = false,
  },
  pickers = {
    views = {
      path_display = { "shorten" },
      prompt_prefix = " 粒 ",
      previewer = false,
      initial_mode = "insert",
      layout_config = {
        preview_cutoff = 1,
        width = function(_, max_columns, _) return math.min(max_columns, 70) end,
        height = function(_, _, max_lines) return math.min(max_lines, 15) end,
      },
      hooks = {
        on_close = Util.mute,
        on_open = Util.mute,
        on_each_view = function(buffer, map, mark)
          local keys = Util.serial_keymap(mark.index)
          local function command()
            require("telescope.actions").close(buffer)
            Util.open_file(mark.path)
          end
          map("n", keys.normal, command)
          map("i", keys.insert, command)
        end,
        on_choose = function(_, picker)
          local entries = vim.F.if_nil(picker:get_multi_selection(), {})
          if #entries == 0 then table.insert(entries, picker:get_selection()) end
          vim.tbl_map(function(entry) Util.open_file(entry.value.path) end, entries)
        end,
      },
      attach_mappings = function(_, map)
        local actions = require("telescope.actions")
        map("i", "<C-K>", actions.move_selection_previous)
        map("i", "<C-J>", actions.move_selection_next)
        map("n", "q", actions.close)
        map("n", "v", actions.select_all)

        local Actions = require("telescope._extensions.track.actions")
        map("n", "dd", Actions.delete_view)
        map("i", "<C-D>", Actions.delete_view)
        map("n", "D", actions.select_all + Actions.delete_view)
        return true
      end,
      track_options = {
        bundle_label = function(root)
          if root and not root:empty() then
            return root.main
          end
          return "main"
        end,
        root_path = vim.fn.getcwd,
      },
      disable_devicons = false,
      icons = {
        separator = " ",
        accessible = " ",
        inaccessible = " ",
        focused = " ",
        listed = "",
        unlisted = "≖",
        file = "",
      },
    },
    marks = {
      prompt_prefix = " 粒 ",
      previewer = false,
      initial_mode = "insert",
      layout_config = {
        preview_cutoff = 1,
        width = function(_, max_columns, _) return math.min(max_columns, 50) end,
        height = function(_, _, max_lines) return math.min(max_lines, 15) end,
      },
      hooks = {
        on_close = Util.mute,
        on_open = Util.mute,
        on_choose = Util.mute,
      },
      mappings = function(_, map)
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
      disable_devicons = false,
    },
    bundles = {
      prompt_prefix = " 粒 ",
      previewer = false,
      initial_mode = "insert",
      layout_config = {
        preview_cutoff = 1,
        width = function(_, max_columns, _) return math.min(max_columns, 50) end,
        height = function(_, _, max_lines) return math.min(max_lines, 15) end,
      },
      hooks = {
        on_close = Util.mute,
        on_open = Util.mute,
        on_choose = Util.mute,
      },
      mappings = function(_, map)
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
      disable_devicons = false,
    },
    roots = {
      prompt_prefix = " 粒 ",
      previewer = false,
      initial_mode = "insert",
      layout_config = {
        preview_cutoff = 1,
        width = function(_, max_columns, _) return math.min(max_columns, 50) end,
        height = function(_, _, max_lines) return math.min(max_lines, 15) end,
      },
      hooks = {
        on_close = Util.mute,
        on_open = Util.mute,
        on_choose = Util.mute,
      },
      mappings = function(_, map)
        local actions = require("telescope.actions")
        map("i", "<C-K>", actions.move_selection_previous)
        map("i", "<C-J>", actions.move_selection_next)
        map("i", "<C-E>", actions.close)
      end,
      disable_devicons = false,
    },
    track = {
      prompt_prefix = " 粒 ",
      previewer = false,
      initial_mode = "insert",
      layout_config = {
        preview_cutoff = 1,
        width = function(_, max_columns, _) return math.min(max_columns, 50) end,
        height = function(_, _, max_lines) return math.min(max_lines, 15) end,
      },
      hooks = {
        on_close = Util.mute,
        on_open = Util.mute,
        on_choose = function(_, picker)
          local entry = picker:get_selection()
          require("telescope").extensions.track[entry.value:lower()]()
        end,
      },
      mappings = function(_, map)
        local actions = require("telescope.actions")
        map("i", "<C-K>", actions.move_selection_previous)
        map("i", "<C-J>", actions.move_selection_next)
        map("i", "<C-E>", actions.close)
      end,
      disable_devicons = false,
    },
  },
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
