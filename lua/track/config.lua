local M = {}

-- WARN: Do not import track.config in track.util.
local Util = require("track.util")

-- TODO: Implement validation (vim.validate) and config fallback.
-- TODO: Defaults (M.defaults) will be used if config values are invalid.
-- TODO: Implement a way to show hidden files.
-- TODO: Implement exclude filetypes.
-- TODO: Implement exclude buffer names.

---Default **track.nvim** opts.
---@type TrackOpts
M._defaults = {
  save_path = vim.fn.stdpath("state") .. "/track.json",
  disable_history = true,
  maximum_history = 10,
  pad = {
    serial_maps = true,
    save_on_close = true,
    hooks = {
      on_choose = Util.open_entry,
      on_serial_choose = Util.open_entry,
    },
    window = {
      style = "minimal",
      border = "solid",
      focusable = true,
      relative = "editor",
      width = 60,
      height = 10,
      title_pos = "center",
    },
  },
  pickers = {
    bundles = {
      save_on_close = true,
      bundle_label = nil,
      root_path = nil,
      prompt_prefix = "   ",
      selection_caret = "   ",
      previewer = false,
      initial_mode = "insert", -- alternatively: "normal"
      layout_config = {
        preview_cutoff = 1,
        width = function(_, max_col, _) return math.min(max_col, 70) end,
        height = function(_, _, max_line) return math.min(max_line, 15) end,
      },
      hooks = {
        on_close = Util.mute,
        on_open = Util.mute,
        on_choose = function(status, opts)
          local selected = status.picker:get_selection()
          if not selected then return end
          require("track.state")._roots[opts.root_path]:change_main_bundle(selected.value.label)
        end,
      },
      attach_mappings = function(_, map)
        local actions = require("telescope.actions")
        map("n", "q", actions.close)
        map("n", "v", actions.select_all)

        local Actions = require("telescope._extensions.track.actions")
        map("n", "D", actions.select_all + Actions.delete_bundle)
        map("n", "dd", Actions.delete_bundle)
        map("i", "<C-D>", Actions.delete_bundle)
        map("i", "<C-E>", Actions.change_bundle_label)
        return true -- compulsory
      end,
      icons = {
        separator = " ┃ ",
        main = " ",
        alternate = " ",
        inactive = " ",
        mark = "",
        history = "",
      }
    },
    views = {
      on_bundles_close = true, -- save when the view telescope picker is closed
      bundle_label = nil,
      root_path = nil,
      selection_caret = "   ",
      path_display = {
        absolute = false, -- /home/name/projects/hello/mark.lua -> hello/mark.lua
        shorten = 1, -- /aname/bname/cname/dname.e -> /a/b/c/dname.e
      },
      prompt_prefix = "   ",
      previewer = false,
      initial_mode = "insert", -- alternatively: "normal"
      layout_config = {
        preview_cutoff = 1,
        width = function(_, max_col, _) return math.min(max_col, 70) end,
        height = function(_, _, max_line) return math.min(max_line, 15) end,
      },
      hooks = {
        on_close = Util.mute,
        on_open = Util.mute,
        on_choose = function(status, _)
          local entries = vim.F.if_nil(status.picker:get_multi_selection(), {})
          if #entries == 0 then table.insert(entries, status.picker:get_selection()) end
          for _, entry in ipairs(entries) do Util.open_entry(entry.value.path) end
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
        map("i", "<C-E>", Actions.change_mark_view)
        return true -- compulsory
      end,
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
        directory = "",
      },
    },
  },
  log = {
    plugin = "track",
    level = "warn",
  },
}

---Current **track.nvim** opts. This will be initially the same as `defaults`.
---@type TrackOpts
M._current = vim.deepcopy(M._defaults)

---Merge `opts` with current track opts (`M._current`).
---@param opts TrackOpts
function M.merge(opts)
  ---@type TrackOpts
  opts = vim.F.if_nil(opts, {})
  M._current = vim.tbl_deep_extend("keep", opts, M._current)
end

---Merge `opts` with current track picker opts (`M._current.pickers`).
---@param opts TrackPickers
function M.merge_pickers(opts)
  ---@type TrackPickers
  opts = vim.F.if_nil(opts, {})
  M._current.pickers = vim.tbl_deep_extend("keep", opts, M._current.pickers)
end

---@param opts TrackPad
function M.merge_pad(opts)
  ---@type TrackPad
  opts = vim.F.if_nil(opts, {})
  M._current.pad = vim.tbl_deep_extend("keep", opts, M._current.pad)
end

---Merge `opts` with current track opts and return it. This will not write to `M._current`.
---@param opts TrackOpts
---@return TrackOpts
function M.extend(opts) return vim.tbl_deep_extend("keep", opts, M._current) end

---Merge `opts` with current track picker opts and return it. This will not write to `M._current.pickers`.
---@param opts TrackPickers
---@return TrackPickers
function M.extend_pickers(opts) return vim.tbl_deep_extend("keep", opts, M._current.pickers) end

---@param opts TrackPad
---@return TrackPad
function M.extend_pad(opts) return vim.tbl_deep_extend("keep", opts, M._current.pad) end

---Return current track config.
---@return TrackOpts
function M.get() return M._current end

---Return current track pickers config.
---@return TrackPickers
function M.get_pickers() return M._current.pickers end

---Return current track save config.
---@return TrackSave
function M.get_save_config() return M._current.save end

---@return TrackPad
function M.get_pad() return M._current.pad end

return M
