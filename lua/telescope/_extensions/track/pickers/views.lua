local A = vim.api
local V = vim.fn

local Config = require("track.config")
local Core = require("track.core")
local State = require("track.state")
local Util = require("track.util")

local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local config = require("telescope.config")
local state = require("telescope.state")
local actions_state = require("telescope.actions.state")

return function(options)
  options = Config.extend(vim.F.if_nil(options, {}))
  State.load()
  options.hooks.on_views_open()

  local picker = pickers.new(options, {
    prompt_title = "Views",
    finder = finders.new_table({ results = Core.view(V.getcwd()) }),
    sorter = config.values.file_sorter(options),
    attach_mappings = function(buffer, map)
      local current_picker = actions_state.get_current_picker(buffer)
      actions.close:replace(function()
        local window = current_picker.original_win_id
        local valid, cursor = pcall(A.nvim_win_get_cursor, window)
        actions.close_pum(buffer)
        pickers.on_close_prompt(buffer)
        pcall(A.nvim_set_current_win, window)
        if valid and A.nvim_get_mode().mode == "i" and current_picker._original_mode ~= "i" then
          pcall(A.nvim_win_set_cursor, window, { cursor[1], cursor[2] + 1 })
        end
        if options.save.on_views_close then State.save() end
        options.hooks.on_views_close(buffer, current_picker)
      end)
      actions.select_default:replace(function()
        actions.close(buffer)
        options.hooks.on_views_choose(buffer, current_picker)
      end)
      options.mappings.views(buffer, map)
      return true
    end,
  })
  picker:find()
end
