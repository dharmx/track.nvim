local M = {}

local state = require("track.state")
local util = require("track.util")
local config = require("track.config")

local Root = require("track.containers.root")
local Mark = require("track.containers.mark")
local Pad = require("track.pad")

local log = require("track.log")
local if_nil = vim.F.if_nil
state.load() -- load state from savefile if it exists

---@param file string
---@param branch_label? string
---@param save? function
---@return Core?
function M:mark(file, branch_label, save)
  log.errors(file, "file cannot be nil.", "Core.mark")
  if util.contains(config.get().exclude, file) then return self end

  -- create a root if it does not exist
  local root = state._roots[self.root_path]
  if not root then
    ---@type Root
    local new_root = Root(self.root_path)
    state._roots[self.root_path] = new_root
    root = new_root
  end

  -- this part makes sure that root.main does not stay empty
  -- create a default branch if no branch_label is supplied
  if not branch_label then
    branch_label = root.main
    if root.branches[branch_label].marks[file] then return self end
  elseif not root.branches[branch_label] then
    root:new_branch(branch_label)
  end

  local mark = Mark({ uri = file })
  if mark.type == "term" then mark.uri = util.clean_term_uri(file) end
  root.branches[branch_label]:add_mark(mark)
  if save then state.save() end
  return self
end

---@param file string
---@param branch_label? string
---@param save? function
function M:unmark(file, branch_label, save)
  local root = state._roots[self.root_path]
  if not root then
    log.warn("Core.unmark(): cannot unmark as the root " .. self.root_path .. " does not exist")
    return self
  end

  if not branch_label then branch_label = root.main end
  local mark = Mark({ uri = file })
  if mark.type == "term" then mark.uri = util.clean_term_uri(file) end

  local branch = root.branches[branch_label]
  if not branch or not branch.marks[mark:absolute()] then return self end
  branch:remove_mark(mark)
  if save then state.save() end
  return self
end

---@param save? function
function M:stash(save)
  local root = state._roots[self.root_path]
  if not root then
    log.warn("Core.stash(): cannot stash branch as the root " .. self.root_path .. " does not exist")
    return
  end
  root:stash_branch()
  if save then state.save() end
  return self
end

---@param save? function
function M:restore(save)
  local root = state._roots[self.root_path]
  if not root then
    log.warn("Core.restore(): cannot restore branch as the root " .. self.root_path .. " does not exist")
    return
  end
  root:restore_branch()
  if save then state.save() end
  return self
end

---@param save? function
function M:alternate(save)
  local root = state._roots[self.root_path]
  if not root then
    log.warn("Core.alternate(): cannot alternate branch as the root " .. self.root_path .. " does not exist")
    return
  end
  root:alternate_branch()
  if save then state.save() end
  return self
end

---@param branch_label? string
---@param save? function
function M:delete(branch_label, save)
  local root = state._roots[self.root_path]
  if not root then
    log.warn("Core.delete(): cannot delete branch as the root " .. self.root_path .. " does not exist")
    return
  end

  if not branch_label then
    root:delete_main_branch()
    return self
  end
  root:delete_branch(branch_label)
  if save then state.save() end
  return self
end

---@param file string
---@param direction? boolean
---@param branch_label string
---@param save? function
---@return Core?
function M:move(file, direction, branch_label, save)
  log.errors(file, "file needs to be present.", "Core.move")
  log.errors(branch_label, "branch_label needs to be present.", "Core.move")

  local root = state._roots[self.root_path]
  if not root or not root.branches[branch_label] then return end

  ---@type Branch
  local branch = root.branches[branch_label]
  -- true means the item at swap index would be moved upwards
  -- false means downwards
  if direction == "next" then
    for index, view in ipairs(branch.views) do
      if view == file then
        branch:swap_marks(index + 1, index)
        break
      end
    end
  else
    for index, view in ipairs(branch.views) do
      if view == file then
        branch:swap_marks(index, index - 1)
        break
      end
    end
  end

  if save then state.save() end
  return self
end

---@overload fun(self): Core
---@overload fun(self, branch_label: string): Core
---@overload fun(self, disable_history: boolean, maximum_history: boolean): Core
---@overload fun(self, branch_label: string, disable_history: boolean, maximum_history: boolean): Core
function M:history(...)
  local branch_label = if_nil(select(1, ...), "main")
  local disable_history = if_nil(select(2, ...), true)
  local maximum_history = if_nil(select(3, ...), 0)
  local root = state._roots[self.root_path]
  if root then
    branch_label = if_nil(branch_label, root.main)
    local branch = root.branches[branch_label]
    if branch and not branch:empty() then
      -- we want to make branch history togglable on the fly
      branch.disable_history = disable_history
      branch.maximum_history = maximum_history
    end
    return self
  end
  log.warn("Core.history(): cannot insert into history as the root " .. self.root_path .. " does not exist")
end

function M:select(index, callback, branch_label)
  local root = state._roots[self.root_path]
  if not root then return end
  if not branch_label then branch_label = root.main end

  local branch = root.branches[branch_label]
  if not branch then return end

  local view_mark
  local index_type = type(index)
  if index_type == "number" then
    view_mark = branch.views()[index]
  elseif index_type == "string" then
    view_mark = branch.marks[index]
  end

  if not view_mark then return end
  callback(view_mark)
end

return setmetatable(M, {
  ---@overload fun(self, root_path: string)
  __call = function(self, root_path)
    log.errors(root_path, "root_path needs to be present.", "Core.__call")
    self.root_path = root_path
    if self.pad then self.pad:delete() end
    self.pad = Pad(config.get_pad())
    return self
  end,
})
