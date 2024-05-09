local present, telescope = pcall(require, "telescope")
if not present then
  vim.notify("This plugin requires telescope.nvim.")
  return
end

-- TODO: Implement copy and paste (mutiple & single). Copy/Paste JSON version of the containers.
-- TODO: Implement a previewer for viewing metadata and file contents.

return telescope.register_extension({
  setup = function(opts)
    require("track.config").merge_pickers(opts)
    require("track.log").info("Telescope.Init.setup(): telescope extension has been configured")
  end,
  exports = {
    views = require("telescope._extensions.track.pickers.views").picker,
    branches = require("telescope._extensions.track.pickers.branches").picker,
  },
})
