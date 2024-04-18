---@diagnostic disable: unused-local, missing-fields, undefined-field
local M = {}
M.pads = {}

local Config = require("track.config")
local State = require("track.state")
local Util = require("track.util")
State.load()

local A = vim.api
local U = vim.loop
local V = vim.fn
local if_nil = vim.F.if_nil

-- Helpers {{{
local function is_pad_hidden(pad)
  return not pad.window and pad.buffer and A.nvim_buf_is_valid(pad.buffer)
end

local function create_pad_window(buffer, bundle, opts)
  local window = A.nvim_open_win(buffer, true, opts.window)
  A.nvim_win_set_option(window, "winhighlight", "FloatTitle:TrackPadTitle,FloatBorder:NormalFloat")
  A.nvim_win_set_option(window, "number", true)
  return window
end

local function create_pad_buffer(bundle)
  local buffer = A.nvim_create_buf(false, false)
  A.nvim_buf_set_option(buffer, "filetype", "track_bundle")
  A.nvim_buf_set_name(buffer, bundle.label)
  return buffer
end

local function resolve_bundle_opt(bundle, opts)
  opts = if_nil(opts, {})
  if not bundle then
    local root = State._roots[if_nil(opts.root_path, V.getcwd())]
    if not root then return end
    return root:get_main_bundle()
  elseif bundle._NAME == "root" then
    return bundle:get_main_bundle()
  elseif bundle._NAME == "bundle" then
    return bundle
  end
end

local function sync_with_bundle(pad, bundle, save)
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
-- }}}

function M.open_bundle(opts, bundle)
  opts = if_nil(opts, {})
  local window_opts = Config.get_pad().window
  opts = Config.extend_pad({
    window = {
      row = (vim.o.lines - window_opts.height - 2) / 2,
      col = (vim.o.columns - window_opts.width) / 2,
      title = string.format(" Bundle (%s) ", bundle.label),
    },
  })

  bundle = resolve_bundle_opt(bundle, opts)
  if not bundle then return end

  local pad = if_nil(M.pads[bundle.label], {})
  if is_pad_hidden(pad) then
    pad.window = create_pad_window(pad.buffer, bundle, opts)
  else
    pad.buffer = create_pad_buffer(bundle)
    pad.window = create_pad_window(pad.buffer, bundle, opts)
    vim.keymap.set("n", "q", function() M.hide_bundle(opts, bundle) end, { buffer = pad.buffer })
    vim.keymap.set("n", "<C-S>", State.save, { buffer = pad.buffer })
    vim.keymap.set("n", "<cr>", function()
      local line = A.nvim_win_get_cursor(pad.window)[1] - 1
      local line_content = A.nvim_buf_get_lines(pad.buffer, line, line + 1, true)[1]

      M.hide_bundle(opts, bundle)
      opts.hooks.on_choose(vim.trim(line_content), bundle.views[line + 1])
    end, { buffer = pad.buffer })
    M.pads[bundle.label] = pad
  end

  A.nvim_buf_set_lines(pad.buffer, 0, -1, false, bundle.views)
  if opts.serial_maps then
    for line, view in ipairs(bundle.views) do
      vim.keymap.set("n", tostring(line), function()
        M.hide_bundle(opts, bundle)
        opts.hooks.on_serial_choose(view, line)
      end, { buffer = pad.buffer })
    end
  end
end

function M.close_bundle(opts, bundle)
  opts = if_nil(opts, {})
  bundle = resolve_bundle_opt(bundle)
  if not bundle then return end

  local pad = M.pads[bundle.label]
  if not pad then return end

  sync_with_bundle(pad, bundle, true)
  if A.nvim_win_is_valid(pad.window) then A.nvim_win_close(pad.window, true) end
  if A.nvim_buf_is_valid(pad.buffer) then A.nvim_buf_delete(pad.buffer, { force = true }) end
  M.pads[bundle.label] = nil
end

function M.hide_bundle(opts, bundle)
  opts = if_nil(opts, {})
  bundle = resolve_bundle_opt(bundle)
  if not bundle then return end

  local pad = M.pads[bundle.label]
  if not pad then return end
  if is_pad_hidden(pad) then return end

  A.nvim_win_hide(pad.window)
  sync_with_bundle(pad, bundle, true)
  M.pads[bundle.label].window = nil
end

function M.toggle_bundle(opts, bundle)
  opts = if_nil(opts, {})
  bundle = resolve_bundle_opt(bundle)
  if not bundle then return end

  local pad = M.pads[bundle.label]
  if pad then
    if is_pad_hidden(pad) then
      M.open_bundle(opts, bundle)
    else
      M.hide_bundle(bundle)
    end
  else
    M.open_bundle(opts, bundle)
  end
end

return M
