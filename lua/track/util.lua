---@diagnostic disable: param-type-mismatch
local M = {}
local U = vim.loop

function M.mute()
end

function M.inspect(items)
  vim.notify(vim.inspect(items))
end

return M
