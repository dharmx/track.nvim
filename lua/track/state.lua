local M = {}

local Config = require("track.config").get()
local Path = require("plenary.path")
local Log = require("plenary.log")

local Root = require("track.containers.root")
local Mark = require("track.containers.mark")
local Bundle = require("track.containers.bundle")

---Main state of track.nvim. It tracks all roots.
---@type table<string, Root>
---@private
M._roots = {}

---Add the `__call` metatable to `M._roots` table.
---@param roots table<string, Root>
---@private
function M._callize_roots(roots)
  setmetatable(roots, {
    ---Returns either a list of root paths or, a list of `Root` instances.
    ---@param self table<string, Root> The a map of `string: Root`.
    ---@param action "string"|"instance" return a list of either Root.path[] or, Root[].
    ---@return string[]|Root[]
    __call = function(self, action)
      if action == "string" then return vim.tbl_keys(self) end
      return vim.tbl_values(self)
    end,
  })
end
M._callize_roots(M._roots)


---If `TrackConfig.savepath` has been loaded (merged) into `M._roots` then `true` else `false`.
---@private
M.loaded = false
---@private
M._log = Log.new(Config.log) -- TODO: Please, FTLOG. Use this. Logging is seriously underrated.

---@type Path
local savepath = Path:new(Config.savepath)

---Clear all recorded roots. This will clear histories as well.
function M.wipe()
  M._roots = {}
  M._callize_roots(M._roots)
end

-- Roots parser helpers. {{{

---Helper that parses marks and wraps raw mark fields into a `Mark` instance. As a side-effect any extra values sneaked in will be ignored.
---@param marks {path: string, label: string}[]
---@return Mark[]
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

---Helper that parsers bundles and wraps raw bundle into a `Bundle` instance.
---@param bundles {label: string, disable_history?: boolean, maximum_history: number, marks: table<string, Mark>, views: Mark[]}[]
---@return Bundle[]
local function parse_bundles(bundles)
  local store = {}
  for label, bundle in pairs(bundles) do
    store[label] = Bundle:new({
      label = bundle.label,
      disable_history = bundle.disable_history,
      maximum_history = bundle.maximum_history,
    })

    store[label].marks = parse_marks(bundle.marks)
    store[label].views = bundle.views

    store[label]:_callize_views()
    store[label]:_callize_marks()
  end
  return store
end

-- }}}

-- loadsave? Really? Impeccable naming sense.
-- Interpret this as load_savefile. _ triggers my OCD.

---Load a save file. The decoded JSON will be merged/overwritten to `M._roots` table.
---@param action "wipe"|"extend" Wipe will clear `M._roots` and then assign the decoded values. Merge will extend existing `M._roots` value.
---@param loadpath string Path to save file that should be loaded.
---@param on_load? function Run this callback after the save file is loaded.
function M.loadsave(action, loadpath, on_load)
  if not savepath:exists() then
    M._log.warn("Config.savepath does not exist.")
    return
  end

  ---@diagnostic disable-next-line: cast-local-type
  loadpath = Path:new(loadpath)
  local data = vim.trim(loadpath:read()) -- strip leading and trailing whitespaces
  if data == "" then return end

  -- action == "wipe" will clear the current state (M._roots)
  -- and then parse the supplied savefile
  -- otherwise it will be merged with current state (maybe I should remove this?)
  local roots = vim.json.decode(data)
  if action == "wipe" then M.wipe() end
  assert(action == "extend" or action == "wipe", "action: string[extend|wipe]")

  for path, root in pairs(roots) do
    M._roots[path] = Root:new({
      path = root.path,
      label = root.label,
      links = root.links,
      main = root.main,
    })
    M._roots[path].bundles = parse_bundles(root.bundles) -- delegate to helper
    M._roots[path]:_callize_bundles()

    -- private
    M._roots[path].stashed = root.stashed
    M._roots[path].previous = root.previous
  end
  if on_load then on_load() end
end

---Reload and merge `Config.savepath` path into `M._roots` again.
---@param on_reload? function Callback that gets called after reload.
function M.reload(on_reload)
  M.loadsave("extend", savepath.filename, on_reload)
end

-- you will see this called practically everywhere in core.lua

---Load and assign `Config.savepath` path into `M._roots`. This can only be called once.
---@param on_load? function Callback that gets called after load.
function M.load(on_load)
  if M._loaded then return end
  M._loaded = true -- allow calling this only once.
  M.reload(on_load)
end

---Save current state of `M._roots` into `Config.savepath`.
---@param before_save? function Callback that is called exactly before changes are written in `Config.savepath`.
---@param on_save? function Callback that is called after changes are written to `Config.savepath`.
function M.save(before_save, on_save)
  if not savepath:exists() then
    M._log.info("M.save(): Config.savepath does not exist. Creating...")
    savepath:touch({ parents = true })
  end

  -- before_save seems too much?
  if before_save and before_save() then return end
  local encoded = vim.json.encode(M._roots)
  savepath:write(encoded, "w")
  if on_save then on_save() end
end

---Remove or clear the save file.
---@param clean? boolean
function M.rm(clean)
  if clean then
    -- empty JSON object
    savepath:write("{}", "w")
    return
  end
  savepath:rm()
end

return M
