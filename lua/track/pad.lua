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

local Mark = require("track.containers.mark")

local util = require("track.util")
local state = require("track.state")
local config = require("track.config").get()

local utils = require("telescope.utils")
local strings = require("plenary.strings")

function Pad:_new(opts)
  local types = type(opts)
  assert(types == "table", "expected table")

  self.root_path = opts.root_path
  self.path_display = opts.path_display
  self.mappings = if_nil(opts.mappings, {})
  self.entries = if_nil(opts, {})
  self.path_display = opts.path_display
  self.disable_devicons = opts.disable_devicons
  self.color_devicons = opts.color_devicons

  self.bundle = if_nil(opts.bundle, select(2, util.root_and_bundle({}, true)))
  self.buffer = A.nvim_create_buf(false, false)
  self.namespace = A.nvim_create_namespace("TrackPad")
  self.hooks = opts.hooks
  self.window = nil

  -- TODO: Apply root entry as pickers.views.
  self.mappings.n["<cr>"] = function()
    if self:hidden() then return end
    local parsed_line = Pad.line2entry(A.nvim_get_current_line(), self.disable_devicons)
    if not parsed_line then return end
    self:close()
    self.hooks.on_choose({ value = parsed_line })
  end

  self.config = opts.config
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

  if opts.auto_resize then
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

  A.nvim_buf_attach(self.buffer, false, {
    on_lines = function()
      -- TODO: self:clean() + self:theme()
      self:apply_serial()
    end,
  })

  self._NAME = "pad"
end

function Pad.make_entry(index, view_mark, disable_devicons, color_devicons)
  local entry = { index = index, value = view_mark }
  local icon, group = util.get_icon(entry.value, config.icons, {
    disable_devicons = disable_devicons,
    color_devicons = color_devicons,
  })
  entry.icon = icon
  entry.group = group

  entry.display = (disable_devicons and "" or icon .. " ") .. entry.value.path
  entry.range = { { { 0, #icon }, entry.group }, "TrackPadEntry" }
  return entry
end

function Pad.line2entry(line, disable_devicons)
  local trimmed = vim.trim(line)
  if trimmed ~= "" then
    local mark
    if disable_devicons then
      mark = Mark({ path = trimmed, type = util.filetype(trimmed) })
    else
      local icon, content = line:match("^([^%s]+)%s(.+)$")
      if icon and not utils.is_uri(icon) then
        mark = Mark({ path = content, type = util.filetype(content) })
      else
        local filetype = util.filetype(trimmed)
        if filetype == "term" then trimmed = util.clean_term_uri(trimmed) end
        mark = Mark({ path = trimmed, type = filetype })
      end
    end
    return mark
  end
end

function Pad:apply_serial()
  local maps = A.nvim_buf_get_keymap(self.buffer, "n")
  for _, map in ipairs(maps) do
    if map.lhs:match("^%d+$") then A.nvim_buf_del_keymap(self.buffer, "n", map.lhs) end
  end

  local lines = A.nvim_buf_get_lines(self.buffer, 0, -1, false)
  for serial, line in ipairs(lines) do
    local mark = Pad.line2entry(line, self.disable_devicons)
    if mark then
      vim.keymap.set("n", tostring(serial), function()
        self:close()
        self.hooks.on_serial({ value = mark }, serial, self)
      end, { buffer = self.buffer })
    end
  end
end

function Pad:_extmark(line, start, finish)
  A.nvim_buf_set_extmark(self.buffer, self.namespace, line, start, {
    end_row = line,
    end_col = finish,
    conceal = "",
  })
end

function Pad:conceal_term(line, offset, path)
  local start, finish = string.find(path, "^(term://.+//)%d+?:.*$")
  if start and finish then
    self:_extmark(line, start + offset - 1, finish + offset)
  else
    start, finish = string.find(path, "^(term://.+//)")
    if start and finish then self:_extmark(line, start + offset - 1, finish + offset) end
  end

  local count = 1
  start, finish = nil, nil
  while true do
    start, finish = string.find(path, "\\|", count)
    if start == nil then break end
    self:_extmark(line, start + offset - 1, finish + offset - 1)
    count = finish + 1
  end
end

function Pad:conceal_uri(line, offset, path)
  local start, finish = string.find(path, "^%w+://")
  if start and finish then
    start = offset
    finish = finish + start
    self:_extmark(line, start, finish)
  end
end

function Pad:conceal_path(line, offset, path)
  local normp = vim.split(path, "/", { plain = true })
  local tranp = vim.split(utils.transform_path(self, path), "/", { plain = true })

  if #tranp ~= #normp or normp[#normp] ~= tranp[#tranp] then return end
  table.remove(tranp)
  table.remove(normp)

  local index = 1
  local pointer = offset
  while index <= #tranp do
    pointer = pointer + #tranp[index]
    local start = pointer
    pointer = pointer + #normp[index] - #tranp[index]
    if (pointer - start) ~= #normp[index] then self:_extmark(line, start, pointer) end
    pointer = pointer + 1
    index = index + 1
  end
end

---@todo
function Pad:theme() end

-- stylua: ignore
function Pad:render()
  self:clean()
  self:clear()
  local view_marks = self.bundle.views()
  for index, view_mark in ipairs(view_marks) do
    local entry = Pad.make_entry(index, view_mark, self.disable_devicons, self.color_devicons)
    local mark = entry.value
    local line = index - 1
    local range = entry.range
    if entry.value.absolute == self._focused then range[2] = range[2] .. "Focused" end
    table.insert(self.entries, index, entry)

    A.nvim_buf_set_lines(self.buffer, line, line, true, { entry.display })
    A.nvim_buf_add_highlight(self.buffer, self.namespace, range[1][2], line, range[1][1][1], range[1][1][2])
    A.nvim_buf_add_highlight(self.buffer, self.namespace, range[2], line, range[1][1][2] + 1, range[1][1][2] + 1 + #mark.path)
    if mark.type == "file" or mark.type == "directory" then
      self:conceal_path(line, range[1][1][2] + 1, mark.path)
    elseif mark.type == "term" then
      self:conceal_term(line, range[1][1][2] + 1, mark.path)
    elseif mark.type ~= "file" then
      self:conceal_uri(line, range[1][1][2] + 1, mark.path)
    end
  end
  self:apply_serial()
end

function Pad:sync(save)
  self.bundle:clear()
  local lines = A.nvim_buf_get_lines(self.buffer, 0, -1, true)
  for _, line in ipairs(lines) do
    local parsed_mark = Pad.line2entry(line, self.disable_devicons)
    if parsed_mark then self.bundle:add_mark(parsed_mark) end
  end
  self:render()
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
  self:render()
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

function Pad:exists() return self.buffer and A.nvim_buf_is_valid(self.buffer) end

function Pad:delete()
  if not self:exists() then return end
  A.nvim_buf_delete(self.buffer, { force = true })
end

function Pad:clean(begin, finish) A.nvim_buf_clear_namespace(self.buffer, self.namespace, begin or 0, finish or -1) end

function Pad:clear() A.nvim_buf_set_lines(self.buffer, 0, -1, true, {}) end

return Pad
