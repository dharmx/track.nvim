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
      vim.cmd("confirm edit " .. entry)
    end
  else
    vim.cmd("confirm edit " .. entry)
  end
end

---@return string
function M.filetype(uri)
  local uri_type = vim.F.if_nil(string.match(uri, "^(%w+):/"), "file")
  if uri_type == "file" then
    local stat, _, e = vim.loop.fs_stat(uri)
    if e == "EACCES" then
      return "no_access"
    elseif e == "ENOENT" then
      return "no_exists"
    else
      return stat and stat.type or "error"
    end
  end
  return vim.trim(uri_type) == "" and "default" or uri_type
end

---Get cwd. Like really.
---@return string
function M.cwd()
  return (vim.loop.cwd()) or vim.fn.getcwd() or vim.env.PWD
end

return M
