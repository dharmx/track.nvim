local A = vim.api
local Config = require("track.config")
local State = require("track.state")
local Entry = require("telescope._extensions.track.entry")

local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local config = require("telescope.config")
local actions_state = require("telescope.actions.state")

return function(options)
  options = Config.extend(vim.F.if_nil(options, {}))
  local views_options = options.pickers.views
  local views_hooks = views_options.hooks

  State.load()
  views_hooks.on_open()

  local results = {}
  local directory = views_options.track_options.root()
  local bundle = views_options.track_options.bundle
  local roots_copy = vim.deepcopy(State._roots)

  if roots_copy[directory] and roots_copy[directory].bundles[bundle] then
    local marks = roots_copy[directory].bundles[bundle].marks()
    local count = 1
    results = vim.tbl_map(function(mark)
      mark.index = count
      mark.root_name = directory
      mark.bundle_name = bundle
      count = count + 1
      return mark
    end, marks)
  end

  local picker = pickers.new(views_options, {
    prompt_title = "Views",
    finder = finders.new_table({ results = results, entry_maker = Entry.views(views_options) }),
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
        if options.save.on_views_close then State.save() end
        views_hooks.on_close(buffer, current_picker)
      end)

      actions.select_default:replace(function()
        actions.close(buffer)
        views_hooks.on_choose(buffer, current_picker)
      end)

      views_options.mappings(buffer, map, options)
      for _, mark in ipairs(results) do
        views_hooks.on_each_view(buffer, map, mark)
      end
      return true
    end,
  })
  picker:find()
end
