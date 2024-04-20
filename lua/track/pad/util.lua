---@diagnostic disable: missing-fields
local M = {}

local A = vim.api
local if_nil = vim.F.if_nil

local Util = require("track.util")
local Core = require("track.core")
local State = require("track.state")
local Root = require("track.containers.root")

function M.is_pad_hidden(pad)
  return not pad.window and pad.buffer and A.nvim_buf_is_valid(pad.buffer)
end

function M.create_pad_window(buffer, _, opts)
  local window = A.nvim_open_win(buffer, true, opts.window)
  A.nvim_win_set_option(window, "winhighlight", "FloatTitle:TrackPadTitle,FloatBorder:NormalFloat")
  A.nvim_win_set_option(window, "number", true)
  A.nvim_win_set_option(window, "cursorline", true)
  return window
end

function M.create_pad_buffer(bundle)
  local buffer = A.nvim_create_buf(false, false)
  A.nvim_buf_set_option(buffer, "filetype", "track_bundle")
  A.nvim_buf_set_name(buffer, bundle.label)
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
  local raw_lines = A.nvim_buf_get_lines(pad.buffer, 0, -1, false)
  bundle:clear()
  for _, line in ipairs(raw_lines) do
    local trimmed = vim.trim(line)
    if trimmed ~= "" then
      local mark = bundle:add_mark(trimmed)
      if mark then
        mark.type = Util.filetype(trimmed)
        if mark.type == "term" then
          local path_cmd = vim.split(mark.path, ":", { plain = true })
          bundle:change_mark_path(mark, string.format("term:%s", path_cmd[#path_cmd]))
        end
      end
    end
  end
  if save then State.save() end
end

function M.apply_serial_maps(pad, bundle, on_serial)
  for line, view in ipairs(bundle.views) do
    vim.keymap.set("n", tostring(line), function()
      on_serial(view, line, bundle)
    end, { buffer = pad.buffer })
  end
end

return M
