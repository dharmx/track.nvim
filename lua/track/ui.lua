local M = {}
M.bookmarks = {}
M.namespaces = {}
local A = vim.api

function M.place_bookmark_symbol(buffer, namespace, line, symbol, groups)
  M.bookmarks[line] = A.nvim_buf_set_extmark(buffer, namespace, line, 0, {
    sign_text = symbol,
    sign_hl_group = groups.sign,
    number_hl_group = groups.number,
    line_hl_group = groups.line,
    cursorline_hl_group = groups.cursorline,
  })
end

function M.load_bookmarks(buffer)
  local State = require("track.state")
  State.load()

  local root = State._roots[vim.fn.getcwd()]
  if not root then return end

  local bundle = root:get_main_bundle()
  local mark = bundle.marks[vim.fn.expand("%")]
  if not mark then return end

  for line, _ in pairs(mark.bookmarks) do
    M.add_bookmark(buffer, tonumber(line))
  end
end

function M.add_bookmark(buffer, line)
  M.namespaces.bookmarks = vim.F.if_nil(M.namespaces.bookmarks, A.nvim_create_namespace("Bookmarks"))
  local sign = require("track.config").get().bookmarks.sign
  M.place_bookmark_symbol(buffer, M.namespaces.bookmarks, line - 1, sign, {
    sign = "TrackBookmarkSign",
    number = "TrackBookmarkNumber",
    line = "TrackBookmarkLine",
    cursor = "TrackBookmarkCursorline",
  })
end

function M.remove_bookmark(buffer, line)
  if not M.namespaces.bookmarks then return end
  A.nvim_buf_del_extmark(buffer, M.namespaces.bookmarks, M.bookmarks[line - 1])
end

return M
