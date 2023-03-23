---@diagnostic disable: param-type-mismatch
local M = {}
local U = vim.loop

function M.mute()
end

function M.inspect(items)
  vim.notify(vim.inspect(items))
end

function M.cwd()
  return vim.F.if_nil(U.cwd(), vim.env.PWD)
end

return M
