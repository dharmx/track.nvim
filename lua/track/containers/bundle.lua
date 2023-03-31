local Bundle = {}
local Mark = require("track.containers.mark")

function Bundle:new(fields)
  assert(fields and type(fields) == "table", "fields: table cannot be empty.")
  assert(fields.label and type(fields.label) == "string", "Bundle needs to have a label: string.")

  local bundle = {}
  bundle.label = fields.label
  bundle.marks = vim.F.if_nil(fields.marks, {})
  bundle.views = vim.F.if_nil(fields.views, {})
  bundle.disable_history = vim.F.if_nil(fields.disable_history, true)
  bundle.maximum_history  = vim.F.if_nil(fields.maximum_history , 10)
  bundle.history = vim.F.if_nil(fields.history, {})
  bundle._type = "mark"

  self.__index = self
  setmetatable(bundle, self)
  self._callize_views(bundle)
  self._callize_marks(bundle)
  return bundle
end

-- Metatable Setters {{{
---@private
function Bundle:_callize_views()
  setmetatable(self.views, {
    __call = function(views, _)
      local view_marks = {}
      for _, view in ipairs(views) do
        table.insert(view_marks, self.marks[view])
      end
      return view_marks
    end,
  })
end

---@private
function Bundle:_callize_marks()
  setmetatable(self.marks, {
    __call = function(marks, action)
      if action == "string" then return vim.tbl_keys(marks) end
      return vim.tbl_values(marks)
    end,
  })
end
-- }}}

function Bundle:add_mark(mark, label)
  if type(mark) == "table" and mark._type == "mark" then
    self.marks[mark.path] = mark
    return self.marks[mark.path]
  end
  self.marks[mark] = Mark:new({ path = mark, label = label })
  table.insert(self.views, mark)
  return self.marks[mark]
end

function Bundle:remove_mark(path)
  assert(path and type(path), "path: string cannot be empty.")
  local removed_mark = self.marks[path]
  self.marks[path] = nil
  self.views = vim.tbl_filter(function(item) return item ~= path end, self.views)
  self:_callize_views()
  self:insert_history(removed_mark)
  return removed_mark
end

function Bundle:clear()
  for _, mark in pairs(self.marks) do
    table.insert(self.history, mark)
  end
  self.marks = {}
  self.views = {}
  self:_callize_views()
  self:_callize_marks()
end

function Bundle:insert_history(mark, force)
  local mark_type = type(mark)
  assert(mark_type == "table" and mark._type == "mark", "mark: Mark cannot be nil.")
  if self.disable_history and not force then return end
  table.insert(self.history, 1, mark)
  if #self.history > self.maximum_history then table.remove(self.history, #self.history) end
end

function Bundle:empty() return vim.tbl_isempty(self.marks) end

return Bundle
