local present, telescope = pcall(require, "telescope")
if not present then
  vim.notify("This plugin requires telescope.nvim.")
  return
end

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
