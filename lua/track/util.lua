---@diagnostic disable: param-type-mismatch
local M = {}

---Dummy function that does noting.
function M.mute() end

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
