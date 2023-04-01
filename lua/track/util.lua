---@diagnostic disable: param-type-mismatch
local M = {}

function M.mute() end

function M.inspect(items) vim.notify(vim.inspect(items)) end

function M.swap(items, index1, index2)
  local temp = items[index1]
  items[index1] = items[index2]
  items[index2] = temp
  return items
end

function M.serial_keymap(index)
  local digits = vim.split(tostring(index), "", { plain = true })
  local map_keys_normal = vim.tbl_map(function(digit) return string.format("%s", digit) end, digits)
  local map_keys_insert = vim.tbl_map(function(digit) return string.format("<M-%s>", digit) end, digits)

  return {
    normal = table.concat(map_keys_normal),
    insert = table.concat(map_keys_insert),
  }
end

function M.open_file(file)
   vim.cmd("confirm edit " .. file)
end

function M.filter_path(path)
  local length = path:len()
  path = path:gsub("//", "/")
  if path == "/" then return path end
  if path:sub(length, length) == "/" then return path:sub(1, length - 1) end
  return path
end

return M
