local M = {}
M.pads = {}

local PadUtil = require("track.pad.util")
local Config = require("track.config")
local State = require("track.state")
local Util = require("track.util")

local strings = require("plenary.strings")
State.load()

local A = vim.api
local U = vim.loop
local V = vim.fn
local if_nil = vim.F.if_nil

function M.open_bundle(opts, bundle)
  opts = Config.extend_pad(opts)
  opts.window.title = string.format(" %s ", strings.truncate(bundle.label, math.floor(opts.window.width / 2)))
  opts.window.row = (vim.o.lines - opts.window.height - 2) / 2
  opts.window.col = (vim.o.columns - opts.window.width) / 2
  bundle = PadUtil.resolve_bundle_opt(bundle, opts)

  if not bundle then return end
  local pad = if_nil(M.pads[bundle.label], {})
  if PadUtil.is_pad_hidden(pad) then
    pad.window = PadUtil.new_window(pad.buffer, bundle, opts)
  else
    pad.buffer = PadUtil.new_buffer(bundle)
    pad.window = PadUtil.new_window(pad.buffer, bundle, opts)
    pad.namespace = A.nvim_create_namespace("track_pad_" .. bundle.label)

    vim.keymap.set("n", "q", function() M.hide_bundle(opts, bundle) end, { buffer = pad.buffer })
    -- vim.keymap.set("n", "<c-s>", function()
    --   PadUtil.entrify_lines(pad, opts.check_icon)
    --   PadUtil.sync_with_bundle(pad, bundle, true)
    -- end, { buffer = pad.buffer })

    vim.keymap.set("n", "<cr>", function()
      if A.nvim_get_current_win() ~= pad.window then return end
      local entry = PadUtil.parse_line(A.nvim_get_current_line())
      if not entry then return end

      if entry then
        local index = A.nvim_win_get_cursor(pad.window)[1] + 1
        M.hide_bundle(opts, bundle)
        opts.hooks.on_choose(entry.content)
      end
    end, { buffer = pad.buffer })

    pad.auto_resize = A.nvim_create_autocmd("VimResized", {
      buffer = pad.buffer,
      callback = function()
        if not PadUtil.is_pad_hidden(pad) then
          opts.window.row = (vim.o.lines - opts.window.height - 2) / 2
          opts.window.col = (vim.o.columns - opts.window.width) / 2
          A.nvim_win_set_config(pad.window, opts.window)
        end
      end,
    })

    M.pads[bundle.label] = pad
  end
  A.nvim_buf_set_lines(pad.buffer, 0, -1, false, bundle.views)
  PadUtil.entrify_lines(pad, opts.check_icon)

  if opts.serial_maps then
    PadUtil.apply_serial_mappings(pad, bundle, function(...)
      M.hide_bundle(opts, bundle)
      opts.hooks.on_serial_choose(...)
    end)
  end
end

function M.hide_bundle(opts, bundle)
  opts = Config.extend_pad(if_nil(opts, {}))
  bundle = PadUtil.resolve_bundle_opt(bundle, opts)
  if not bundle then return end

  local pad = M.pads[bundle.label]
  if not pad then return end
  if PadUtil.is_pad_hidden(pad) then return end

  A.nvim_win_hide(pad.window)
  PadUtil.sync_with_bundle(pad, bundle, opts.save_on_hide)
  M.pads[bundle.label].window = nil
end

function M.toggle_bundle(opts, bundle)
  opts = Config.extend_pad(if_nil(opts, {}))
  bundle = PadUtil.resolve_bundle_opt(bundle, opts)
  if not bundle then return end

  local pad = M.pads[bundle.label]
  if pad then
    if PadUtil.is_pad_hidden(pad) then
      M.open_bundle(opts, bundle)
    else
      M.hide_bundle(bundle)
    end
  else
    M.open_bundle(opts, bundle)
  end
end

function M.close_bundle(opts, bundle)
  opts = Config.extend_pad(if_nil(opts, {}))
  bundle = PadUtil.resolve_bundle_opt(bundle, opts)
  if not bundle then return end

  local pad = M.pads[bundle.label]
  if not pad then return end

  PadUtil.sync_with_bundle(pad, bundle, opts.save_on_close)
  A.nvim_buf_clear_namespace(pad.buffer, pad.namespace, 0, -1)
  if pad.window and A.nvim_win_is_valid(pad.window) then A.nvim_win_close(pad.window, true) end
  if pad.buffer and A.nvim_buf_is_valid(pad.buffer) then A.nvim_buf_delete(pad.buffer, { force = true }) end
  M.pads[bundle.label] = nil
end

return M
