local M = setmetatable({}, {
  __index = function(_, key) error("Key does not exist for actions: " .. tostring(key)) end,
})

-- TODO: Document this BRUH.

local if_nil = vim.F.if_nil
local util = require("track.util")

local mt = require("telescope.actions.mt")
local actions_state = require("telescope.actions.state")

function M.delete_view(buffer)
  local current_picker = actions_state.get_current_picker(buffer)
  local entries = if_nil(current_picker:get_multi_selection(), {})
  current_picker:delete_selection(util.mute)
  if #entries == 0 then table.insert(entries, current_picker:get_selection()) end

  local _, branch = util.root_and_branch()
  if not branch then return end
  for _, entry in ipairs(entries) do
    branch:remove_mark(entry.value)
  end
end

local function picked_view_branch(buffer)
  local current_picker = actions_state.get_current_picker(buffer)
  local entry = current_picker:get_selection()
  local _, branch = util.root_and_branch()
  return { branch = branch, picker = current_picker, entry = entry }
end

local function refresh(name, pack, length)
  length = if_nil(length, 0)
  local picker_util = require("telescope._extensions.track.pickers." .. name)
  pack.picker:register_completion_callback(function(self) self:set_selection(pack.entry.index + length) end)
  pack.picker:refresh(picker_util.finder({}, picker_util.resulter({})), { reset_prompt = true })
end

function M.move_view_previous(buffer)
  local pack = picked_view_branch(buffer)
  pack.branch:swap_marks(pack.entry.index, pack.entry.index - 1)
  refresh("views", pack, -2)
end

function M.move_view_next(buffer)
  local pack = picked_view_branch(buffer)
  pack.branch:swap_marks(pack.entry.index + 1, pack.entry.index)
  refresh("views", pack)
end

function M.change_mark_view(buffer)
  local pack = picked_view_branch(buffer)
  if not (pack and pack.entry and pack.entry.value) then return end
  vim.ui.input({ prompt = "New path: ", completion = "file" }, function(input)
    input = vim.trim(if_nil(input, ""))
    if input == "" then return end

    local _, branch = util.root_and_branch()
    if not branch then return end

    local mark = branch:change_mark_uri(pack.entry.value, input)
    if mark then mark.type = util.filetype(mark:absolute()) end
    refresh("views", pack, -1)
  end)
end

function M.delete_branch(buffer)
  local current_picker = actions_state.get_current_picker(buffer)
  local entries = if_nil(current_picker:get_multi_selection(), {})
  current_picker:delete_selection(util.mute)
  if #entries == 0 then table.insert(entries, current_picker:get_selection()) end

  local root, _ = util.root_and_branch()
  for _, entry in ipairs(entries) do
    if root and root:branch_exists(entry.value.label) then root:delete_branch(entry.value.label) end
  end
end

function M.rename_branch(buffer)
  local current_picker = actions_state.get_current_picker(buffer)
  local entry = current_picker:get_selection()
  local root, branch = util.root_and_branch()
  local pack = { branch = branch, picker = current_picker, entry = entry }

  if not (pack and pack.entry and pack.entry.value) then return end
  vim.ui.input({ prompt = "New name: " }, function(input)
    input = vim.trim(if_nil(input, ""))
    if input == "" then return end
    root:rename_branch(branch, input)
    require("track.core")(require("track.util").cwd())
    refresh("branches", pack, -1)
  end)
end

function M.delete_buffer(buffer)
  local current_picker = actions_state.get_current_picker(buffer)
  local entries = if_nil(current_picker:get_multi_selection(), {})
  current_picker:delete_selection(util.mute)
  if #entries == 0 then table.insert(entries, current_picker:get_selection()) end
end

M = mt.transform_mod(M)
return M
