--@diagnostic disable: need-check-nil, redundant-parameter
local M = {}
local U = vim.loop
local V = vim.fn
local if_nil = vim.F.if_nil

local Path = require("plenary.path")
local config = require("track.config").get()
local util = require("track.util")

M._internal = {}
M._loaded = false

-- TODO: Use assertions and handle possible errors more.

function M.load(on_load)
  local state_path = Path:new(config.state_path)
  if not state_path:exists() then state_path:touch({ parents = true }) end
  local ok, data = pcall(vim.json.decode, state_path:read())
  if ok then M._internal = data end

  local cwd = util.cwd()
  local root = config.roots[cwd]
  if root then
    -- TODO: Use metatables instead i.e. add on __index/__newindex.
    if not M._internal[cwd] then M._internal[cwd] = {} end

    -- NOTE: What more metadata can be added here?
    M._internal[cwd].describe = root.describe
    M._internal[cwd].label = root.label
    M._internal[cwd].marks = if_nil(M._internal[cwd].marks, {})
    root.marks = if_nil(root.marks, {})

    if not vim.tbl_isempty(root.marks) then
      for _, mark in ipairs(root.marks) do
        local mark_type = type(mark)
        if mark_type == "string" then
          M._internal[cwd].marks[mark] = {
            exists = not not U.fs_realpath(mark),
            absolute = V.fnamemodify(mark, ":p"),
            positions = {},
          }
        end
        -- overwrite string with table if duplicate
        if mark_type == "table" then
          mark.path = if_nil(mark[1], mark.path)
          M._internal[cwd].marks[mark.path] = {
            exists = not not U.fs_realpath(mark.path),
            absolute = V.fnamemodify(mark.path, ":p"),
            positions = if_nil(mark.positions, {}),
          }
        end
      end
    end
  end
  M._loaded = true
  if_nil(on_load, config.callbacks.on_load)(M._internal)
end

function M.mark_file(file)
  if not M._loaded then M.load() end
  local cwd = util.cwd()
  if not M._internal[cwd] then
    -- TODO: Use a class instead. Root:new({...})
    M._internal[cwd] = {
      marks = {
        [file] = {
          exists = not not U.fs_realpath(file),
          absolute = V.fnamemodify(file, ":p"),
          positions = {},
        },
      },
    }
  end

  if not M._internal[cwd].marks[file] then
    M._internal[cwd].marks[file] = {
      exists = not not U.fs_realpath(file),
      absolute = V.fnamemodify(file, ":p"),
      positions = {},
    }
  end
  if config.save.on_file_mark then M.save() end
end

function M.unmark_file(file)
  if not M._loaded then M.load() end
  local cwd = util.cwd()
  if not M._internal[cwd] or not M._internal[cwd].marks[file] then return end
  M._internal[cwd].marks[file] = nil
  if config.save.on_file_unmark then M.save() end
end

function M.mark_position(file, position)
  M.mark_file(file)
  position = {
    label = position.label,
    row = if_nil(position.row, position[1]),
    column = if_nil(position.column, position[2]),
  }
  table.insert(M._internal[util.cwd()].marks[file].positions, position)
  if config.save.on_mark_position then M.save() end
end

function M.unmark_position(file, position)
  local cwd = util.cwd()
  if not M._internal[cwd] or not M._internal[cwd].marks[file] then return end
  if vim.tbl_isempty(M._internal[cwd].marks[file].positions) then return end

  local items = M._internal[cwd].marks[file].positions
  for index, item in ipairs(items) do
    if item.row == position.row and item.column == position.column then
      table.remove(M._internal[cwd].marks[file].positions, index)
      return
    end
    if item.row == position[1] and item.column == position[2] then
      table.remove(M._internal[cwd].marks[file].positions, index)
      return
    end
  end
  if config.save.on_mark_position then M.save() end
end

function M.marks()
  if not M._loaded then M.load() end
  return if_nil(if_nil(M._internal[vim.loop.cwd()], {}).marks, {})
end

local function save()
  local state_path = Path:new(config.state_path)
  state_path:write(vim.json.encode(M._internal), "w")
end

function M.save(on_save)
  if not M._loaded then
    vim.ui.input({ prompt = "Save file not loaded. This will erase history. Continue? [Y/N]: " }, function(value)
      value = value:upper()
      if value == "N" or value ~= "Y" then
        vim.notify("Cancelled.")
        return
      end
      vim.notify("Erased.")
    end)
    return
  end
  save()
  if_nil(on_save, config.callbacks.on_save)(M._internal)
end

-- TODO: Implement next_file_mark, previous_file_mark and to_file_mark.
-- TODO: Implement next_position_mark, previous_position_mark and to_position_mark.

return M
