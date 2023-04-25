---Root represents a directory in track.nvim. This is synonymous to cwd/project.
---A root will contain a map of bundles and the bundles will contain marks. A root will
---also contain a `main` key which (just like GIT) will be the default bundle of the root.
---@class Root
---@field path string Path to root.
---@field label? string Small description/title about the root.
---@field links? string[] Shortcuts to other roots.
---@field bundles Bundle[] Bundle map. Key is the same as `Bundle.label` and value is a `Bundle` instance.
---@field main string Master bundle. This is similar to the `main` branch in GIT.
---@field stashed? string Flag variable that will be set if a bundle has been stashed.
---@field previous? string Flag variable that will be set if the `main` bundle has an alternate bundle.
---@field _NAME string Type.
local Root = {}

local Log = require("track.log")._log

---@module "track.containers.bundle"
local Bundle = require("track.containers.bundle")

-- TODO: Implement if cwd/block - cwd != "" then bundles from cwd will be shown instead of cwd/block.
-- TODO: Implement a way to distinguish projects. Like if cwd has .git then mark it as a git directory.

---@class RootFields
---@field path string Path to root.
---@field label? string Small description/title about the root.
---@field links? string[] Shortcuts to other roots.
---@field bundles? Bundle[] Bundle map. Key is the same as `Bundle.label` and value is a `Bundle` instance.
---@field main? string Master bundle. This is similar to the `main` branch in GIT.
---@field stashed? string Flag variable that will be set if a bundle has been stashed.
---@field previous? string Flag variable that will be set if the `main` bundle has an alternate bundle.

---Create a new `Root` instance.
---@param fields RootFields Available root attributes/fields.
---@return Root
function Root:new(fields)
  assert(fields and type(fields) == "table", "fields: table cannot be empty")
  assert(fields.path and type(fields.path) == "string", "Root needs to have a path: string field.")

  local root = {}
  root.path = fields.path
  root.label = fields.label
  root.links = fields.links

  root.bundles = {}
  root.stashed = nil -- currently stashed bundle (if any)
  root.previous = nil -- previous bundle (alternate)
  root._NAME = "root"
  root.main = vim.F.if_nil(fields.main, "main")

  self.__index = self
  setmetatable(root, self)
  self.new_bundle(root, root.main, true)
  self._callize_bundles(root)
  return root
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
  self.bundles[bundle_label] = Bundle:new({ label = bundle_label })
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
  if not vim.tbl_contains(vim.tbl_keys(self.bundles), new_main) then return end
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

-- Not implemented. {{{
---@todo
function Root:delete__bundle(bundle_label)
  Log.warn("Root.delete__bundle(): this function has not been implemented")
end

---@todo
function Root:bundle__union(bundle_labels)
  Log.warn("Root.bundle__union(): this function has not been implemented")
end

---@todo
function Root:bundle__intersection(bundle_labels)
  Log.warn("Root.bundle__intersection(): this function has not been implemented")
end
-- }}}

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

return Root
