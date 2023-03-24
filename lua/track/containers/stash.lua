local Stash = {}
local Mark = require("track.containers.mark")

function Stash:new(fields)
  assert(fields, "fields cannot be empty")
  assert(fields.label, "Stash needs to have a label.")
  local stash = {}
  stash.label = fields.label
  stash.marks = vim.F.if_nil(fields.marks, {})
  stash._type = "mark"

  self.__index = self
  setmetatable(stash, self)
  return stash
end

function Stash:add_mark(path, label, positions, lines)
  self.marks[path] = Mark:new({
    path = path,
    label = label,
    positions = positions,
    lines = lines,
  })
  return self.marks[path]
end

function Stash:remove_mark(path)
  if type(path) == "string" then
    self.marks[path] = nil
    return
  end
  self.marks[path.path] = nil
end

return Stash
