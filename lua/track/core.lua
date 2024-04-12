local M = {}

local State = require("track.state")
local Util = require("track.util")
local Root = require("track.containers.root")
local Log = require("track.log")

---@param root_path string
---@param file string
---@param bundle_label? string
---@param save? function
function M.mark(root_path, file, bundle_label, save)
  Log.errors(root_path, "root_path needs to be present.", "Core.mark")
  Log.errors(file, "file cannot be nil.", "Core.mark")
  file = Util.filter_path(file) -- remove // and trailing /
  State.load() -- load state from savefile if it exists

  -- create a root if it does not exist
  local root = State._roots[root_path]
  if not root then
    ---@type Root
    local new_root = Root(root_path)
    State._roots[root_path] = new_root
    root = new_root
  end

  -- this part makes sure that root.main does not stay empty
  -- create a default bundle if no bundle_label is supplied
  if not bundle_label then
    bundle_label = root.main
    if root.bundles[bundle_label].marks[file] then return end
  elseif not root.bundles[bundle_label] then
    root:new_bundle(bundle_label)
  end
  ---@diagnostic disable-next-line: undefined-field
  local mark = root.bundles[bundle_label]:add_mark(file)
  ---@diagnostic disable-next-line: assign-type-mismatch
  if mark then mark.type = vim.loop.fs_stat(file).type end
  if save then State.save() end
end

---@param root_path string
---@param file string
---@param bundle_label? string
---@param save? function
function M.unmark(root_path, file, bundle_label, save)
  Log.errors(root_path, "root_path needs to be present.", "Core.unmark")
  file = Util.filter_path(file)
  State.load()

  local root = State._roots[root_path]
  if not root then
    Log.warn("Core.unmark(): cannot unmark as the root " .. root_path .. " does not exist")
    return
  end

  if not bundle_label then bundle_label = root.main end
  if not root.bundles[bundle_label] or not root.bundles[bundle_label].marks[file] then return end
  root.bundles[bundle_label]:remove_mark(file)
  if save then State.save() end
end

---@param root_path string
---@param save? function
function M.stash(root_path, save)
  Log.errors(root_path, "root_path needs to be present.", "Core.stash")
  local root = State._roots[root_path]
  if not root then
    Log.warn("Core.stash(): cannot stash bundle as the root " .. root_path .. " does not exist")
    return
  end
  root:stash_bundle()
  if save then State.save() end
end

---@param root_path string
---@param save? function
function M.restore(root_path, save)
  Log.errors(root_path, "root_path needs to be present.", "Core.restore")
  State.load()
  local root = State._roots[root_path]
  if not root then
    Log.warn("Core.restore(): cannot restore bundle as the root " .. root_path .. " does not exist")
    return
  end
  root:restore_bundle()
  if save then State.save() end
end

---@param root_path string
---@param save? function
function M.alternate(root_path, save)
  Log.errors(root_path, "root_path needs to be present.", "Core.alternate")
  State.load()
  local root = State._roots[root_path]
  if not root then
    Log.warn("Core.alternate(): cannot alternate bundle as the root " .. root_path .. " does not exist")
    return
  end
  root:alternate_bundle()
  if save then State.save() end
end

---@param root_path string
---@param bundle_label? string
---@param save? function
function M.delete(root_path, bundle_label, save)
  Log.errors(root_path, "root_path needs to be present.", "Core.delete")
  State.load()
  local root = State._roots[root_path]
  if not root then
    Log.warn("Core.delete(): cannot delete bundle as the root " .. root_path .. " does not exist")
    return
  end

  if not bundle_label then
    root:delete_main_bundle()
    return
  end
  root:delete_bundle(bundle_label)
  if save then State.save() end
end

---@param root_path string
---@param file string
---@param direction? boolean
---@param bundle_label string
---@param save? function
---@return Bundle?
function M.move(root_path, file, direction, bundle_label, save)
  Log.errors(root_path, "root_path needs to be present.", "Core.move")
  Log.errors(file, "file needs to be present.", "Core.move")
  Log.errors(bundle_label, "bundle_label needs to be present.", "Core.move")

  file = Util.filter_path(file)
  State.load()

  local root = State._roots[root_path]
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
  return root.bundles[bundle_label]
end

---@param root_path string
---@param bundle_label? string
---@param disable_history? boolean
---@param maximum_history? number
function M.history(root_path, bundle_label, disable_history, maximum_history)
  Log.errors(root_path, "root_path needs to be present.", "Core.delete")
  local root = State._roots[root_path]
  if root then
    bundle_label = vim.F.if_nil(bundle_label, root.main)
    local bundle = root.bundles[bundle_label]
    if bundle and not bundle:empty() then
      -- we want to make bundle history togglable on the fly
      bundle.disable_history = disable_history
      bundle.maximum_history = maximum_history
    end
    return
  end
  Log.warn("Core.history(): cannot insert into history as the root " .. root_path .. " does not exist")
end

return M
