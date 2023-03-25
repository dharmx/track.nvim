local M = setmetatable({}, {
  __index = function(_, key) error("Key does not exist for actions: " .. tostring(key)) end,
})

local Config = require("track.config").get()
local util = require("track.util")
local core = require("track.core")
local action_state = require("telescope.actions.state")
local mt = require("telescope.actions.mt")

function M.delete(buffer, bundle_label)
  local current_picker = action_state.get_current_picker(buffer)
  local entries = vim.F.if_nil(current_picker:get_multi_selection(), {})
  current_picker:delete_selection(util.mute)
  if #entries == 0 then table.insert(entries, current_picker:get_selection()) end
  vim.tbl_map(
    function(entry) core.unmark(vim.fn.getcwd(), entry.value, bundle_label, Config.save.on_unmark) end,
    entries
  )
  Config.callbacks.on_delete(buffer)
end

M = mt.transform_mod(M)
return M
