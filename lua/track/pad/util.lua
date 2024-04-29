local M = {}

local A = vim.api
local U = vim.loop
local V = vim.fn
local if_nil = vim.F.if_nil

function M.new_pad(opts, bundle)
  local buffer = A.nvim_create_buf(false, false)
  A.nvim_buf_set_option(buffer, "number", true)
  A.nvim_buf_set_option(buffer, "filetype", "trackpad")
  A.nvim_buf_set_name(buffer, bundle.label)
  A.nvim_buf_set_option(buffer, "indentexpr", "3")

  local namespace = A.nvim_create_namespace("TrackPad")

  local window = A.nvim_open_win(buffer, true, opts.window)
  A.nvim_win_set_option(window, "winhighlight", "FloatTitle:TrackPadTitle,FloatBorder:NormalFloat")
  A.nvim_win_set_option(window, "number", true)
  A.nvim_win_set_option(window, "cursorline", true)
end

return M
