local M = {}

M.TRACK_GROUP = vim.api.nvim_create_augroup("TrackGroup", { clear = false })

function M.setup(opts)
  require("track.config").merge(opts)
  require("track.log").info("Init.setup(): plugin has been configured")
  vim.api.nvim_create_autocmd("DirChanged", {
    group = M.TRACK_GROUP,
    callback = function()
      require("track.core")(require("track.util").cwd())
    end,
  })
end

setmetatable(M, {
  __index = function(_, key)
    return require("track.core")[key]
  end
})
return M
