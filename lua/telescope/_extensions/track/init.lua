local present, telescope = pcall(require, "telescope")

if not present then
  vim.notify("This plugin requires telescope.nvim.")
  return
end

local A = vim.api
local config = require("track.config")
local core = require("track.core")
local state = require("track.state")
local Config = config.get()

local track_actions = require("telescope._extensions.track.actions")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local config_values = require("telescope.config").values

-- TODO: Write a link picker.
-- TODO: Write a stash picker.
-- TODO: Write a way to edit stash, root and mark labels.

-- TODO: Implement copying and pasting (both mutiple and single).
-- TODO: Implement move up and move down (both multiple and single).
-- TODO: Implement highlight_one_row.
-- TODO: Implement row edits.
-- TODO: Implement save_modify.
-- TODO: Implement a previewer for viewing metadata and file contents.
-- TODO: Implement entry_makers.

local function marks(options)
  options = vim.F.if_nil(options, {})
  config.merge(options)
  state.load()
  Config.callbacks.on_open()

  -- TODO: Implement a previewer for viewing metadata and file contents.
  local picker = pickers.new(Config, {
    prompt_title = "Track",
    finder = finders.new_table({
      results = core.view(vim.fn.getcwd(), options.bundle_label),
    }),
    sorter = config_values.file_sorter(Config),
    attach_mappings = function(buffer, map)
      local current_picker = action_state.get_current_picker(buffer)
      -- TODO: Implement copying and pasting (both mutiple and single).
      -- TODO: Implement move up and move down (both multiple and single).
      -- TODO: Implement highlight_one_row.
      -- TODO: Implement row edits.
      -- TODO: Implement save_modify.
      actions.close:replace(function()
        local window = current_picker.original_win_id
        local valid, cursor = pcall(A.nvim_win_get_cursor, window)
        actions.close_pum(buffer)
        pickers.on_close_prompt(buffer)
        pcall(A.nvim_set_current_win, window)
        if valid and A.nvim_get_mode().mode == "i" and current_picker._original_mode ~= "i" then
          pcall(A.nvim_win_set_cursor, window, { cursor[1], cursor[2] + 1 })
        end

        if Config.save.on_close then state.save() end
        Config.callbacks.on_close(buffer, current_picker)
      end)
      actions.select_default:replace(function()
        actions.close(buffer)
        Config.callbacks.on_choose(buffer, current_picker)
      end)

      map("n", "dd", function() track_actions.delete(buffer, options.bundle_label) end)
      map("i", "<C-D>", function() track_actions.delete(buffer, options.bundle_label) end)
      map("i", "<C-K>", actions.move_selection_previous)
      map("i", "<C-J>", actions.move_selection_next)
      map("i", "<C-H>", actions.move_selection_next)
      map("i", "<C-S>", actions.file_split)
      map("i", "<C-V>", actions.file_vsplit)
      map("i", "<C-[>", actions.close)
      return true
    end,
  })
  picker:find()
end

return telescope.register_extension({
  setup = config.merge,
  exports = {
    marks = marks,
  },
})
