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

local V = vim.fn
local U = vim.loop
local if_nil = vim.F.if_nil

local util = require("track.util")
local enum = require("track.dev.enum")
local M_TYPE = enum.M_TYPE
local CLASS = enum.CLASS

---Create a new `Mark` object.
---@param opts MarkFields Available mark attributes/fields.
function Mark:_new(opts)
  local types = type(opts)
  assert(types == "table", "expected: opts.opts to be table found " .. types)
  assert(opts.uri and type(opts.uri) == "string", "opts.path: string cannot be nil")

  self.uri = opts.uri
  self.label = opts.label
  self.type = if_nil(opts.type, util.filetype(opts.uri))
  self._NAME = CLASS.MARK
end

function Mark:absolute()
  local path = self.uri
  if self.type ~= M_TYPE.FILE and self.type ~= M_TYPE.DIR then return path end
  path = vim.fs.normalize(path)
  return if_nil((U.fs_realpath(path)), V.fnamemodify(path, ":p"))
end

function Mark:readable()
  if self.type ~= M_TYPE.FILE and self.type ~= M_TYPE.DIR then return true end
  return not not U.fs_access(self:absolute(), "R")
end

---Check if the mark URI exists. True if it does, false otherwise.
---@return boolean
function Mark:exists()
  if self.type == M_TYPE.NO_EXIST then return false end
  if self.type ~= M_TYPE.FILE and self.type ~= M_TYPE.DIR then return true end
  return not not U.fs_realpath(self:absolute())
end

function Mark:symbolic()
  if self.type ~= M_TYPE.FILE and self.type ~= M_TYPE.DIR then return false end
  return if_nil(U.fs_lstat(self:absolute()), {}).type == "link"
end

return Mark
