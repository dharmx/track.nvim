---@diagnostic disable: undefined-field
local Root = {}
local Bundle = require("track.containers.bundle")

-- TODO: Implement links.
-- TODO: Implement if cwd/block - cwd != "" then bundles from cwd will be shown instead of cwd/block.
-- TODO: Implement a way to distinguish projects. Like if cwd has .git then mark it as a git directory.

function Root:new(fields)
  assert(fields and type(fields) == "table", "fields: table cannot be empty")
  assert(fields.path and type(fields.path) == "string", "Root needs to have a path: string field.")

  local root = {}
  root.path = fields.path
  root.label = fields.label
  root.links = fields.links

  root.bundles = vim.F.if_nil(fields.bundles, {})
  setmetatable(root.bundles, {
    __call = function(bundles, action)
      if action == "string" then return vim.tbl_keys(bundles) end
      return vim.tbl_values(bundles)
    end,
  })

  root.main = fields.main
  root._stashed = nil
  root._previous = nil
  root._type = "root"

  self.__index = self
  setmetatable(root, self)
  return root
end

function Root:new_bundle(bundle_label, main, marks)
  assert(bundle_label and type(bundle_label) == "string", "bundle_label needs to be a string and not nil.")
  main = vim.F.if_nil(main, false)
  self.bundles[bundle_label] = Bundle:new({ label = bundle_label, marks = vim.F.if_nil(marks, {}) })
  if main then self:change_main_bundle(bundle_label) end
end

function Root:change_main_bundle(new_main)
  assert(new_main and type(new_main) == "string", "new_main needs to be a string|nil.")
  if not new_main then return end
  if not vim.tbl_contains(vim.tbl_keys(self.bundles), new_main) then return end
  self._previous = self.main
  self.main = new_main
end

function Root:bundle_exists(bundle_label)
  assert(bundle_label and type(bundle_label) == "string", "bundle_label needs to be a string and not nil.")
  return not not self.bundles[bundle_label]
end

function Root:create_default_bundle()
  if vim.tbl_isempty(self.bundles) or not self.bundle["main"] then
    self:new_bundle("main")
    self:change_main_bundle("main")
  end
end

function Root:get_main_bundle(create)
  if create then self:create_default_bundle() end
  return self.bundles[self.main]
end

function Root:empty() return not self.main end

local function date_label() return "new-bundle-" .. os.date("%s") end
local function return_true() return true end
function Root:stash_bundle(on_collision, create_label)
  if self:empty() then return end
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

function Root:restore_bundle()
  if self:empty() or not self._stashed then return end
  if self.bundles[self._stashed] then self:change_main_bundle(self._stashed) end
  self._stashed = nil
end

function Root:alternate_bundle()
  if self:empty() or not self._previous or not self.bundles[self._previous] then return end
  self:change_main_bundle(self._previous)
end

---@todo
function Root:delete__bundle(bundle_label) end

---@todo
function Root:unionize__bundle(bundle_labels) end

---@todo
function Root:intersect__bundle(bundle_labels) end

function Root:link(root_path)
  assert(root_path and type(root_path) == "string", "root_path needs to be a string and not nil.")
  self.links = vim.F.if_nil(self.links, {})
  table.insert(self.links, root_path)
end

function Root:unlink(root_path)
  assert(root_path and type(root_path) == "string", "root_path needs to be a string and not nil.")
  if not self.links then return end
  self.links = vim.tbl_filter(function(_item) return _item ~= root_path end, self.links)
end

return Root
