---@mod mark Mark

-- TODO: Add position sub-mark.
-- TODO: Add line sub-mark.

---A class that represents a mark. A mark is a path inside (most of the time)
---your current working directory. It serves as a project-scoped file-bookmark.
---@class Mark
---@field path string Path to mark.
---@field label? string Optional label for that the mark.
---@field absolute string Absolute path to mark.
---@field _NAME string Type.

---@class MarkFields
---@field path string Path to mark.
---@field label? string Optional label for that the mark.

---@type Mark
local Mark = {}

local V = vim.fn
local U = vim.loop

---Create a new `Mark` object.
---@param fields MarkFields Available mark attributes/fields.
---@return Mark
function Mark:new(fields)
  assert(fields and type(fields) == "table", "fields: table cannot be empty")
  assert(fields.path and type(fields.path) == "string", "Mark needs to have a path: string.")

  local mark = {}
  mark.path = fields.path
  mark.label = fields.label
  mark.absolute = V.fnamemodify(mark.path, ":p")
  mark._NAME = "mark"

  self.__index = self
  setmetatable(mark, self)
  return mark
end

---Check if the mark path exists. True if it does, false otherwise.
---@return boolean
function Mark:exists() return not not U.fs_realpath(self.absolute) end

return Mark
