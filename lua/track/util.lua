---@diagnostic disable: param-type-mismatch
local M = {}
local A = vim.api

function M.mute() end

function M.inspect(items) vim.notify(vim.inspect(items)) end

function M.warn(message)
  A.nvim_notify(message, vim.log.levels.WARN, {
    icon = " ",
    title = "track.nvim",
    prompt_title = "track.nvim",
  })
end

function M.swap(items, index1, index2)
  local temp = items[index1]
  items[index1] = items[index2]
  items[index2] = temp
  return items
end

function M.filter_path(path)
  local length = path:len()
  path = path:gsub("//", "/")
  if path == "/" then return path end
  if path:sub(length, length) == "/" then return path:sub(1, length - 1) end
  return path
end

return M
