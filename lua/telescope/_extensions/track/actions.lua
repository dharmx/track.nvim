local M = setmetatable({}, {
  __index = function(_, key) error("Key does not exist for actions: " .. tostring(key)) end,
})

local Util = require("track.util")
local State = require("track.state")

local mt = require("telescope.actions.mt")
local actions_state = require("telescope.actions.state")
local actions = require("telescope.actions")

function M.delete_view(buffer)
  local current_picker = actions_state.get_current_picker(buffer)
  local entries = vim.F.if_nil(current_picker:get_multi_selection(), {})
  current_picker:delete_selection(Util.mute)
  if #entries == 0 then table.insert(entries, current_picker:get_selection()) end

  for _, entry in ipairs(entries) do
    local root = State._roots[entry.value.root_path]
    if root then
      local bundle = root.bundles[entry.value.bundle_label]
      bundle:remove_mark(entry.value.path)
    end
  end
end

function M.move_view_previous(buffer)
  local current_picker = actions_state.get_current_picker(buffer)
  local entry = current_picker:get_selection()

  local root = State._roots[entry.value.root_path]
  ---@type Bundle
  local bundle = root.bundles[entry.value.bundle_label]
  bundle:swap_marks(entry.value.index - 1, entry.value.index)

  local views = require("telescope._extensions.track.pickers.views")
  local options = current_picker._current_options.views
  current_picker:refresh(views.finder(options, views.resulter(options)))
end

function M.move_view_next(buffer)
  local current_picker = actions_state.get_current_picker(buffer)
  local entry = current_picker:get_selection()

  local root = State._roots[entry.value.root_path]
  ---@type Bundle
  local bundle = root.bundles[entry.value.bundle_label]
  bundle:swap_marks(entry.value.index + 1, entry.value.index)

  local views = require("telescope._extensions.track.pickers.views")
  local options = current_picker._current_options.views
  current_picker:refresh(views.finder(options, views.resulter(options)))
end

M = mt.transform_mod(M)
return M
