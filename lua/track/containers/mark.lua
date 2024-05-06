local Mark = {}
Mark.__index = Mark
setmetatable(Mark, {
  __call = function(class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
  __eq = function(a, b)
    return a:readable() == b:readable() and a:absolute() == b:absolute()
  end,
})

local util = require("track.util")
local V = vim.fn
local U = vim.loop

---Create a new `Mark` object.
---@param opts MarkFields Available mark attributes/fields.
---@return Mark
function Mark:_new(opts)
  local types = type(opts)
  assert(types == "table", "expected: fields: table found: " .. types)
  assert(opts.path and type(opts.path) == "string", "fields.path: string cannot be nil")

  self.path = opts.path
  self.label = opts.label
  self.type = vim.F.if_nil(opts.type, util.filetype(opts.path))
  ---@diagnostic disable-next-line: missing-return
  self._NAME = "mark"
end

function Mark:absolute()
  if self.type ~= "file" and self.type ~= "directory" then return self.path end
  return V.fnamemodify(vim.fs.normalize(self.path), ":p")
end

function Mark:readable()
  if self.type ~= "file" and self.type ~= "directory" then return true end
  return not not vim.loop.fs_access(self:absolute(), "R")
end

---Check if the mark path exists. True if it does, false otherwise.
---@return boolean
function Mark:exists()
  if self.type ~= "file" and self.type ~= "directory" then return true end
  return not not U.fs_realpath(self:absolute())
end

return Mark
