local M = setmetatable({}, {
  __index = function(_, key) error("Key does not exist for actions: " .. tostring(key)) end,
})

local Util = require("track.util")
local State = require("track.state")

local mt = require("telescope.actions.mt")
local actions_state = require("telescope.actions.state")

function M.delete_view(buffer)
  local current_picker = actions_state.get_current_picker(buffer)
  local entries = vim.F.if_nil(current_picker:get_multi_selection(), {})
  current_picker:delete_selection(Util.mute)
  if #entries == 0 then table.insert(entries, current_picker:get_selection()) end
  for _, entry in ipairs(entries) do
    local root = State._roots[entry.value.root_name]
    if root and not root:empty() then
      local bundle = root.bundles[entry.value.bundle_name]
      bundle:remove_mark(entry.value.path)
    end
  end
end

M = mt.transform_mod(M)
return M
