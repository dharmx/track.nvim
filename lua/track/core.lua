local M = {}
local state = require("track.state")
local util = require("track.util")

local Config = require("track.config").get()
local Stash = require("track.containers.stash")
local Root = require("track.containers.root")

function M.mark(file, stash_label)
  state.load()
  stash_label = vim.F.if_nil(stash_label, "default")
  local cwd = util.cwd()
  local cwdroot = state._roots[cwd]
  if not cwdroot then
    local root = Root:new({ path = cwd })
    root.stashes["default"]:add_mark(file)
    state._roots[cwd] = root
    return
  end
  if not cwdroot.stashes[stash_label][file] then cwdroot.stashes[stash_label]:add_mark(file) end
  if Config.save.on_mark then state.save() end
end

function M.unmark(file, stash_label)
  state.load()
  stash_label = vim.F.if_nil(stash_label, "default")
  local cwd = util.cwd()
  local cwdroot = state._roots[cwd]
  if not cwdroot or not cwdroot[stash_label][file] then return end
  cwdroot[stash_label]:remove_mark(file)
  if Config.save.on_unmark then state.save() end
end

function M.stash()
  state.load()
  local cwd = util.cwd()
  local cwdroot = state._roots[cwd]
  if not cwdroot then return end

  local oldstash = cwdroot.stashes[cwdroot.main]
  oldstash.label = "stashed-" .. os.date("%s")
  cwdroot.stashes["default"] = Stash:new({ label = "default" })
  cwdroot.main = "default"
  cwdroot.stashes[oldstash.label] = oldstash
  if Config.save.on_stash then state.save() end
end

function M.mark_position(row, column, label)
  state.load()
  if Config.save.on_position_mark then state.save() end
end

function M.unmark_position(row, column)
  state.load()
  if Config.save.on_position_unmark then state.save() end
end

function M.unmark_position_by_label(label)
  state.load()
  if Config.save.on_position_unmark then state.save() end
end

function M.mark_line(line, label)
  state.load()
  if Config.save.on_line_mark then state.save() end
end

function M.unmark_line(line)
  state.load()
  if Config.save.on_line_unmark then state.save() end
end

function M.unmark_line_by_label(label)
  state.load()
  if Config.save.on_line_unmark then state.save() end
end

function M.list_marks(stash_name)
  state.load()
  local cwd = util.cwd()
  local cwdroot = state._roots[cwd]
  if not cwdroot then return {} end
  stash_name = vim.F.if_nil(stash_name, cwdroot.main)
  return vim.tbl_keys(cwdroot.stashes[stash_name].marks)
end

return M
