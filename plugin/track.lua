if vim.version().minor < 8 then
  vim.notify("nvim-colo requires at least nvim-0.8.0.")
  return
end

if vim.g.loaded_track == 1 then return end
vim.g.loaded_track = 1
local cmd = vim.api.nvim_create_user_command

cmd("Mark", function(...)
  local files = (...).fargs
  if #files == 0 then table.insert(files, vim.fn.expand("%")) end
  for _, file in ipairs(files) do
    require("track.marks").mark(file)
  end
end, {
  desc = "Mark current files(s). This can also takes in a file path.",
  nargs = "*",
  complete = "file",
})

cmd("Unmark", function(...)
  local files = (...).fargs
  if #files == 0 then table.insert(files, vim.fn.expand("%")) end
  for _, file in ipairs(files) do
    require("track.marks").unmark(file)
  end
end, {
  desc = "Mark current files(s). This can also takes in a file path.",
  nargs = "*",
  complete = function()
    return vim.tbl_keys(require("track.marks").marks())
  end,
})
