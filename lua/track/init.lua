local M = {}

function M.setup(options)
  require("track.config").merge(options)
  require("track.log").info("Init.setup(): plugin has be configured")
end

setmetatable(M, {
  __index = function(_, key)
    return require("track.core")[key]
  end
})
return M
