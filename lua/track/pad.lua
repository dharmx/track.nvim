local Pad = {}
Pad.__index = Pad
setmetatable(Pad, {
  __call = function(class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    return self
  end,
})

-- TODO: Handle URI entries

local A = vim.api
local V = vim.fn
local if_nil = vim.F.if_nil

local Mark = require("track.containers.mark")
local util = require("track.util")
local state = require("track.state")
local config = require("track.config").get()
local strings = require("plenary.strings")

function Pad:_new(fields)
  local field_types = type(fields)
  assert(field_types == "table", "expected: fields: table found: " .. field_types)

  self._opts = fields
  self.mappings = if_nil(fields.mappings, {})
  self.entries = if_nil(fields, {})
  self.spacing = fields.spacing

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

  for mode, maps in pairs(self.mappings) do
    for key, action in pairs(maps) do
      vim.keymap.set(mode, key, function() action(self) end, { silent = true, buffer = self.buffer })
    end
  end

  if fields.auto_resize then
    A.nvim_create_autocmd("VimResized", {
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

  entry.display = (opts.disable_devicons and "" or (icon .. string.rep(" ", opts.spacing))) .. entry.mark.path
  entry.range = { { { 0, #icon }, entry.group }, "TrackPadEntry" }
  return entry
end

-- stylua: ignore
function Pad:apply_entries()
  self:clean()
  self:clear()
  local view_marks = self.bundle.views()
  for index, view_mark in ipairs(view_marks) do
    local entry = Pad.make_entry(index, view_mark, self._opts)
    local line = index - 1
    local range = entry.range
    if entry.mark.absolute == self._focused then range[2] = range[2] .. "Focused" end
    table.insert(self.entries, index, entry)

    A.nvim_buf_set_lines(self.buffer, line, line, true, { entry.display })
    A.nvim_buf_add_highlight(self.buffer, self.namespace, range[1][2], line, range[1][1][1], range[1][1][2])
    A.nvim_buf_add_highlight(self.buffer, self.namespace, range[2], line, range[1][1][2] + self.spacing, range[1][1][2] + self.spacing + #entry.mark.path)
  end
end

function Pad:sync(save)
  self.bundle:clear()
  local lines = A.nvim_buf_get_lines(self.buffer, 0, -1, true)
  for index, line in ipairs(lines) do
    local trimmed = vim.trim(line)
    if trimmed ~= "" then
      local mark
      if self._opts.disable_devicons then
        mark = Mark({ path = trimmed, type = util.filetype(trimmed) })
      else
        local icon, spacing, content = line:match("^([^%s]+)(" .. string.rep("%s", self.spacing) .. ")(.+)$")
        if icon then
          mark = Mark({ path = content, type = util.filetype(content) })
        else
          mark = Mark({ path = trimmed, type = util.filetype(trimmed) })
        end
      end
      self.bundle:add_mark(mark)
    end
  end
  self:apply_entries()
  if save then state.save() end
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

function Pad:clean(begin, finish) A.nvim_buf_clear_namespace(self.buffer, self.namespace, begin or 0, finish or -1) end

function Pad:clear() A.nvim_buf_set_lines(self.buffer, 0, -1, true, {}) end

return Pad
