---@diagnostic disable: param-type-mismatch
---Root represents a directory in track.nvim. This is synonymous to cwd/project.
---A root will contain a map of branches and the branches will contain marks. A root will
---also contain a `main` key which (just like GIT) will be the default branch of the root.
local Root = {}
Root.__index = Root
setmetatable(Root, {
  __call = function(class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    self.new_branch(self, self.main, true)
    self._callize_branches(self)
    return self
  end,
})

local log = require("track.log")
local util = require("track.util")
local P = require("plenary.path")
local if_nil = vim.F.if_nil

---@module "track.containers.branch"
local Branch = require("track.containers.branch")

-- TODO: Implement if cwd/block - cwd != "" then branches from cwd will be shown instead of cwd/block.
-- TODO: Implement a way to distinguish projects i.e., if cwd has .git then mark it as a git directory.

---Create a new `Root` instance.
---@param opts RootFields Available root attributes/fields.
---@return Root
function Root:_new(opts)
  local types = type(opts)
  assert(types ~= "table" or types ~= "string", "expected: fields: string|table found: " .. types)
  if types == "string" then opts = { path = opts } end
  assert(opts.path and type(opts.path) == "string", "fields.path: string cannot be nil")

  self.path = opts.path
  self.label = opts.label
  self.links = opts.links

  self.disable_history = if_nil(opts.disable_history, true)
  self.maximum_history = if_nil(opts.maximum_history, 10)
  self.history = {}

  self.branches = {}
  self.stashed = nil -- currently stashed branch (if any)
  self.previous = nil -- previous branch (alternate)
  self._NAME = "root"
  ---@diagnostic disable-next-line: missing-return
  self.main = if_nil(opts.main, "main")
end

-- Metatable Setters {{{
---@private
---Helper for re-registering the `__call` metatable to `Root.branches` field.
function Root:_callize_branches()
  setmetatable(self.branches, {
    __call = function(branches, action)
      if action == "string" then return vim.tbl_keys(branches) end
      return vim.tbl_values(branches)
    end,
  })
end
-- }}}

---Create a new `Branch` inside the `Root`. No collision handling implemented. If an existing branch name
---is supplied then it will get erased with an empty one.
---@param branch_label string The name/label of the `Branch`.
---@param main? boolean Make this the default `Branch`.
---@param marks? Mark[]|table<string, Mark> Optional List of marks.
function Root:new_branch(branch_label, main, marks)
  assert(branch_label and type(branch_label) == "string", "branch_label needs to be a string and not nil.")
  main = if_nil(main, false)
  marks = if_nil(marks, {})
  self.branches[branch_label] = Branch(branch_label)
  log.trace("Root.new_branch(): branch " .. branch_label .. " has been created")

  if vim.tbl_islist(marks) then
    for _, mark in ipairs(marks) do
      self.branches[branch_label]:add_mark(mark)
    end
  else
    self.branches[branch_label].marks = marks
  end
  if main then self:change_main_branch(branch_label) end
end

---Change the default branch. Current branch will be saved into `Root.previous` variable.
---@param new_main string New default `Branch`.
function Root:change_main_branch(new_main)
  assert(new_main and type(new_main) == "string", "new_main needs to be a string|nil.")
  if not new_main then return end
  if not vim.tbl_contains(vim.tbl_keys(self.branches), new_main) then
    log.warn("Root.change_main_branch(): tried changing main to a branch " .. new_main .. " which does not exist")
    return
  end
  self.previous = self.main
  self.main = new_main
  log.trace("Root.change_main_branch(): main branch has been changed")
end

---Check if a branch exists or, not. `true` if it does `false`, otherwise.
---@param branch_label string Label of the `Branch` that needs to be seached for.
---@return boolean
function Root:branch_exists(branch_label)
  assert(branch_label and type(branch_label) == "string", "branch_label needs to be a string and not nil.")
  return not not self.branches[branch_label]
end

---Get the main `Branch` instance. This is not a copy but a reference.
---@return Branch
function Root:get_main_branch() return self.branches[self.main] end

---Generate a random branch name using current time (in milliseconds).
---@return string
local function date_label() return "new-branch-" .. os.date("%s") end

---Dummy function that always returns `true`.
---@return true
local function return_true() return true end

---@param on_collision fun(): boolean
---@param create_label fun(): string
function Root:stash_branch(on_collision, create_label)
  create_label = if_nil(create_label, date_label)
  on_collision = if_nil(on_collision, return_true)
  assert(type(create_label) == "function", "create_label must be a fun(): string")
  assert(type(on_collision) == "function", "will_wipe must be a fun(): boolean")

  local new_name = create_label()
  assert(type(new_name) == "string", "create_label should return string")
  local wipe = on_collision()
  assert(type(wipe) == "boolean", "on_collision should return boolean")
  log.trace("Root.stash_branch(): main branch has been stashed")

  if self.branches[new_name] and not wipe then return end
  self.stashed = self.main
  self:new_branch(new_name, true)
end

function Root:restore_branch()
  if not self.stashed then return end
  if self.branches[self.stashed] then self:change_main_branch(self.stashed) end
  self.stashed = nil
  log.trace("Root.restore_branch(): stashed branch has been restored")
end

function Root:alternate_branch()
  if not self.previous or not self.branches[self.previous] then return end
  self:change_main_branch(self.previous)
  log.trace("Root.alternate_branch(): main branch is now previous branch")
end

function Root:delete_main_branch()
  local branch_labels = vim.tbl_keys(self.branches)
  if #branch_labels == 1 then
    log.warn("Root.delete_branch(): tried deleting last branch " .. self.main)
    return
  end

  for index, branch_label in ipairs(branch_labels) do
    if branch_label == self.main then
      table.remove(branch_labels, index)
      self:change_main_branch(branch_labels[1]) -- changes self.main
      self:insert_history(self.branches[branch_label])
      if self.previous == branch_label then self.previous = nil end
      if self.stashed == branch_label then self.stashed = nil end
      self.branches[branch_label] = nil
      return
    end
  end
end

function Root:delete_branch(branch_label)
  if not self:branch_exists(branch_label) then
    log.warn("Root.delete_branch(): tried deleting a branch " .. branch_label .. " that does not exist")
    return
  end
  if self.main == branch_label then
    self:delete_main_branch()
    return
  end
  if self.previous == branch_label then self.previous = nil end
  if self.stashed == branch_label then self.stashed = nil end
  self:insert_history(self.branches[branch_label])
  self.branches[branch_label] = nil
end

function Root:link(root_path)
  assert(root_path and type(root_path) == "string", "root_path needs to be a string and not nil.")
  self.links = if_nil(self.links, {})
  table.insert(self.links, root_path)
  log.trace("Root.link(): linked root " .. root_path .. " to current root")
end

function Root:unlink(root_path)
  assert(root_path and type(root_path) == "string", "root_path needs to be a string and not nil.")
  if not self.links then return end
  self.links = vim.tbl_filter(function(_item) return _item ~= root_path end, self.links)
  log.trace("Root.unlink(): unlinked root " .. root_path .. " from current root")
end

function Root:insert_history(branch, force)
  local branch_type = type(branch)
  assert(branch_type == "table" and branch._NAME == "branch", "branch: Branch cannot be nil")
  if self.disable_history and not force then return end
  table.insert(self.history, 1, branch)
  if #self.history > self.maximum_history then table.remove(self.history, #self.history) end
  log.trace("Root.insert_history(): branch " .. branch.label .. " has been recorded into history")
end

function Root:rename_branch(branch, new_label)
  local branch_type = type(branch)
  assert(
    branch_type == "string" or (branch_type == "table" and branch._NAME == "branch"),
    "branch: branch needs to be Branch|string"
  )
  local label = type(branch) == "string" and branch or branch.label
  if self:branch_exists(new_label) then return end
  local old_branch = self.branches[label]

  local main = self:get_main_branch().label == label
  local stashed = self.stashed == label
  local previous = self.previous == label

  old_branch.label = new_label
  self.branches[label] = nil
  self.branches[new_label] = old_branch

  self.main = main and new_label or self.main
  self.stashed = stashed and new_label or self.stashed
  self.previous = previous and new_label or self.previous
end

return Root
