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

local function picked_bundle(buffer)
  local current_picker = actions_state.get_current_picker(buffer)
  local entry = current_picker:get_selection()
  local root = State._roots[entry.value.root_path]
  return {
    bundle = root.bundles[entry.value.bundle_label],
    picker = current_picker,
    entry = entry,
  }
end

function M.move_view_previous(buffer)
  local pack = picked_bundle(buffer)
  pack.bundle:swap_marks(pack.entry.value.index, pack.entry.value.index - 1)
  local views = require("telescope._extensions.track.pickers.views")
  local options = pack.picker._current_options.views
  pack.picker:register_completion_callback(function(self)
    self:set_selection(pack.entry.value.index - 2)
  end)
  pack.picker:refresh(views.finder(options, views.resulter(options)), { reset_prompt = true })
end

function M.move_view_next(buffer)
  local pack = picked_bundle(buffer)
  pack.bundle:swap_marks(pack.entry.value.index + 1, pack.entry.value.index)
  local views = require("telescope._extensions.track.pickers.views")
  local options = pack.picker._current_options.views
  pack.picker:register_completion_callback(function(self)
    self:set_selection(pack.entry.value.index)
  end)
  pack.picker:refresh(views.finder(options, views.resulter(options)), { reset_prompt = true })
end

M = mt.transform_mod(M)
return M
