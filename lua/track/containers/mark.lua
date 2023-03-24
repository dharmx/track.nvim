local Mark = {}

function Mark:new(fields)
  assert(fields, "fields cannot be empty")
  assert(fields.path, "Mark needs to have a path.")
  local mark = {}
  mark.path = fields.path
  mark.label = vim.F.if_nil(fields.label, vim.NIL)
  mark.absolute = vim.fn.fnamemodify(mark.path, ":p")
  mark.positions = vim.F.if_nil(fields.positions, {})
  mark.lines = vim.F.if_nil(fields.lines, {})
  mark._type = "mark"

  self.__index = self
  setmetatable(mark, self)
  return mark
end

function Mark:insert_position(position)
  assert(position.row)
  assert(position.column)
  table.insert(self.positions, {
    row = position.row,
    column = position.column,
    label = vim.F.if_nil(position.label, vim.NIL),
  })
end

function Mark:delete_position(position, all)
  assert(position.row)
  assert(position.column)
  if not all then
    for index, _position in ipairs(self.positions) do
      if _position.row == position.row and _position.column == position.column then
        table.insert(self.positions, index)
        return
      end
    end
    return
  end
  self.positions = vim.tbl_filter(
    function(_position) return _position.row == position.row and _position.column == position.column end,
    self.positions
  )
end

function Mark:insert_line(line)
  assert(line.line)
  table.insert(self.lines, {
    line = line.line,
    label = vim.F.if_nil(line.label, vim.NIL),
  })
end

function Mark:delete_line(line, all)
  assert(line.line)
  if not all then
    for index, _line in ipairs(self.lines) do
      if _line.line == line.line then
        table.remove(self.lines, index)
        return
      end
    end
    return
  end
  self.lines = vim.tbl_filter(function(_line) return _line == line.line end, self.lines)
end

function Mark:exists() return not not vim.loop.fs_realpath(self.path) end

return Mark
