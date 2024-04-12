---@diagnostic disable: param-type-mismatch
local M = {}

function M.setup(opts)
  require("track.config").merge(opts)
  require("track.log").info("Init.setup(): plugin has been configured")
end

setmetatable(M, {
  __index = function(_, key)
    return require("track.core")[key]
  end
})
return M
