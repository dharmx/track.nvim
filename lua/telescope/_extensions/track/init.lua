local present, telescope = pcall(require, "telescope")

if not present then
  vim.notify("This plugin requires telescope.nvim.")
  return
end

local interface = require("track.interface")
local mark = require("track.mark")
local config = require("track.config")

return telescope.register_extension({
  setup = config.merge,
  exports = {
    marks = function(options)
      config.merge(options)
      if not mark._loaded then mark.load() end
      interface.view()
    end,
  },
})
