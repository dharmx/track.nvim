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
  assert(opts.uri and type(opts.uri) == "string", "fields.path: string cannot be nil")

  self.uri = opts.uri
  self.label = opts.label
  self.type = if_nil(opts.type, util.filetype(opts.uri))
  self._NAME = "mark"
end

function Mark:absolute()
  if self.type ~= "file" and self.type ~= "directory" then return self.uri end
  local path = vim.fs.normalize(self.uri)
  return if_nil((U.fs_realpath(path)), V.fnamemodify(path, ":p"))
end

function Mark:readable()
  if self.type ~= "file" and self.type ~= "directory" then return true end
  return not not U.fs_access(self:absolute(), "R")
end

---Check if the mark URI exists. True if it does, false otherwise.
---@return boolean
function Mark:exists()
  if self.type == "no_exists" then return false end
  if self.type ~= "file" and self.type ~= "directory" then return true end
  return not not U.fs_realpath(self:absolute())
end

function Mark:symbolic()
  if self.type ~= "file" and self.type ~= "directory" then return false end
  return if_nil(U.fs_lstat(self:absolute()), {}).type == "link"
end

return Mark
