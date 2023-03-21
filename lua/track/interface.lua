---@diagnostic disable: undefined-field
local M = {}

local A = vim.api
local marks = require("track.marks")

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local config = require("telescope.config")
local make_entry = require("telescope.make_entry")

function M.open(options)
  options.entry_maker = make_entry.gen_from_file(options)
  local picker = pickers.new(options, {
    prompt_title = "Track",
    finder = finders.new_table(vim.tbl_keys(marks.marks())),
    sorter = config.values.file_sorter(options),
    attach_mappings = function(_, map)
      map("n", "dd", function()
        marks.unmark(action_state.get_selected_entry().value)
      end)
      actions.close:replace(function(buffer)
        local current = action_state.get_current_picker(buffer)
        local original_win_id = current.original_win_id
        local cursor_valid, original_cursor = pcall(A.nvim_win_get_cursor, original_win_id)
        actions.close_pum(buffer)
        pickers.on_close_prompt(buffer)
        pcall(A.nvim_set_current_win, original_win_id)
        if cursor_valid and A.nvim_get_mode().mode == "i" and current._original_mode ~= "i" then
          pcall(A.nvim_win_set_cursor, original_win_id, { original_cursor[1], original_cursor[2] + 1 })
        end
        marks.save(options)
      end)
      actions.select_default:replace(function(buffer)
        actions.close(buffer)
        vim.cmd.edit(action_state.get_selected_entry().value)
      end)
      return true
    end,
  })
  picker:find()
end

return M
