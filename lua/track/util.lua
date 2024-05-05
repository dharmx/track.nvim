local M = {}

local U = vim.loop
local A = vim.api

---Dummy function that does noting.
function M.mute() end

function M.open_entry(entry)
  if entry.value.type == "https" or entry.value.type == "http" then
    vim.fn.jobstart({ "xdg-open", entry.value.path }, { detach = true })
    return
  end
  vim.cmd("confirm edit " .. entry.value.path)
end

---@return string
function M.filetype(uri)
  local uri_type = vim.F.if_nil(uri:match("^(%w+)://"), "file")
  if uri_type == "file" then
    uri = vim.fs.normalize(uri)
    local stat, _, e = U.fs_stat(uri)
    if e == "EACCES" then
      return "no_access"
    elseif e == "ENOENT" then
      return "no_exists"
    else
      return stat and stat.type or "error"
    end
  end
  return vim.trim(uri_type) == "" and "default" or uri_type
end

function M.transform_term_uri(uri)
  return (uri:match("^term://.+//%d+:(.+)$") or uri:match("^term://.+//(.+)$") or uri:match("term://(.+)")):gsub(
    "\\|",
    "|"
  )
end

function M.transform_man_uri(uri) return uri:match("man://(.+)") end

function M.transform_site_uri(uri) return uri:match("https?://w?w?w?%.?(.+)") end

function M.get_cwd_from_term_uri(uri)
  local working = uri:match("^term://(.+)//%d+:.+$")
  working = working or uri:match("^term://(.+)//.+$")
  return working and vim.fs.normalize(working) or M.cwd()
end

---Get cwd. Like really.
---@return string
function M.cwd() return (U.cwd()) or vim.fn.getcwd() or vim.env.PWD end

function M.get_icon(mark, extra_icons, opts)
  local icon, group = "", ""
  if opts.disable_devicons then return icon end

  if mark.type == "term" then
    icon, group = extra_icons.terminal, "TrackViewsTerminal"
  elseif mark.type == "man" then
    icon, group = extra_icons.manual, "TrackViewsManual"
  elseif mark.type == "directory" then
    icon, group = extra_icons.directory, "TrackViewsDirectory"
  elseif mark.type == "http" or mark.type == "https" then
    icon, group = extra_icons.site, "TrackViewsSite"
  else
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if not ok then
      icon, group = extra_icons.file, "TrackViewsFile"
    else
      if not devicons.has_loaded() then devicons.setup() end
      icon, group = devicons.get_icon(vim.fs.basename(mark.path))
      if not icon or not group then
        icon, group = devicons.get_default_icon().icon, "DevIconDefault"
      end
    end
  end

  if opts.color_devicons ~= false then return icon, group end
  assert(A.nvim_strwidth(icon) < 2, "icon length should be < 2")
  return icon, ""
end

function M.clean_term_uri(uri)
  local trimmed = vim.trim(uri)
  local working = trimmed:match("^term://(.+)//%d+:.*$")
  if working then
    working = vim.fs.normalize(working)
    trimmed = trimmed:gsub("^(term://)(.+)(//)%d+:(.*)$", "%1" .. working .. "%3%4")
  else
    trimmed = trimmed:gsub("^(term://.+//)%d+:(.*)$", "%1%2")
  end
  trimmed = trimmed:gsub("|", "\\|")
  return trimmed
end

-- TODO: Allow opts.root_path and opts.bundle_label to be a function.
function M.root_and_bundle(opts, force)
  opts = vim.F.if_nil(opts, {})
  opts = require("track.config").extend(opts)
  local bundle_label = opts.bundle_label
  local root_path = opts.root_path ~= true and opts.root_path or M.cwd()
  assert(type(root_path) == "string", "Config.root_path needs to be string")

  local state = require("track.state")
  local bundle = nil
  local root = state._roots[root_path]
  if root and bundle_label == true then
    bundle = root:get_main_bundle()
  elseif type(bundle_label) == "string" then
    bundle = root.bundles[bundle_label]
  elseif force then
    if not root then
      local Root = require("track.containers.root")
      local new_root = Root(root_path)
      state._roots[root_path] = new_root
      root = new_root
    end
    bundle = root:get_main_bundle()
  end
  return root, bundle
end

function M.contains(patterns, item)
  for k, v in pairs(patterns) do
    local k_type = type(k)
    if k_type == "string" then
      if v then
        if item:match(k) then return true end
      end
    elseif k_type == "number" then
      if item:match(v) then return true end
    end
  end
  return false
end

return M
