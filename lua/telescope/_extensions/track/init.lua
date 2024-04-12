local present, telescope = pcall(require, "telescope")
if not present then
  vim.notify("This plugin requires telescope.nvim.")
  return
end

-- TODO: Implement the links picker.
-- TODO: Add ability to delete entries from bundles, views, links and marks pickers.
-- TODO: Implement copying and pasting (both mutiple and single).
-- TODO: Implement move up and move down (both multiple and single).
-- TODO: Implement row edits.
-- TODO: Implement save_modify.
-- TODO: Implement a previewer for viewing metadata and file contents.

return telescope.register_extension({
  setup = function(opts)
    require("track.config").merge_pickers(opts)
    require("track.log").info("Telescope.Init.setup(): telescope extension has been configured")
  end,
  exports = {
    views = require("telescope._extensions.track.pickers.views").picker,
    bundles = require("telescope._extensions.track.pickers.bundles").picker,
  },
})
