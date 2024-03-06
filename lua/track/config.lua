local M = {}

-- WARN: Do not import track.config in track.util.
local Util = require("track.util")

-- TODO: Implement validation (vim.validate) and config fallback.
-- TODO: Defaults (M.defaults) will be used if config values are invalid.
-- TODO: Implement a way to show hidden files.
-- TODO: Implement exclude filetypes.
-- TODO: Implement exclude buffer names.
-- TODO: Asyncify saving.

-- Configuration documentation. {{{

---@class TrackSaveConfig
---@field on_views_close boolean Save state when the views telescope buffer is closed.

---@class TrackPickersViewsHooksConfig
---@field on_open function This will be called before the picker window is opened.
---@field on_close function(buffer: number, picker: Picker) This will be called right after the picker window is closed.
---@field on_choose function(buffer: number, picker: Picker) Will be called after the choice is made and the picker os closed.

---@class TrackPickersViewsTrackOptionsConfig
---@field bundle_label function(root: Root): string Function that must return the root path.
---@field root_path function: string Function that must return the path to the current working directory.

---@class TrackPickersViewsIconsConfig
---@field separator string Separator between columns in the views picker.
---@field missing string Indicator icon for representing a missing/deleted file.
---@field accessible string Indicator icon for representing a file that allows reading.
---@field inaccessible string Indicator icon for representing a file that does not allow reading from it.
---@field focused string Indicator icon for representing a file that is currently being edited on.
---@field listed string Indicator icon for representing if a file is already open.
---@field unlisted string Indicator icon for representing if a file is not open.
---@field file string Default file icon. This will be visible when `disable_devicons` is `true`.

---Other config options that are not documented here can be found at |telecope.nvim| help page.
---@class TrackPickersViewsConfig
---@field hooks TrackPickersViewsHooksConfig Callbacks related to the views picker.
---@field track_options TrackPickersViewsTrackOptionsConfig Defaults like `bundle_label` and `root_path` for calling the view list.
---@field icons TrackPickersViewsIconsConfig File-indicators, state-indicators, separators and default icons.

---@class TrackPickersConfig
---@field views TrackPickersViewsConfig Configuration options relating to the `views` telescope picker.

---@class TrackLogConfig
---@field level "error"|"warn"|"info"|"trace"|"debug"|"off" Log level. The higher the level is, lesser the STDOUT messages will be shown.
---@field plugin string Name of the plugin.

---@class TrackBookmarksConfig
---@field sign string
---@field choice boolean

---@class TrackConfig
---@field savepath string JSON file where the current state will be saved.
---@field disable_history boolean Change state of all bundle histories.
---@field maximum_history number Change the maximum number of marks to be stored in all bundle history tables.
---@field save TrackSaveConfig Sub-configuration for when current state will be saved.
---@field bookmarks TrackBookmarksConfig Sub-configuration for bookmarks.
---@field pickers TrackPickersConfig Sub-configuration for telescope pickers.
---@field log TrackLogConfig Sub-configuration for logging and debugging.

-- }}}

---Default **track.nvim** options.
---@type TrackConfig
M._defaults = {
  savepath = vim.fn.stdpath("state") .. "/track.json",
  disable_history = true,
  maximum_history = 10,
  save = {
    on_views_close = true, -- save when the view telescope picker is closed
  },
  bookmarks = {
    sign = "",
    choice = false,
  },
  pickers = {
    views = {
      path_display = {
        absolute = false, -- /home/name/projects/hello/mark.lua -> hello/mark.lua
        shorten = 1, -- /aname/bname/cname/dname.e -> /a/b/c/dname.e
      },
      prompt_prefix = " 粒 ",
      previewer = false,
      initial_mode = "insert", -- alternatively: "normal"
      layout_config = {
        preview_cutoff = 1,
        width = function(_, maximum_columns, _) return math.min(maximum_columns, 70) end,
        height = function(_, _, maximum_lines) return math.min(maximum_lines, 15) end,
      },
      hooks = {
        on_close = Util.mute,
        on_open = Util.mute,
        on_choose = function(_, picker)
          local entries = vim.F.if_nil(picker:get_multi_selection(), {})
          if #entries == 0 then table.insert(entries, picker:get_selection()) end
          vim.tbl_map(function(entry) Util.open_entry(entry.value.path) end, entries)
        end,
      },
      attach_mappings = function(_, map)
        local actions = require("telescope.actions")
        map("n", "q", actions.close)
        map("n", "v", actions.select_all)

        local Actions = require("telescope._extensions.track.actions")
        map("n", "D", actions.select_all + Actions.delete_view)
        map("n", "dd", Actions.delete_view)
        map("i", "<C-D>", Actions.delete_view)
        map("i", "<C-N>", Actions.move_view_next)
        map("i", "<C-P>", Actions.move_view_previous)
        return true -- compulsory
      end,
      track_options = {
        bundle_label = function(root)
          if root then return root.main end
          return "main"
        end,
        root_path = vim.fn.getcwd,
      },
      disable_devicons = false,
      icons = {
        separator = " ",
        terminal = " ",
        manual = " ",
        missing = " ",
        accessible = " ",
        inaccessible = " ",
        focused = " ",
        listed = "",
        unlisted = "≖",
        file = "",
      },
    },
  },
  log = {
    plugin = "track",
    level = "warn",
  },
}

---Current **track.nvim** options. This will be initially the same as `defaults`.
---@type TrackConfig
M._current = vim.deepcopy(M._defaults)

---Merge `options` with current track options (`M._current`).
---@param options TrackConfig
function M.merge(options)
  ---@type TrackConfig
  options = vim.F.if_nil(options, {})
  M._current = vim.tbl_deep_extend("keep", options, M._current)
end

---Merge `picker_options` with current track picker options (`M._current.pickers`).
---@param picker_options TrackPickersConfig
function M.merge_pickers(picker_options)
  ---@type TrackPickersConfig
  picker_options = vim.F.if_nil(picker_options, {})
  M._current.pickers = vim.tbl_deep_extend("keep", picker_options, M._current.pickers)
end

---Merge `options` with current track options and return it. This will not write to `M._current`.
---@param options TrackConfig
---@return TrackConfig
function M.extend(options) return vim.tbl_deep_extend("keep", options, M._current) end

---Merge `picker_options` with current track picker options and return it. This will not write to `M._current.pickers`.
---@param picker_options TrackPickersConfig
---@return TrackPickersConfig
function M.extend_pickers(picker_options) return vim.tbl_deep_extend("keep", picker_options, M._current.pickers) end

---Return current track config.
---@return TrackConfig
function M.get() return M._current end

---Return current track pickers config.
---@return TrackPickersConfig
function M.get_pickers() return M._current.pickers end

---Return current track save config.
---@return TrackSaveConfig
function M.get_save_config() return M._current.save end

return M
