---@diagnostic disable: undefined-field
local Root = {}
local Bundle = require("track.containers.bundle")

function Root:new(fields)
  assert(fields and type(fields) == "table", "fields: table cannot be empty")
  assert(fields.path and type(fields.path) == "string", "Root needs to have a path: string field.")

  local root = {}
  root.path = fields.path
  root.label = vim.F.if_nil(fields.label, vim.NIL)
  root.links = vim.F.if_nil(fields.links, {})

  -- TODO: Set __call metatable to get bundle list.
  root.bundles = vim.F.if_nil(fields.bundles, {})
  root.main = vim.F.if_nil(fields.main, vim.NIL)
  root._stashed = vim.NIL
  root._type = "root"

  self.__index = self
  setmetatable(root, self)
  return root
end

function Root:new_bundle(label, main, marks)
  assert(label and type(label) == "string", "label needs to be a string and not nil.")
  main = vim.F.if_nil(main, false)
  self.bundles[label] = Bundle:new({ label = label, marks = vim.F.if_nil(marks, {}) })
  if main then self.main = label end
end

function Root:change_main_bundle(new_main)
  assert(new_main and type(new_main) == "string", "new_main needs to be a string|vim.NIL, not nil.")
  if self.main == new_main or new_main == vim.NIL then return end
  if vim.tbl_contains(vim.tbl_keys(self.bundles), new_main) then self.main = new_main end
end

function Root:bundle_exists(bundle_label)
  assert(bundle_label and type(bundle_label) == "string", "bundle_label needs to be a string and not nil.")
  return not not self.bundles[bundle_label]
end

function Root:create_default_bundle()
  if vim.tbl_isempty(self.bundles) or not self.bundle["main"] then
    self:new_bundle("main")
    self.main = "main"
  end
end

function Root:get_main_bundle(create)
  if create then self:create_default_bundle() end
  return self.bundles[self.main]
end

local function date_label() return "new-bundle-" .. os.date("%s") end
local function return_true() return true end
function Root:stash_bundle(on_collision, create_label)
  if self.main == vim.NIL then return end
  create_label = vim.F.if_nil(create_label, date_label)
  on_collision = vim.F.if_nil(on_collision, return_true)
  assert(type(create_label) == "function", "create_label must be a fun(): string")
  assert(type(on_collision) == "function", "will_wipe must be a fun(): boolean")

  local new_name = create_label()
  assert(type(new_name) == "string", "create_label should return string")
  local wipe = on_collision()
  assert(type(wipe) == "boolean", "on_collision should return boolean")
  if self.bundles[new_name] and not wipe then return end
  self._stashed = self.main
  self:new_bundle(new_name, true)
end

function Root:empty()
  return self.main == vim.NIL
end

function Root:restore_bundle()
  if self._stashed == vim.NIL then return end
  if self.bundles[self._stashed] then
    self:change_main_bundle(self._stashed)
  end
  self._stashed = vim.NIL
end

---@todo
function Root:delete_bundle(bundle_label)
  assert(bundle_label and type(bundle_label) == "string", "bundle_label needs to be a string and not nil.")
  if self.bundles[bundle_label] then
    if #vim.tbl_keys(self.bundles) == 1 then return end
  end
end

function Root:link(root_path)
  assert(root_path and type(root_path) == "string", "root_path needs to be a string and not nil.")
  table.insert(self.links, root_path)
end

function Root:unlink(root_path)
  assert(root_path and type(root_path) == "string", "root_path needs to be a string and not nil.")
  self.links = vim.tbl_filter(function(_item) return _item ~= root_path end, self.links)
end

Root.__newindex = function(_, value) assert(value == nil, "Adding additional fields aren't allowed.") end

return Root
