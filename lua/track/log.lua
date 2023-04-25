local M = {}
local Log = require("plenary.log")
local Config = require("track.config").get()

M._log = Log.new(Config.log) -- TODO: Please, FTLOG. Use this. Logging is seriously underrated.

function M.errors(bool, message, title)
  assert(message and title, "All params are required.")
  if not bool then
    error(message, vim.log.levels.ERROR)
    M._log.error(title .. "(): " .. message)
  end
end

return M
