---@mod mark Mark

-- TODO: Add position sub-mark.
-- TODO: Add line sub-mark.

---A class that represents a mark. A mark is a path inside (most of the time)
---your current working directory. It serves as a project-scoped file-bookmark.
---@class Mark
---@field path string Path to mark.
---@field label? string Optional label for that the mark.
---@field absolute string Absolute path to mark.
---@field bookmarks {label:string,row:number}[] Positional array.
---@field _NAME string Type.
local Mark = {}
Mark.__index = Mark
setmetatable(Mark, {
  __call = function(class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

local V = vim.fn
local U = vim.loop

---@class MarkFields
---@field path string Path to mark.
---@field label? string Optional label for that the mark.

---Create a new `Mark` object.
---@param fields MarkFields Available mark attributes/fields.
---@return Mark
function Mark:_new(fields)
  local field_types = type(fields)
  assert(field_types == "table", "expected: fields: table found: " .. field_types)
  assert(fields.path and type(fields.path) == "string", "fields.path: string cannot be nil")

  self.bookmarks = {}
  self.path = fields.path
  self.label = fields.label
  self.absolute = V.fnamemodify(self.path, ":p")
  ---@diagnostic disable-next-line: missing-return
  self._NAME = "mark"
end

function Mark:add_bookmark(label, line)
  self.bookmarks[tostring(line)] = label
end

function Mark:remove_bookmark(line)
  self.bookmarks[tostring(line)] = nil
end

---Check if the mark path exists. True if it does, false otherwise.
---@return boolean
function Mark:exists() return not not U.fs_realpath(self.absolute) end

return Mark
