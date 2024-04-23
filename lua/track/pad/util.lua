local M = {}

local A = vim.api
local if_nil = vim.F.if_nil

local Util = require("track.util")
local Core = require("track.core")
local State = require("track.state")
local Root = require("track.containers.root")

function M.is_pad_hidden(pad) return not pad.window and pad.buffer and A.nvim_buf_is_valid(pad.buffer) end

function M.new_window(buffer, _, opts)
  local window = A.nvim_open_win(buffer, true, opts.window)
  A.nvim_win_set_option(window, "winhighlight", "FloatTitle:TrackPadTitle,FloatBorder:NormalFloat")
  A.nvim_win_set_option(window, "number", true)
  A.nvim_win_set_option(window, "cursorline", true)
  return window
end

function M.gen_icon_from_line(line, content_group)
  content_group = if_nil(content_group, "")
  local ok, devicons = pcall(require, "nvim-web-devicons")
  assert(ok, "nvim-web-devicons needs to be installed") -- TODO: make this optional

  local trimmed = vim.trim(line)
  local icon, group = devicons.get_icon(vim.fs.basename(trimmed))
  if not icon or not group then
    icon, group = devicons.get_default_icon().icon, "DevIconDefault"
  end
  return {
    value = string.format("%s %s", icon, trimmed),
    icon = { group = group, range = { start = 0, finish = #icon } },
    content = { group = content_group, range = { start = 1 + #icon, finish = #trimmed + 1 + #icon } },
  }
end

function M.parse_line(line)
  local icon, sep, content = line:match("^([^%s]+)(%s+)(.+)$")
  if not icon then return end
  return {
    value = line,
    icon = icon,
    content = content,
  }
end

function M.entrify_line(pad, index, line, check_icon)
  line = vim.trim(line)
  if line == "" then return end
  local parsed = M.parse_line(line)
  if parsed then
    if not check_icon then return end
    line = parsed.content
  end

  local style = M.gen_icon_from_line(line)
  local icon = style.icon
  local content = style.content

  A.nvim_buf_set_lines(pad.buffer, index, index, false, { style.value })
  A.nvim_buf_add_highlight(pad.buffer, pad.namespace, icon.group, index, icon.range.start, icon.range.finish)
  A.nvim_buf_add_highlight(pad.buffer, pad.namespace, content.group, index, content.range.start, content.range.finish)
end

function M.entrify_lines(pad, check_icon)
  local lines = A.nvim_buf_get_lines(pad.buffer, 0, -1, false)
  A.nvim_buf_set_lines(pad.buffer, 0, -1, false, {})
  for serial, line in ipairs(lines) do
    M.entrify_line(pad, serial - 1, line, check_icon)
  end
end

function M.entrify_current_line(pad, check_icon)
  if A.nvim_get_current_win() ~= pad.window then return end
  M.entrify_line(pad, A.nvim_win_get_cursor(pad.window)[1] - 1, A.nvim_get_current_line(), check_icon)
end

function M.new_buffer(bundle)
  local buffer = A.nvim_create_buf(false, false)
  A.nvim_buf_set_option(buffer, "filetype", "track_bundle")
  A.nvim_buf_set_name(buffer, bundle.label)
  A.nvim_buf_set_option(buffer, "indentexpr", "2")
  return buffer
end

function M.resolve_bundle_opt(bundle, opts)
  opts = if_nil(opts, {})
  if not bundle then
    local root_path = if_nil(opts.root_path, Core.root_path)
    local root = State._roots[root_path]
    if root then
      return root:get_main_bundle()
    elseif opts.auto_create then
      root = Root(root_path)
      State._roots[root_path] = root
      return root:get_main_bundle()
    end
  elseif bundle._NAME == "root" then
    return bundle:get_main_bundle()
  elseif bundle._NAME == "bundle" then
    return bundle
  end
end

function M.sync_with_bundle(pad, bundle, save)
  local lines = A.nvim_buf_get_lines(pad.buffer, 0, -1, false)
  bundle:clear()
  for _, line in ipairs(lines) do
    local entry = M.parse_line(line)
    if entry then
      local mark = bundle:add_mark(entry.content)
      if mark then
        mark.type = Util.filetype(entry.content)
        if mark.type == "term" then
          local path_cmd = vim.split(mark.path, ":", { plain = true })
          bundle:change_mark_path(mark, string.format("term:%s", path_cmd[#path_cmd]))
        end
      end
    end
  end
  if save then State.save() end
end

function M.apply_serial_mappings(pad, bundle, on_serial)
  -- reset
  local maps = A.nvim_buf_get_keymap(pad.buffer, "n")
  for _, map in ipairs(maps) do
    if map.lhs:match("^%d+$") then A.nvim_buf_del_keymap(pad.buffer, "n", map.lhs) end
  end

  local lines = A.nvim_buf_get_lines(pad.buffer, 0, -1, false)
  for serial, line in ipairs(lines) do
    local entry = M.parse_line(line)
    if entry then
      vim.keymap.set(
        "n",
        tostring(serial),
        function() on_serial(entry.content, serial, bundle) end,
        { buffer = pad.buffer }
      )
    end
  end
end

return M
