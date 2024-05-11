local M = {}

M.URI = {
  NO_EXIST = "no_exist",
  NO_ACCESS = "no_access",
  ERROR = "error",
  TERM = "term",
  FILE = "file",
  DIR = "directory",
  DEFAULT = "default",
  HTTP = "http",
  HTTPS = "https",
  MAN = "man",
}
setmetatable(M.URI, { __index = function(self) return self.DEFAULT end })

M.CLASS = {
  MARK = "mark",
  BRANCH = "branch",
  ROOT = "root",
  PAD = "pad",
}

return M
