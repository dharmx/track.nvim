---@mod mark Mark

-- TODO: Add position sub-mark.
-- TODO: Add line sub-mark.
-- TODO: Add URL sub-mark.

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

---Create a new `Mark` object.
---@param fields MarkFields Available mark attributes/fields.
---@return Mark
function Mark:_new(fields)
  local field_types = type(fields)
  assert(field_types == "table", "expected: fields: table found: " .. field_types)
  assert(fields.path and type(fields.path) == "string", "fields.path: string cannot be nil")

  self.path = fields.path
  self.label = fields.label
  self.type = vim.F.if_nil(fields.type, "file")
  self.absolute = V.fnamemodify(self.path, ":p")
  self._NAME = "mark"
end

---Check if the mark path exists. True if it does, false otherwise.
---@return boolean
function Mark:exists() return not not U.fs_realpath(self.absolute) end

return Mark
