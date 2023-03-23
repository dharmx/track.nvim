local present, telescope = pcall(require, "telescope")

if not present then
  vim.notify("This plugin requires telescope.nvim.")
  return
end

local A = vim.api
local mark = require("track.mark")
local config = require("track.config")
local current_config = config.get()
local util = require("track.util")

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local state = require("telescope.actions.state")
local values = require("telescope.config").values

local function marks(options)
  config.merge(options)
  if not mark._loaded then mark.load() end
  current_config.callbacks.on_open()

  -- TODO: Implement a previewer for viewing metadata and file contents.
  local picker = pickers.new(current_config, {
    prompt_title = "Track",
    finder = finders.new_table({
      results = vim.tbl_keys(mark.marks()),
      -- TODO: Implement entry_makers.
    }),
    sorter = values.file_sorter(current_config),
    attach_mappings = function(buffer, map)
      local current = state.get_current_picker(buffer)
      -- TODO: Implement copying and pasting (both mutiple and single).
      -- TODO: Implement move up and move down (both multiple and single).
      -- TODO: Implement highlight_one_row.
      -- TODO: Implement row edits.
      -- TODO: Implement save_modify.

      map("n", "dd", function()
        current_config.callbacks.on_delete(buffer, current)
        current:delete_selection(util.mute)
      end)
      map("i", "<C-D>", function()
        current_config.callbacks.on_delete(buffer, current)
        current:delete_selection(util.mute)
      end)

      actions.close:replace(function()
        local window = current.original_win_id
        local valid, cursor = pcall(A.nvim_win_get_cursor, window)
        actions.close_pum(buffer)
        pickers.on_close_prompt(buffer)
        pcall(A.nvim_set_current_win, window)
        if valid and A.nvim_get_mode().mode == "i" and current._original_mode ~= "i" then
          pcall(A.nvim_win_set_cursor, window, { cursor[1], cursor[2] + 1 })
        end
        if current_config.save.on_close then mark.save() end
        current_config.callbacks.on_close(buffer, current)
      end)

      actions.select_default:replace(function()
        actions.close(buffer)
        current_config.callbacks.on_choose(buffer, current)
      end)
      return true
    end,
  })
  picker:find()
end

return telescope.register_extension({
  setup = config.merge,
  exports = {
    marks = marks
  },
})
