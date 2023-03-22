---@diagnostic disable: need-check-nil, redundant-parameter
local M = {}
local U = vim.loop
local V = vim.fn
local A = vim.api

local Path = require("plenary.path")
local config = require("track.config").get()

M._internal = {}
M._loaded = false

-- TODO: M.reload - M.load should only be called once.
function M.load(on_load)
  local state_path = Path:new(config.state_path)
  if not state_path:exists() then state_path:touch({ parents = true }) end
  local ok, data = pcall(vim.json.decode, state_path:read())
  if ok then M._internal = data end

  local cwd = U.cwd()
  local project = config.roots[cwd]
  if project then
    if not M._internal[cwd] then M._internal[cwd] = {} end

    -- NOTE: What more metadata can be added here?
    M._internal[cwd].describe = vim.F.if_nil(project.describe, "NONE")
    M._internal[cwd].label = vim.F.if_nil(project.label, "NONE")
    M._internal[cwd].marks = vim.F.if_nil(M._internal[cwd].marks, {})
    project.marks = vim.F.if_nil(project.marks, {})

    -- IMPROVE: Use pairs() and see if key is a number i.e. allow both table and string.
    if vim.tbl_isempty(project.marks) then
      M._loaded = true
      vim.F.if_nil(on_load, config.callbacks.on_load)(M._internal)
      return
    end
    if vim.tbl_islist(project.marks) then
      for _, mark in ipairs(project.marks) do
        -- NOTE: What more metadata can be added here?
        M._internal[cwd].marks[mark] = {
          exists = not not U.fs_realpath(mark),
          absolute = V.fnamemodify(mark, ":p"),
          position = { 1, 0 }, -- TODO: Support multiple positions.
        }
      end
      M._loaded = true
      vim.F.if_nil(on_load, config.callbacks.on_load)(M._internal)
      return
    end

    for mark, _ in pairs(project.marks) do
      M._internal[cwd].marks[mark] = {
        exists = vim.F.if_nil(mark.exists, not not U.fs_realpath(mark)),
        absolute = V.fnamemodify(mark, ":p"),
        position = vim.F.if_nil(mark.position, { 1, 0 }), -- TODO: Support multiple positions.
      }
    end
  end
  M._loaded = true
  vim.F.if_nil(on_load, config.callbacks.on_load)(M._internal)
end

function M.mark(file)
  local cwd = U.cwd()
  if not M._internal[cwd] then
    M._internal[cwd] = {
      describe = "NONE",
      label = "NONE",
      marks = {
        [file] = {
          exists = not not U.fs_realpath(file),
          absolute = V.fnamemodify(file, ":p"),
          position = A.nvim_win_get_cursor(0), -- TODO: Support multiple positions.
        },
      },
    }
  end

  if not M._internal[cwd].marks[file] then
    M._internal[cwd].marks[file] = {
      exists = not not U.fs_realpath(file),
      absolute = V.fnamemodify(file, ":p"),
      position = A.nvim_win_get_cursor(0), -- TODO: Support multiple positions.
    }
  end
  config.callbacks.on_mark(M._internal[cwd].marks[file])
  if config.save.on_mark then M.save() end
end

function M.unmark(file)
  local cwd = U.cwd()
  if not M._internal[cwd] then return end
  if not M._internal[cwd].marks[file] then return end
  M._internal[cwd].marks[file] = nil
  config.callbacks.on_unmark(M._internal[cwd].marks[file])
  if config.save.on_unmark then M.save() end
end

function M.marks() return vim.F.if_nil(vim.F.if_nil(M._internal[vim.loop.cwd()], {}).marks, {}) end

function M.save(on_save)
  local state_path = Path:new(config.state_path)
  state_path:write(vim.json.encode(M._internal), "w")
  vim.F.if_nil(on_save, config.callbacks.on_save)(M._internal)
end

-- TODO: Implement next_mark, previous_mark and to_mark.

return M
