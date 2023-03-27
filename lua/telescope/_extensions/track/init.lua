local present, telescope = pcall(require, "telescope")

if not present then
  vim.notify("This plugin requires telescope.nvim.")
  return
end

-- TODO: Implement the links picker.
-- TODO: Add ability to delete entries from bundles, views, links and marks pickers.
-- TODO: Implement a way to edit bundle, root and mark labels.
-- TODO: Implement copying and pasting (both mutiple and single).
-- TODO: Implement move up and move down (both multiple and single).
-- TODO: Implement highlight_one_row.
-- TODO: Implement row edits.
-- TODO: Implement save_modify.
-- TODO: Implement a previewer for viewing metadata and file contents.
-- TODO: Implement entry_makers.

return telescope.register_extension({
  setup = require("track.config").merge,
  exports = {
    track = require("telescope._extensions.track.pickers.track"),
    views = require("telescope._extensions.track.pickers.views"),
    marks = require("telescope._extensions.track.pickers.marks"),
    roots = require("telescope._extensions.track.pickers.roots"),
    bundles = require("telescope._extensions.track.pickers.bundles"),
  },
})
