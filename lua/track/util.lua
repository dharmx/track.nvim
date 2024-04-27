local M = {}

---Dummy function that does noting.
function M.mute() end

function M.open_entry(entry)
  if entry.value.type == "https" or entry.value.type == "http" then
    vim.fn.jobstart("xdg-open " .. entry.value.path, { detach = true })
    return
  end
  vim.cmd("confirm edit " .. entry.value.path)
end

---@return string
function M.filetype(uri)
  local uri_type = vim.F.if_nil(string.match(uri, "^(%w+)://"), "file")
  if uri_type == "file" then
    local stat, _, e = vim.loop.fs_stat(uri)
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
  return uri:match("^term://.+//%d+:(.+)$") or uri:match("^term://.+//(.+)$") or uri:match("term://(.+)")
end

function M.get_cwd_from_term_uri(uri)
  local working = uri:match("^term://(.+)//%d+:.+$")
  working = working or uri:match("^term://(.+)//.+$")
  return working and vim.fs.normalize(working) or M.cwd()
end

---Get cwd. Like really.
---@return string
function M.cwd()
  return (vim.loop.cwd()) or vim.fn.getcwd() or vim.env.PWD
end

function M.get_icon(mark, opts)
  local icon, group = "", nil
  if opts.disable_devicons then return icon end

  if mark.type == "term" then
    icon, group = opts.icons.terminal, "TrackViewsTerminal"
  elseif mark.type == "man" then
    icon, group = opts.icons.manual, "TrackViewsManual"
  elseif mark.type == "directory" then
    icon, group = opts.icons.directory, "TrackViewsDirectory"
  elseif mark.type == "http" or mark.type == "https" then
    icon, group = opts.icons.site, "TrackViewsSite"
  else
    local ok, devicons = pcall(require, "nvim-web-devicons")
    if not ok then
      icon, group = opts.icons.file, "TrackViewsFile"
    else
      if not devicons.has_loaded() then devicons.setup() end
      icon, group = devicons.get_icon(vim.fs.basename(mark.path))
      if not icon or not group then
        icon, group = devicons.get_default_icon().icon, "DevIconDefault"
      end
    end
  end

  if opts.color_devicons ~= false then return icon, group end
  return icon, nil
end

return M
