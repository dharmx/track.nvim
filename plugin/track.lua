if vim.version().minor < 8 then
  vim.notify("nvim-colo requires at least nvim-0.8.0.")
  return
end

if vim.g.loaded_track == 1 then return end
vim.g.loaded_track = 1
local cmd = vim.api.nvim_create_user_command

-- TODO: Implement bang, range, repeat, motions and bar.

