---@diagnostic disable: param-type-mismatch
local M = {}
local U = vim.loop
local F = vim.fn
local A = vim.api

function M.mute() end

function M.inspect(items) vim.notify(vim.inspect(items)) end

function M.cwd() return vim.F.if_nil(U.cwd(), F.getcwd()) end

function M.warn(message)
  A.nvim_notify(message, vim.log.levels.WARN, {
    icon = " ",
    title = "track.nvim",
    prompt_title = "track.nvim",
  })
end

return M
