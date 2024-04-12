---Root represents a directory in track.nvim. This is synonymous to cwd/project.
---A root will contain a map of bundles and the bundles will contain marks. A root will
---also contain a `main` key which (just like GIT) will be the default bundle of the root.
local Root = {}
Root.__index = Root
setmetatable(Root, {
  __call = function(class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    self.new_bundle(self, self.main, true)
    self._callize_bundles(self)
    return self
  end,
})

local Log = require("track.log")

---@module "track.containers.bundle"
local Bundle = require("track.containers.bundle")

-- TODO: Implement if cwd/block - cwd != "" then bundles from cwd will be shown instead of cwd/block.
-- TODO: Implement a way to distinguish projects. Like if cwd has .git then mark it as a git directory.

---Create a new `Root` instance.
---@param fields RootFields Available root attributes/fields.
---@return Root
function Root:_new(fields)
  local fieldstype = type(fields)
  assert(fieldstype ~= "table" or fieldstype ~= "string", "expected: fields: string|table found: " .. fieldstype)
  ---@diagnostic disable-next-line: missing-fields
  if fieldstype == "string" then fields = { path = fields } end
  assert(fields.path and type(fields.path) == "string", "fields.path: string cannot be nil")

  self.path = fields.path
  self.label = fields.label
  self.links = fields.links

  self.disable_history = vim.F.if_nil(fields.disable_history, true)
  self.maximum_history = vim.F.if_nil(fields.maximum_history, 10)
  self.history = {}

  self.bundles = {}
  self.stashed = nil -- currently stashed bundle (if any)
  self.previous = nil -- previous bundle (alternate)
  self._NAME = "root"
  ---@diagnostic disable-next-line: missing-return, assign-type-mismatch
  self.main = vim.F.if_nil(fields.main, "main")
end

---@private
---Helper for re-registering the `__call` metatable to `Root.bundles` field.
function Root:_callize_bundles()
  setmetatable(self.bundles, {
    __call = function(bundles, action)
      if action == "string" then return vim.tbl_keys(bundles) end
      return vim.tbl_values(bundles)
    end,
  })
end

---Create a new `Bundle` inside the `Root`. No collision handling implemented. If an existing bundle name
---is supplied then it will get erased with an empty one.
---@param bundle_label string The name/label of the `Bundle`.
---@param main? boolean Make this the default `Bundle`.
---@param marks? Mark[]|table<string, Mark> Optional List of marks.
function Root:new_bundle(bundle_label, main, marks)
  assert(bundle_label and type(bundle_label) == "string", "bundle_label needs to be a string and not nil.")
  main = vim.F.if_nil(main, false)
  marks = vim.F.if_nil(marks, {})
  self.bundles[bundle_label] = Bundle(bundle_label)
  Log.trace("Root.new_bundle(): bundle " .. bundle_label .. " has been created")

  ---@diagnostic disable-next-line: param-type-mismatch
  if vim.tbl_islist(marks) then
    ---@diagnostic disable-next-line: param-type-mismatch
    for _, mark in ipairs(marks) do
      self.bundles[bundle_label]:add_mark(mark)
    end
  else
    ---@diagnostic disable-next-line: assign-type-mismatch
    self.bundles[bundle_label].marks = marks
  end
  if main then self:change_main_bundle(bundle_label) end
end

---Change the default bundle. Current bundle will be saved into `Root.previous` variable.
---@param new_main string New default `Bundle`.
function Root:change_main_bundle(new_main)
  assert(new_main and type(new_main) == "string", "new_main needs to be a string|nil.")
  if not new_main then return end
  if not vim.tbl_contains(vim.tbl_keys(self.bundles), new_main) then
    Log.warn("Root.change_main_bundle(): tried changing main to a bundle " .. new_main .. " which does not exist")
    return
  end
  self.previous = self.main
  self.main = new_main
  Log.trace("Root.change_main_bundle(): main bundle has been changed")
end

---Check if a bundle exists or, not. `true` if it does `false`, otherwise.
---@param bundle_label string Label of the `Bundle` that needs to be seached for.
---@return boolean
function Root:bundle_exists(bundle_label)
  assert(bundle_label and type(bundle_label) == "string", "bundle_label needs to be a string and not nil.")
  return not not self.bundles[bundle_label]
end

---Get the main `Bundle` instance. This is not a copy but a reference.
---@return Bundle
function Root:get_main_bundle()
  return self.bundles[self.main]
end

---Generate a random bundle name using current time (in milliseconds).
---@return string
local function date_label() return "new-bundle-" .. os.date("%s") end

---Dummy function that always returns `true`.
---@return true
local function return_true() return true end

---@param on_collision fun(): boolean
---@param create_label fun(): string
function Root:stash_bundle(on_collision, create_label)
  create_label = vim.F.if_nil(create_label, date_label)
  on_collision = vim.F.if_nil(on_collision, return_true)
  assert(type(create_label) == "function", "create_label must be a fun(): string")
  assert(type(on_collision) == "function", "will_wipe must be a fun(): boolean")

  local new_name = create_label()
  assert(type(new_name) == "string", "create_label should return string")
  local wipe = on_collision()
  assert(type(wipe) == "boolean", "on_collision should return boolean")
  Log.trace("Root.stash_bundle(): main bundle has been stashed")

  if self.bundles[new_name] and not wipe then return end
  self.stashed = self.main
  self:new_bundle(new_name, true)
end

function Root:restore_bundle()
  if not self.stashed then return end
  if self.bundles[self.stashed] then self:change_main_bundle(self.stashed) end
  self.stashed = nil
  Log.trace("Root.restore_bundle(): stashed bundle has been restored")
end

function Root:alternate_bundle()
  if not self.previous or not self.bundles[self.previous] then return end
  self:change_main_bundle(self.previous)
  Log.trace("Root.alternate_bundle(): main bundle is now previous bundle")
end

function Root:delete_main_bundle()
  local bundle_labels = vim.tbl_keys(self.bundles)
  if #bundle_labels == 1 then
    Log.warn("Root.delete_bundle(): tried deleting last bundle " .. self.main)
    return
  end

  for index, bundle_label in ipairs(bundle_labels) do
    if bundle_label == self.main then
      table.remove(bundle_labels, index)
      self:change_main_bundle(bundle_labels[1]) -- changes self.main
      self:insert_history(self.bundles[bundle_label])
      if self.previous == bundle_label then self.previous = nil end
      if self.stashed == bundle_label then self.stashed = nil end
      self.bundles[bundle_label] = nil
      return
    end
  end
end

function Root:delete_bundle(bundle_label)
  if not self:bundle_exists(bundle_label) then
    Log.warn("Root.delete_bundle(): tried deleting a bundle " .. bundle_label .. " that does not exist")
    return
  end
  if self.main == bundle_label then
    self:delete_main_bundle()
    return
  end
  if self.previous == bundle_label then self.previous = nil end
  if self.stashed == bundle_label then self.stashed = nil end
  self:insert_history(self.bundles[bundle_label])
  self.bundles[bundle_label] = nil
end

function Root:link(root_path)
  assert(root_path and type(root_path) == "string", "root_path needs to be a string and not nil.")
  self.links = vim.F.if_nil(self.links, {})
  table.insert(self.links, root_path)
  Log.trace("Root.link(): linked root " .. root_path .. " to current root")
end

function Root:unlink(root_path)
  assert(root_path and type(root_path) == "string", "root_path needs to be a string and not nil.")
  if not self.links then return end
  self.links = vim.tbl_filter(function(_item) return _item ~= root_path end, self.links)
  Log.trace("Root.unlink(): unlinked root " .. root_path .. " from current root")
end

function Root:insert_history(bundle, force)
  local bundle_type = type(bundle)
  assert(bundle_type == "table" and bundle._NAME == "bundle", "bundle: Bundle cannot be nil")
  if self.disable_history and not force then return end
  table.insert(self.history, 1, bundle)
  if #self.history > self.maximum_history then table.remove(self.history, #self.history) end
  Log.trace("Root.insert_history(): bundle " .. bundle.label .. " has been recorded into history")
end

return Root
