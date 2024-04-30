local Pad = {}
Pad.__index = Pad
setmetatable(Pad, {
  __call = function(class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

local A = vim.api
local util = require("track.util")

function Pad:_new(fields)
  local field_types = type(fields)
  assert(field_types == "table", "expected: fields: table found: " .. field_types)

  self.entries = vim.F.if_nil(fields, {})
  self.bundle = vim.F.if_nil(fields.bundle, select(2, util.root_and_bundle()))
  self.config = fields.config
  self.buffer = A.nvim_create_buf(false, false)
  self.namespace = A.nvim_create_namespace("TrackPad")
  self.window = nil

  A.nvim_buf_set_option(self.buffer, "number", true)
  A.nvim_buf_set_option(self.buffer, "filetype", "track")
  A.nvim_buf_set_name(self.buffer, self.bundle.label)
  A.nvim_buf_set_option(self.buffer, "indentexpr", "3")

  if fields.path_display then
    A.nvim_create_autocmd("InsertLeave", {
      buffer = self.buffer,
      group = require("track").TRACK_GROUP,
      callback = function()
        if A.nvim_get_mode().mode ~= "n" then return end
        -- TODO: shorten entry paths
      end,
    })
  end
  self._NAME = "pad"
end

function Pad:hidden() return self.window and A.nvim_win_is_valid(self.window) end

function Pad:lock() return A.nvim_buf_set_option(self.buffer, "modifiable", true) end

function Pad:unlock() return A.nvim_buf_set_option(self.buffer, "modifiable", false) end

function Pad:open()
  if self:hidden() then return end
  self.window = A.nvim_open_win(self.buffer, true, self.config)
  A.nvim_win_set_option(self.window, "winhighlight", "FloatTitle:TrackPadTitle,FloatBorder:NormalFloat")
  A.nvim_win_set_option(self.window, "number", true)
  A.nvim_win_set_option(self.window, "cursorline", true)
end

function Pad:close()
  if not self:hidden() then return end
  A.nvim_win_close(self.window, true)
  self.window = nil
end

function Pad:toggle()
  if self:hidden() then
    self:open()
    return
  end
  self:close()
end

function Pad:clean(...)
  local line_start, line_end = ...
  if not line_start then line_start = 0 end
  if not line_end then line_end = -1 end
  return A.nvim_buf_clear_namespace(self.buffer, self.namespace, line_start, line_end)
end

return Pad
