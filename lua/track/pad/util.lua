local M = {}

local A = vim.api
local U = vim.loop
local V = vim.fn
local if_nil = vim.F.if_nil

function M.setup_pad(opts, bundle)
  local buffer = A.nvim_create_buf(false, false)
  local namespace = A.nvim_create_namespace()
end

return M
