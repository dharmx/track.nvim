local M = {}

local A = vim.api
M.GROUP = vim.api.nvim_create_augroup("TrackGroup", { clear = false })

function M.setup(opts)
  require("track.config").merge(opts)
  require("track.dev.log").info("setup(): plugin configured")
  require("track.core")(require("track.util").cwd())
  A.nvim_create_autocmd("DirChanged", {
    group = M.GROUP,
    callback = function() require("track.core")(require("track.util").cwd()) end,
  })
end

return setmetatable(M, {
  __index = function(_, key) return require("track.core")[key] end,
})
