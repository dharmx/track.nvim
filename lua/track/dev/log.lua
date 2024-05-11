local M = {}

local log = require("plenary.log")
local config = require("track.config").get()

M._log = log.new(config.log)

function M.errors(bool, message, title)
  assert(message and title, "All params are required.")
  if not bool then
    error(message, vim.log.levels.ERROR)
    M._log.error(title .. "(): " .. message)
  end
end

setmetatable(M, {
  __index = function(_, key) return M._log[key] end,
})
return M
