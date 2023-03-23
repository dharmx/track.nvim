if vim.version().minor < 8 then
  vim.notify("nvim-colo requires at least nvim-0.8.0.")
  return
end

if vim.g.loaded_track == 1 then return end
vim.g.loaded_track = 1
local cmd = vim.api.nvim_create_user_command

-- TODO: Implement bang, range, repeat, motions and bar.

cmd("Track", function(...)
  local option = (...).args
  local mark = require("track.mark")

  if option == "save" then
    mark.save(function() vim.notify("Saved.") end)
  elseif option == "reload" then
    mark.load(function() vim.notify("Reloaded.") end)
  else require("telescope").extensions.track.marks() end
end, {
  desc = "Main controls.",
  nargs = "?",
  complete = function()
    return { "save", "reload", "marks" }
  end
})

cmd("MarkFile", function(...)
  local files = (...).fargs
  local mark = require("track.mark")

  if #files == 0 then table.insert(files, vim.fn.expand("%")) end
  for _, file in ipairs(files) do
    mark.mark_file(file)
  end
end, {
  desc = "Mark current files(s). This can also takes in a file path.",
  nargs = "*",
  complete = "file",
})

cmd("UnmarkFile", function(...)
  local files = (...).fargs
  local mark = require("track.mark")

  if #files == 0 then table.insert(files, vim.fn.expand("%")) end
  for _, file in ipairs(files) do
    mark.unmark_file(file)
  end
end, {
  desc = "Unmark current files(s). This can also takes in a file path.",
  nargs = "*",
  complete = function()
    return vim.tbl_keys(require("track.mark").marks())
  end,
})

cmd("MarkPosition", function(...)
  local args = (...).fargs
  local mark = require("track.mark")

  local file = vim.fn.expand("%")
  if vim.tbl_isempty(args) then
    mark.mark_position(file, vim.api.nvim_win_get_cursor(0))
  else
    assert(#args % 2 == 0)
    for index = 1, #args, 2 do
      mark.mark_position(file, {
        tonumber(args[index]), -- row
        tonumber(args[index + 1]), -- column
      })
    end
  end
end, {
  nargs = "*",
  complete = "file",
})

cmd("UnmarkPosition", function(...)
  local args = (...).fargs
  local mark = require("track.mark")
  local file = vim.fn.expand("%")

  if vim.tbl_isempty(args) then
    mark.unmark_position(file, vim.api.nvim_win_get_cursor(0))
  else
    assert(#args % 2 == 0)
    for index = 1, #args, 2 do
      mark.unmark_position(file, {
        tonumber(args[index]), -- row
        tonumber(args[index + 1]), -- column
      })
    end
  end
end, {
  nargs = "*",
})
