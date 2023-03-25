local M = {}

local Config = require("track.config").get()
local Path = require("plenary.path")
local Log = require("plenary.log")

local Root = require("track.containers.root")
local Mark = require("track.containers.mark")
local Bundle = require("track.containers.bundle")

-- TODO: Set __call metatable to get root list.
M._roots = {}
M._loaded = false
M._savepath = Path:new(Config.savepath)
M._log = Log.new(Config.log)

local function parse_marks(marks)
  local store = {}
  for path, mark in pairs(marks) do
    store[path] = Mark:new({
      path = mark.path,
      label = mark.label,
    })
  end
  return store
end

local function parse_bundles(bundles)
  local store = {}
  for label, bundle in pairs(bundles) do
    store[label] = Bundle:new({
      label = bundle.label,
      views = bundle.views,
      marks = parse_marks(bundle.marks),
    })
  end
  return store
end

function M.wipe() M._roots = {} end

function M.loadsave(action, savepath, on_load)
  if not M._savepath:exists() then
    M._log.warn("Config.savepath does not exist.")
    return
  end
  savepath = Path:new(savepath)
  local data = vim.trim(savepath:read())
  if data == "" then return end

  local roots = vim.json.decode(data)
  if action == "wipe" then M.wipe() end
  for path, root in pairs(roots) do
    M._roots[path] = Root:new({
      path = root.path,
      label = root.label,
      links = root.links,
      main = root.main,
      bundles = parse_bundles(root.bundles),
    })
    M._roots[path]._stashed = root._stashed
  end
  if on_load then on_load() end
end

function M.reload(on_reload) M.loadsave("extend", M._savepath.filename, on_reload) end

function M.load(on_load)
  if M._loaded then return end
  M._loaded = true
  M.reload(on_load)
end

function M.save(before_save, on_save)
  if not M._savepath:exists() then
    M._log.info("Config.savepath does not exist. Creating...")
    M._savepath:touch({ parents = true })
  end

  if before_save and before_save() then return end
  local encoded = vim.json.encode(M._roots)
  M._savepath:write(encoded, "w")
  if on_save then on_save() end
end

function M.rm(clean)
  if clean then
    M._savepath:write("{}", "w")
    return
  end
  M._savepath:rm()
end

return M
