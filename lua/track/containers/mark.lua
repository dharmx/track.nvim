local Mark = {}

function Mark:new(fields)
  assert(fields and type(fields) == "table", "fields: table cannot be empty")
  assert(fields.path and type(fields.path) == "string", "Mark needs to have a path: string.")
  local mark = {}
  mark.path = fields.path
  mark.label = fields.label
  mark.absolute = vim.fn.fnamemodify(mark.path, ":p")
  mark._type = "mark"

  self.__index = self
  setmetatable(mark, self)
  return mark
end

function Mark:exists() return not not vim.loop.fs_realpath(self.path) end

return Mark
