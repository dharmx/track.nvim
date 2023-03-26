local A = vim.api
local V = vim.fn

local config = require("track.config")
local state = require("track.state")

local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local action_state = require("telescope.actions.state")
local values = require("telescope.config").values

return function(options)
  options = config.extend(vim.F.if_nil(options, {}))
  state.load()
  options.hooks.on_bundles_open()
  local root = state._roots[V.getcwd()]
  local results = {}
  if root then results = root.bundles("string") end

  local picker = pickers.new(options, {
    prompt_title = "Bundles",
    finder = finders.new_table({ results = results }),
    sorter = values.generic_sorter(options),
    attach_mappings = function(buffer, map)
      local current_picker = action_state.get_current_picker(buffer)
      actions.close:replace(function()
        local window = current_picker.original_win_id
        local valid, cursor = pcall(A.nvim_win_get_cursor, window)
        actions.close_pum(buffer)
        pickers.on_close_prompt(buffer)
        pcall(A.nvim_set_current_win, window)
        if valid and A.nvim_get_mode().mode == "i" and current_picker._original_mode ~= "i" then
          pcall(A.nvim_win_set_cursor, window, { cursor[1], cursor[2] + 1 })
        end
        if options.save.on_bundles_close then state.save() end
        options.hooks.on_bundles_close(buffer, current_picker)
      end)
      actions.select_default:replace(function()
        actions.close(buffer)
        options.hooks.on_bundles_choose(buffer, current_picker)
      end)
      options.mappings.bundles(buffer, map)
      return true
    end,
  })
  picker:find()
end
