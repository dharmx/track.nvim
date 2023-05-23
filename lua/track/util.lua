---@diagnostic disable: param-type-mismatch
local M = {}

---Dummy function that does noting.
function M.mute() end

---@param items any
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

function M.open_entry(entry)
  if vim.startswith(entry, "man:/") then
    local replaced = entry:gsub("man:/", "")
    if not replaced then
      vim.notify("Could not open manpage for `" .. entry .. "`.")
    else
      vim.cmd.Man(replaced)
    end
  elseif vim.startswith(entry, "term:/") then
    local replaced = entry:gsub("term:/", "")
    if not replaced then
      vim.notify("Could not open terminal for `" .. entry .. "`.")
    else
      vim.cmd.terminal(vim.split(entry, "[;:]")[3])
    end
  else
    vim.cmd("confirm edit " .. entry)
  end
end

function M.filter_path(path)
  local length = path:len()
  path = path:gsub("//", "/")
  if path == "/" then return path end
  if path:sub(length, length) == "/" then return path:sub(1, length - 1) end
  return path
end

return M
