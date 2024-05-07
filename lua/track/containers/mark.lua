---@diagnostic disable: param-type-mismatch
local Mark = {}
Mark.__index = Mark
setmetatable(Mark, {
  ---@return Mark
  __call = function(class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
  __eq = function(a, b) return a:absolute() == b:absolute() end,
})

local util = require("track.util")
local V = vim.fn
local U = vim.loop
local if_nil = vim.F.if_nil

---Create a new `Mark` object.
---@param opts MarkFields Available mark attributes/fields.
function Mark:_new(opts)
  local types = type(opts)
  assert(types == "table", "expected: fields: table found: " .. types)
  assert(opts.path and type(opts.path) == "string", "fields.path: string cannot be nil")

  self.path = opts.path
  self.label = opts.label
  self.type = if_nil(opts.type, util.filetype(opts.path))
  self._NAME = "mark"
end

function Mark:absolute()
  if self.type ~= "file" and self.type ~= "directory" then return self.path end
  local path = vim.fs.normalize(self.path)
  return if_nil((U.fs_realpath(path)), V.fnamemodify(path, ":p"))
end

function Mark:readable()
  if self.type ~= "file" and self.type ~= "directory" then return true end
  return not not U.fs_access(self:absolute(), "R")
end

---Check if the mark path exists. True if it does, false otherwise.
---@return boolean
function Mark:exists()
  if self.type ~= "file" and self.type ~= "directory" then return true end
  return not not U.fs_realpath(self:absolute())
end

function Mark:symbolic()
  if self.type ~= "file" and self.type ~= "directory" then return false end
  return if_nil(U.fs_lstat(self:absolute()), {}).type == "link"
end

return Mark
