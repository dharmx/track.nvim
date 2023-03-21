local present, telescope = pcall(require, "telescope")

if not present then
  vim.notify("This plugin requires telescope.nvim.")
  return
end

local interface = require("track.interface")
local marks = require("track.marks")

local _defaults = {
  state_path = vim.fn.stdpath("state") .. "/track.json",
  prompt_prefix = "  ",
  previewer = false,
  layout_config = { width = 0.3, height = 0.4 },
  roots = {},
}
local _current = _defaults

local function setup(options)
  options = vim.F.if_nil(options, {})
  _current = vim.tbl_deep_extend("keep", options, _current)
end

local function track(options)
  options = vim.F.if_nil(options, {})
  options = vim.tbl_deep_extend("keep", options, _current)
  marks.load(options)
  interface.open(options)
end

return telescope.register_extension({
  setup = setup,
  exports = { track = track },
})
