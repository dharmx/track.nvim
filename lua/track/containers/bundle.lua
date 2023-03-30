local Bundle = {}
local Mark = require("track.containers.mark")

function Bundle:new(fields)
  assert(fields and type(fields) == "table", "fields: table cannot be empty.")
  assert(fields.label and type(fields.label) == "string", "Bundle needs to have a label: string.")

  local bundle = {}
  bundle.label = fields.label
  bundle.marks = vim.F.if_nil(fields.marks, {})
  bundle.views = vim.F.if_nil(fields.views, {})

  -- TODO: Add option fields.disable_history.
  -- TODO: Add option fields.max_history (Sliding Window Algorithm).
  bundle.history = vim.F.if_nil(fields.history, {})
  bundle._type = "mark"

  setmetatable(bundle.marks, {
    __call = function(marks, action)
      if action == "string" then return vim.tbl_keys(marks) end
      return vim.tbl_values(marks)
    end,
  })
  setmetatable(bundle.views, {
    __call = function(views, _)
      local view_marks = {}
      for _, view in ipairs(views) do
        table.insert(view_marks, bundle.marks[view])
      end
      return view_marks
    end,
  })

  self.__index = self
  setmetatable(bundle, self)
  return bundle
end

function Bundle:add_mark(path, label)
  vim.validate({
    path = { path, "string" },
    label = { label, "string", true },
  })
  self.marks[path] = Mark:new({
    path = path,
    label = label,
  })
  table.insert(self.views, path)
  return self.marks[path]
end

function Bundle:remove_mark(path)
  assert(path and type(path), "path: string cannot be empty.")
  local removed_mark = self.marks[path]
  self.marks[path] = nil

  -- NOTE: Is there truly no other way? Why must table.remove be so weird?
  self.views = vim.tbl_filter(function(item) return item ~= path end, self.views)
  setmetatable(self.views, {
    __call = function(views, _)
      local marks = {}
      for _, view in ipairs(views) do
        table.insert(marks, self.marks[view])
      end
      return marks
    end,
  })
  table.insert(self.history, removed_mark)
  return removed_mark
end

function Bundle:clear()
  for _, mark in pairs(self.marks) do table.insert(self.history, mark) end
  self.marks = {}
  self.views = {}
  setmetatable(self.marks, {
    __call = function(marks, action)
      if action == "string" then return vim.tbl_keys(marks) end
      return vim.tbl_values(marks)
    end,
  })
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

function Bundle:empty() return vim.tbl_isempty(self.marks) end

return Bundle
