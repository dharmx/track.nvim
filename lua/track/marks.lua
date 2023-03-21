---@diagnostic disable: need-check-nil
local M = {}

local U = vim.loop
local V = vim.fn
local Path = require("plenary.path")

M._internal = {}
M._loaded = false

function M.load(options)
  if M._loaded then return end
  local state_path = Path:new(options.state_path)
  if not state_path:exists() then state_path:touch({ parents = true }) end
  local ok, data = pcall(vim.json.decode, state_path:read())
  if ok then M._internal = data end

  local working = U.cwd()
  local project = options.roots[working]
  if project then
    if not M._internal[working] then M._internal[working] = {} end
    M._internal[working].describe = vim.F.if_nil(project.describe, "NONE")
    M._internal[working].label = vim.F.if_nil(project.label, "NONE")
    M._internal[working].marks = vim.F.if_nil(M._internal[working].marks, {})
    for _, mark in ipairs(vim.F.if_nil(project.marks, {})) do
      M._internal[working].marks[mark] = {
        exists = not not U.fs_realpath(mark),
        absolute = V.fnamemodify(mark, ":p")
      }
    end
  end
  M._loaded = true
end

function M.mark(file)
  local working = U.cwd()
  if not M._internal[working] then
    M._internal[working] = {
      describe = "NONE",
      label = "NONE",
      marks = {
        [file] = {
          exists = not not U.fs_realpath(file),
          absolute = V.fnamemodify(file, ":p")
        }
      }
    }
  end
  if not M._internal[working].marks[file] then
    M._internal[working].marks[file] = {
      exists = not not U.fs_realpath(file),
      absolute = V.fnamemodify(file, ":p")
    }
  end
end

function M.unmark(file)
  local working = U.cwd()
  if not M._internal[working] then return end
  if not M._internal[working].marks[file] then return end
  M._internal[working].marks[file] = nil
end

function M.marks()
  return vim.F.if_nil(vim.F.if_nil(M._internal[vim.loop.cwd()], {}).marks, {})
end

function M.save(options)
  M.load(options)
  local state_path = Path:new(options.state_path)
  state_path:write(vim.json.encode(M._internal), "w")
end

return M
