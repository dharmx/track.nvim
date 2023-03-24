local present, telescope = pcall(require, "telescope")

if not present then
  vim.notify("This plugin requires telescope.nvim.")
  return
end

local A = vim.api
local config = require("track.config")

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local state = require("telescope.actions.state")
local values = require("telescope.config").values

-- TODO: Implement copying and pasting (both mutiple and single).
-- TODO: Implement move up and move down (both multiple and single).
-- TODO: Implement highlight_one_row.
-- TODO: Implement row edits.
-- TODO: Implement save_modify.
-- TODO: Implement a previewer for viewing metadata and file contents.
-- TODO: Implement entry_makers.

return telescope.register_extension({
  setup = config.merge,
  exports = {
  },
})
