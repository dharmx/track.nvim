---@diagnostic disable: undefined-field
local Root = {}
local Stash = require("track.containers.stash")

function Root:new(fields)
  assert(fields, "fields cannot be empty")
  assert(fields.path, "Root needs to have a path field.")

  local root = {}
  root.path = fields.path
  root.label = vim.F.if_nil(fields.label, vim.NIL)
  root.links = vim.F.if_nil(fields.links, {})
  root._type = "root"

  root.stashes = vim.F.if_nil(fields.stashes, {})
  root.main = vim.F.if_nil(fields.main, "default")
  if vim.tbl_isempty(root.stashes) then
    root.stashes["default"] = Stash:new({ label = "default" })
    root.main = "default"
  end

  self.__index = self
  setmetatable(root, self)
  return root
end

function Root:new_stash(label, marks)
  self.stashes[label] = Stash:new({
    label = label,
    marks = marks,
  })
  return self.stashes[label]
end

function Root:delete_stash(label)
  if type(label) == "string" then
    self.stashes[label] = nil
    return
  end
  self.stashes[label.label] = nil
end

function Root:link(root) table.insert(self.links, root) end

function Root:unlink(root)
  self.links = vim.tbl_filter(function(_item) return _item == root end, self.links)
end

return Root
