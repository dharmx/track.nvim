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

  local root = State._roots[current_picker._current_opts.track.root_path]
  for _, entry in ipairs(entries) do
    if root then
      local bundle = root.bundles[entry.value.bundle_label]
      bundle:remove_mark(entry.value.path)
    end
  end
end

local function picked_view_bundle(buffer)
  local current_picker = actions_state.get_current_picker(buffer)
  local entry = current_picker:get_selection()
  local root = State._roots[entry.value.root_path]
  return {
    bundle = root.bundles[entry.value.bundle_label],
    picker = current_picker,
    entry = entry,
  }
end

local function refresh(name, pack, length)
  length = vim.F.if_nil(length, 0)
  local picker_util = require("telescope._extensions.track.pickers." .. name)
  local opts = pack.picker._current_opts
  pack.picker:register_completion_callback(function(self) self:set_selection(pack.entry.value.index + length) end)
  pack.picker:refresh(picker_util.finder(opts, picker_util.resulter(opts)), { reset_prompt = true })
end

function M.move_view_previous(buffer)
  local pack = picked_view_bundle(buffer)
  pack.bundle:swap_marks(pack.entry.value.index, pack.entry.value.index - 1)
  refresh("views", pack, -2)
end

function M.move_view_next(buffer)
  local pack = picked_view_bundle(buffer)
  pack.bundle:swap_marks(pack.entry.value.index + 1, pack.entry.value.index)
  refresh("views", pack)
end

function M.change_mark_view(buffer)
  local pack = picked_view_bundle(buffer)
  if not (pack and pack.entry and pack.entry.value) then return end
  vim.ui.input({ prompt = "New path: ", completion = "file" }, function(input)
    input = vim.trim(vim.F.if_nil(input, ""))
    if input == "" then return end

    local root = State._roots[pack.picker._current_opts.track.root_path]
    local bundle = root.bundles[pack.entry.value.bundle_label]
    local mark = bundle:change_mark_path(pack.entry.value, input)
    if mark then mark.type = Util.filetype(mark.absolute) end
    refresh("views", pack, -1)
  end)
end

function M.delete_bundle(buffer)
  local current_picker = actions_state.get_current_picker(buffer)
  local entries = vim.F.if_nil(current_picker:get_multi_selection(), {})
  current_picker:delete_selection(Util.mute)
  if #entries == 0 then table.insert(entries, current_picker:get_selection()) end

  local root = State._roots[current_picker._current_opts.track.root_path]
  for _, entry in ipairs(entries) do
    if root and root:bundle_exists(entry.value.label) then
      root:delete_bundle(entry.value.label)
    end
  end
end

function M.change_bundle_label(buffer)
  local current_picker = actions_state.get_current_picker(buffer)
  local entry = current_picker:get_selection()
  local root = State._roots[current_picker._current_opts.track.root_path]
  local pack = {
    bundle = root.bundles[entry.value.label],
    picker = current_picker,
    entry = entry,
  }

  if not (pack and pack.entry and pack.entry.value) then return end
  vim.ui.input({ prompt = "New name: " }, function(input)
    input = vim.trim(vim.F.if_nil(input, ""))
    if input == "" then return end
    local bundle = root.bundles[pack.entry.value.label]
    root:rename_bundle(bundle, input)
    refresh("bundles", pack, -1)
  end)
end


M = mt.transform_mod(M)
return M
