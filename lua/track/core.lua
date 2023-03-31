local M = {}
local State = require("track.state")
local Util = require("track.util")
local Root = require("track.containers.root")

function M.mark(root_path, file, bundle_label, save)
  assert(root_path, "root_path needs to be present.")
  assert(file, "file cannot be nil.")
  file = Util.filter_path(file) -- remove // and trailing /
  State.load() -- load state from savefile if it exists

  -- create a root if it does not exist
  local root = State._roots[root_path]
  if not root then
    local new_root = Root:new({ path = root_path })
    State._roots[root_path] = new_root
    root = new_root
  end

  -- this part makes sure that root.main does not stay empty
  -- create a default bundle if no bundle_label is supplied
  if not bundle_label then
    -- create_default_bundle sets root.main = "main"
    if root:empty() then
      root:create_default_bundle()
    end
    bundle_label = root.main
    if root.bundles[bundle_label].marks[file] then return end
  elseif not root.bundles[bundle_label] then
    root:new_bundle(bundle_label)
  end
  root.bundles[bundle_label]:add_mark(file)
  if save then State.save() end
end

function M.unmark(root_path, file, bundle_label, save)
  assert(root_path, "root_path needs to be present.")
  file = Util.filter_path(file)
  State.load()

  local root = State._roots[root_path]
  if not root then return end

  -- root.main being null implies that there are no bundles in root
  -- which also implies that there are not any marks too
  if root:empty() then return end
  if not bundle_label then bundle_label = root.main end
  if not root.bundles[bundle_label] or not root.bundles[bundle_label].marks[file] then return end
  root.bundles[bundle_label]:remove_mark(file)
  if save then State.save() end
end

function M.stash(root_path, save)
  assert(root_path, "root_path needs to be present.")
  State.load()
  local root = State._roots[root_path]
  if not root or root:empty() then return end
  root:stash_bundle()
  if save then State.save() end
end

function M.restore(root_path, save)
  assert(root_path, "root_path needs to be present.")
  State.load()
  local root = State._roots[root_path]
  if not root then return end
  root:restore_bundle()
  if save then State.save() end
end

function M.alternate(root_path, save)
  assert(root_path, "root_path needs to be present.")
  State.load()
  local root = State._roots[root_path]
  if not root then return end
  root:alternate_bundle()
  if save then State.save() end
end

function M.delete(root_path, bundle_label, save)
  assert(root_path, "root_path cannot be nil.")
  assert(bundle_label, "bundle_label cannot be nil.")
  State.load()
  local root = State._roots[root_path]
  if not root or root:empty() then return end
  root:delete_bundle(bundle_label)
  if save then State.save() end
end

function M.move(root_path, file, direction, bundle_label, save)
  assert(root_path, "root_path needs to be present.")
  assert(file, "file cannot be nil.")
  assert(bundle_label, "bundle_label cannot be nil.")
  file = Util.filter_path(file)
  assert(type(direction) == "boolean", "direction_path must be boolean.")
  State.load()

  local root = State._roots[root_path]
  if not root or root:empty() or not root.bundles[bundle_label] then return end

  local paths = root.bundles[bundle_label].views
  local _index
  for index, path in ipairs(paths) do
    if file == path then
      _index = index
      break
    end
  end
  assert(_index, "_index does not exists on bundle view.")

  local temp
  if direction then
    temp = _index + 1
    if temp > #paths then temp = 1 end
  else
    temp = _index - 1
    if temp < 1 then temp = #paths end
  end
  root.bundles[bundle_label].views = Util.swap(paths, _index, temp)
  if save then State.save() end
  return root.bundles[bundle_label]
end

function M.history(root_path, bundle_label, disable_history, maximum_history)
  local root = State._roots[root_path]
  if root and not root:empty() then
    bundle_label = vim.F.if_nil(bundle_label, root.main)
    local bundle = root.bundles[bundle_label]
    if bundle and not bundle:empty() then
      bundle.disable_history = disable_history
      bundle.maximum_history = maximum_history
    end
  end
end

return M
