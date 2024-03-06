---@diagnostic disable: param-type-mismatch
local M = {}
M._group = vim.api.nvim_create_augroup("Track", {})
local AU = vim.api.nvim_create_autocmd

function M.setup(options)
  require("track.config").merge(options)
  require("track.log").info("Init.setup(): plugin has been configured")
  AU({ "BufWinEnter", "BufEnter" }, {
    group = M._group,
    callback = function()
      require("track.ui").load_bookmarks(vim.fn.bufnr("%"))
    end,
  })
end

setmetatable(M, {
  __index = function(_, key)
    return require("track.core")[key]
  end
})
return M
