local M = {}

local State = require("track.state")
local Util = require("track.util")
local Root = require("track.containers.root")
local Log = require("track.log")

M.root_path = Util.cwd()
State.load() -- load state from savefile if it exists

---@param file string
---@param bundle_label? string
---@param save? function
---@return Core?
function M:mark(file, bundle_label, save)
  Log.errors(file, "file cannot be nil.", "Core.mark")
  file = vim.fs.normalize(file, { expand_env = true })

  -- create a root if it does not exist
  local root = State._roots[self.root_path]
  if not root then
    ---@type Root
    local new_root = Root(self.root_path)
    State._roots[self.root_path] = new_root
    root = new_root
  end

  -- this part makes sure that root.main does not stay empty
  -- create a default bundle if no bundle_label is supplied
  if not bundle_label then
    bundle_label = root.main
    if root.bundles[bundle_label].marks[file] then return self end
  elseif not root.bundles[bundle_label] then
    root:new_bundle(bundle_label)
  end
  ---@diagnostic disable-next-line: undefined-field
  local mark = root.bundles[bundle_label]:add_mark(file)
  ---@diagnostic disable-next-line: assign-type-mismatch
  if mark then mark.type = Util.filetype(file) end
  if save then State.save() end
  return self
end

---@param file string
---@param bundle_label? string
---@param save? function
function M:unmark(file, bundle_label, save)
  file = vim.fs.normalize(file, { expand_env = true })
  local root = State._roots[self.root_path]
  if not root then
    Log.warn("Core.unmark(): cannot unmark as the root " .. self.root_path .. " does not exist")
    return
  end

  if not bundle_label then bundle_label = root.main end
  if not root.bundles[bundle_label] or not root.bundles[bundle_label].marks[file] then return end
  root.bundles[bundle_label]:remove_mark(file)
  if save then State.save() end
  return self
end

---@param save? function
function M:stash(save)
  local root = State._roots[self.root_path]
  if not root then
    Log.warn("Core.stash(): cannot stash bundle as the root " .. self.root_path .. " does not exist")
    return
  end
  root:stash_bundle()
  if save then State.save() end
  return self
end

---@param save? function
function M:restore(save)
  local root = State._roots[self.root_path]
  if not root then
    Log.warn("Core.restore(): cannot restore bundle as the root " .. self.root_path .. " does not exist")
    return
  end
  root:restore_bundle()
  if save then State.save() end
  return self
end

---@param save? function
function M:alternate(save)
  local root = State._roots[self.root_path]
  if not root then
    Log.warn("Core.alternate(): cannot alternate bundle as the root " .. self.root_path .. " does not exist")
    return
  end
  root:alternate_bundle()
  if save then State.save() end
  return self
end

---@param bundle_label? string
---@param save? function
function M:delete(bundle_label, save)
  local root = State._roots[self.root_path]
  if not root then
    Log.warn("Core.delete(): cannot delete bundle as the root " .. self.root_path .. " does not exist")
    return
  end

  if not bundle_label then
    root:delete_main_bundle()
    return self
  end
  root:delete_bundle(bundle_label)
  if save then State.save() end
  return self
end

---@param file string
---@param direction? boolean
---@param bundle_label string
---@param save? function
---@return Core?
function M:move(file, direction, bundle_label, save)
  Log.errors(file, "file needs to be present.", "Core.move")
  Log.errors(bundle_label, "bundle_label needs to be present.", "Core.move")
  file = vim.fs.normalize(file, { expand_env = true })

  local root = State._roots[self.root_path]
  if not root or not root.bundles[bundle_label] then return end

  ---@type Bundle
  local bundle = root.bundles[bundle_label]
  -- true means the item at swap index would be moved upwards
  -- false means downwards
  if direction == "next" then
    for index, view in ipairs(bundle.views) do
      if view == file then
        ---@diagnostic disable-next-line: undefined-field
        bundle:swap_marks(index + 1, index)
        break
      end
    end
  else
    for index, view in ipairs(bundle.views) do
      if view == file then
        ---@diagnostic disable-next-line: undefined-field
        bundle:swap_marks(index, index - 1)
        break
      end
    end
  end

  if save then State.save() end
  return self
end

---@overload fun(self): Core
---@overload fun(self, bundle_label: string): Core
---@overload fun(self, disable_history: boolean, maximum_history: boolean): Core
---@overload fun(self, bundle_label: string, disable_history: boolean, maximum_history: boolean): Core
function M:history(...)
  local bundle_label = vim.F.if_nil(select(1, ...), "main")
  local disable_history = vim.F.if_nil(select(2, ...), true)
  local maximum_history = vim.F.if_nil(select(3, ...), 0)
  local root = State._roots[self.root_path]
  if root then
    bundle_label = vim.F.if_nil(bundle_label, root.main)
    local bundle = root.bundles[bundle_label]
    if bundle and not bundle:empty() then
      -- we want to make bundle history togglable on the fly
      bundle.disable_history = disable_history
      bundle.maximum_history = maximum_history
    end
    return self
  end
  Log.warn("Core.history(): cannot insert into history as the root " .. self.root_path .. " does not exist")
end

return setmetatable(M, {
  ---@overload fun(self, root_path: string)
  __call = function(self, root_path)
    Log.errors(self.root_path, "root_path needs to be present.", "Core.__call")
    self.root_path = root_path
    return self
  end,
})
