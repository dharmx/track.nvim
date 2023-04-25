local M = {}

local A = vim.api
local Config = require("track.config")
local Save = Config.get_save_config()
local Log = require("track.log")

local State = require("track.state")
local EntryMakers = require("telescope._extensions.track.entry_makers")

local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local config = require("telescope.config")
local actions_state = require("telescope.actions.state")

function M.resulter(views_options)
  local results = {}
  local root_path = views_options.track_options.root_path()
  local root = State._roots[root_path]
  local bundle_label = views_options.track_options.bundle_label(root)

  if root then
    local bundle = root.bundles[bundle_label]
    if bundle and not bundle:empty() then
      local views = bundle.views()

      for index, view in ipairs(views) do
        local _view = vim.deepcopy(view)
        _view.index = index -- needed for dynamic keymaps 
        _view.root_path = root_path
        _view.bundle_label = bundle_label
        table.insert(results, index, _view)
      end
    end
  end
  return results
end

-- this can be passed into picker:refresh(<finder>)
function M.finder(views_options, results)
  return finders.new_table({
    results = results,
    entry_maker = EntryMakers.gen_from_views(views_options)
  })
end

function M.picker(options)
  options = vim.F.if_nil(options, {})
  options = Config.extend_pickers(options)

  local views_options = options.views
  options.cwd = vim.F.if_nil(options.cwd, views_options.track_options.root_path())
  local views_hooks = views_options.hooks
  State.load()

  -- this will be used in attach_mappings
  local results = M.resulter(views_options)
  views_hooks.on_open()
  local picker = pickers.new(views_options, {
    prompt_title = "Views",
    finder = M.finder(views_options, results),
    sorter = config.values.file_sorter(views_options),
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
        if Save.on_views_close then
          State.save()
          Log.info("Telescope.Views.picker(): closed telescope.track.views and saved state")
        end
        views_hooks.on_close(buffer, current_picker)
      end)
      actions.select_default:replace(function()
        actions.close(buffer)
        views_hooks.on_choose(buffer, current_picker)
      end)

      -- dynamic keymaps
      for _, mark in ipairs(results) do views_hooks.on_each_view(buffer, map, mark) end
      return true
    end,
  })
  picker:find()
end

return M
