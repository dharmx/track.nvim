local Bundle = {}
local Mark = require("track.containers.mark")

function Bundle:new(fields)
  assert(fields and type(fields) == "table", "fields: table cannot be empty.")
  assert(fields.label and type(fields.label) == "string", "Bundle needs to have a label: string.")
  local bundle = {}
  bundle.label = fields.label
  bundle.marks = vim.F.if_nil(fields.marks, {})
  setmetatable(bundle.marks, {
    __call = function(marks, action)
      if action == "string" then return vim.tbl_keys(marks) end
      return vim.tbl_values(marks)
    end,
  })

  bundle.views = vim.F.if_nil(fields.views, {})
  setmetatable(bundle.views, {
    __call = function(views, _)
      local marks = {}
      for _, view in ipairs(views) do
        table.insert(marks, bundle.marks[view])
      end
      return marks
    end,
  })
  bundle._type = "mark"

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
  self.marks[path] = nil
  self.views = vim.tbl_filter(function(item) return item ~= path end, self.views)
end

function Bundle:empty() return vim.tbl_isempty(self.marks) end

return Bundle
