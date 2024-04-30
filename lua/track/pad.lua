local Pad = {}
Pad.__index = Pad
setmetatable(Pad, {
  __call = function(class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

local A = vim.api
local V = vim.fn
local if_nil = vim.F.if_nil

local util = require("track.util")
local utils = require("telescope.utils")
local config = require("track.config").get()
local strings = require("plenary.strings")

function Pad:_new(fields)
  local field_types = type(fields)
  assert(field_types == "table", "expected: fields: table found: " .. field_types)

  self._opts = fields
  self.mappings = if_nil(fields.mappings, {})
  self.entries = if_nil(fields, {})

  self.bundle = if_nil(fields.bundle, select(2, util.root_and_bundle()))
  self.buffer = A.nvim_create_buf(false, false)
  self.namespace = A.nvim_create_namespace("TrackPad")
  self.window = nil

  self.config = fields.config
  self.config.title = string.format(" %s ", strings.truncate(self.bundle.label, math.floor(self.config.width / 2)))
  self.config.row = (vim.o.lines - self.config.height - 2) / 2
  self.config.col = (vim.o.columns - self.config.width) / 2

  A.nvim_buf_set_option(self.buffer, "filetype", "track")
  A.nvim_buf_set_name(self.buffer, self.bundle.label)
  A.nvim_buf_set_option(self.buffer, "indentexpr", "3")

  for mode, maps in pairs(self.mappings) do
    for key, action in pairs(maps) do
      vim.keymap.set(mode, key, function() action(self) end, { silent = true, buffer = self.buffer })
    end
  end

  self:apply_entries()
  self._autocmds = {}
  if fields.path_display then
    self._autocmds.insert = A.nvim_create_autocmd({ "InsertLeave", "InsertEnter" }, {
      buffer = self.buffer,
      group = require("track").TRACK_GROUP,
      callback = function() self:apply_entries() end,
    })
  end

  if fields.auto_resize then
    self._autocmds.resized = A.nvim_create_autocmd("VimResized", {
      buffer = self.buffer,
      group = require("track").TRACK_GROUP,
      callback = function()
        if not self:hidden() then
          self.config.row = (vim.o.lines - self.config.height - 2) / 2
          self.config.col = (vim.o.columns - self.config.width) / 2
          A.nvim_win_set_config(self.window, self.config)
        end
      end,
    })
  end

  self._NAME = "pad"
end

function Pad.make_entry(index, view_mark, opts)
  local entry = { index = index, mark = view_mark }
  local icon, group = util.get_icon(entry.mark, config.icons, opts)
  entry.icon = icon
  entry.group = group

  entry.transformed = view_mark.path
  if A.nvim_get_mode().mode ~= "n" then entry.transformed = utils.transform_path(opts, view_mark.absolute) end
  entry.display = (opts.disable_devicons and "" or (icon .. " ")) .. entry.transformed
  entry.ranges = { { { 0, 3 }, entry.group }, "TrackPadEntry" }
  return entry
end

function Pad:apply_entries()
  Pad:clean()
  Pad:clear()
  local view_marks = self.bundle.views()
  for index, view_mark in ipairs(view_marks) do
    local entry = Pad.make_entry(index, view_mark, self._opts)
    if entry.mark.absolute == self._focused then entry.ranges[2] = entry.ranges[2] .. "Focused" end
    table.insert(self.entries, index, entry)
    A.nvim_buf_set_lines(self.buffer, index - 1, index - 1, true, { entry.display })
    A.nvim_buf_add_highlight(
      self.buffer,
      self.namespace,
      entry.ranges[1][2],
      index - 1,
      entry.ranges[1][1][1],
      entry.ranges[1][1][2]
    )
    A.nvim_buf_add_highlight(
      self.buffer,
      self.namespace,
      entry.ranges[2],
      index - 1,
      entry.ranges[1][1][2] + 1,
      entry.ranges[1][1][2] + 1 + #entry.transformed
    )
  end
end

function Pad:sync()
  self.bundle:clear()
  for _, entry in ipairs(self.entries) do
    self.bundle:add_mark(entry.mark)
  end
end

function Pad:hidden() return not self.window or not A.nvim_win_is_valid(self.window) end

function Pad:open()
  if not self:hidden() then return end
  self._focused = V.fnamemodify(V.bufname(), ":p")
  self.window = A.nvim_open_win(self.buffer, true, self.config)
  A.nvim_win_set_option(self.window, "winhighlight", "FloatTitle:TrackPadTitle,FloatBorder:NormalFloat")
  A.nvim_win_set_option(self.window, "number", true)
  A.nvim_win_set_option(self.window, "cursorline", true)
  self:apply_entries()
end

function Pad:close()
  if self:hidden() then return end
  A.nvim_win_close(self.window, true)
  self.window = nil
end

function Pad:toggle()
  if self:hidden() then
    self:open()
    return
  end
  self:close()
end

function Pad:clean(...)
  local line_start, line_end = ...
  if not line_start then line_start = 0 end
  if not line_end then line_end = -1 end
  A.nvim_buf_clear_namespace(self.buffer, self.namespace, line_start, line_end)
end

function Pad:clear()
  A.nvim_buf_set_lines(self.buffer, 0, -1, true, {})
end

return Pad
