local M = {}
local state = require("track.state")
local util = require("track.util")
local Root = require("track.containers.root")

-- TODO: Pass cwd instead of calling it.

function M.mark(root_path, file, bundle_label, save)
  assert(root_path, "root_path arg needs to be present.")
  assert(file, "file cannot be nil.")
  file = util.filter_path(file) -- remove // and trailing /
  state.load()

  -- create a root if it does not exist
  local root = state._roots[root_path]
  if not root then
    local new_root = Root:new({ path = root_path })
    state._roots[root_path] = new_root
    root = new_root
  end

  -- this part makes sure that root.main does not stay empty
  -- create a default bundle if not bundle_label is supplied
  if not bundle_label then
    -- create_default_bundle sets root.main = "main"
    if root:empty() then root:create_default_bundle() end
    bundle_label = root.main
    if root.bundles[bundle_label].marks[file] then return end
  elseif not root.bundles[bundle_label] then
    root:new_bundle(bundle_label)
  end
  root.bundles[bundle_label]:add_mark(file)
  if save then state.save() end
end

function M.unmark(root_path, file, bundle_label, save)
  assert(root_path, "root_path arg needs to be present.")
  file = util.filter_path(file)
  state.load()

  local root = state._roots[root_path]
  if not root then return end

  -- root.main being null implies that there are no bundles in root
  -- which also implies that there are not any marks too
  if root:empty() then return end
  if not bundle_label then bundle_label = root.main end
  if not root.bundles[bundle_label] or not root.bundles[bundle_label].marks[file] then return end
  root.bundles[bundle_label]:remove_mark(file)
  if save then state.save() end
end

function M.stash(root_path, save)
  assert(root_path, "root_path arg needs to be present.")
  state.load()
  local root = state._roots[root_path]
  if not root or root:empty() then return end
  root:stash_bundle()
  if save then state.save() end
end

function M.restore(root_path, save)
  assert(root_path, "root_path arg needs to be present.")
  state.load()
  local root = state._roots[root_path]
  if not root or root:empty() then return end
  root:restore_bundle()
  if save then state.save() end
end

function M.delete(root_path, bundle_label, save)
  assert(root_path, "root_path cannot be nil.")
  assert(bundle_label, "bundle_label cannot be nil.")
  state.load()
  local root = state._roots[root_path]
  if not root or root:empty() then return end
  root:delete_bundle(bundle_label)
  if save then state.save() end
end

function M.move(root_path, file, direction, bundle_label, save)
  assert(root_path, "root_path arg needs to be present.")
  assert(file, "file cannot be nil.")
  assert(bundle_label, "bundle_label cannot be nil.")
  file = util.filter_path(file)
  assert(type(direction) == "boolean", "direction_path must be boolean.")
  state.load()

  local root = state._roots[root_path]
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
  root.bundles[bundle_label].views = util.swap(paths, _index, temp)
  if save then state.save() end
  return root.bundles[bundle_label]
end

function M.view(root_path, bundle_label)
  assert(root_path, "root_path arg needs to be present.")
  state.load()
  local root = state._roots[root_path]
  if not root or root:empty() then return {} end
  bundle_label = vim.F.if_nil(bundle_label, root.main)
  if not root.bundles[bundle_label] then return {} end
  return root.bundles[bundle_label].views
end

return M
