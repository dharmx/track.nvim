local M = {}

local config = require("track.config")
local util = require("track.util")
local log = require("track.dev.log")

local state = require("track.state")
local entry_makers = require("telescope._extensions.track.entry_makers")

local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")

local tele_config = require("telescope.config")
local tele_state = require("telescope.state")
local if_nil = vim.F.if_nil

function M.resulter(opts)
  opts = if_nil(opts, {})
  opts = config.extend_pickers({ branches = opts }).branches
  local root, _ = util.root_and_branch()
  return root and root.branches() or {}
end

-- this can be passed into picker:refresh(<finder>)
function M.finder(opts, results)
  opts = if_nil(opts, {})
  opts = config.extend_pickers({ branches = opts }).branches
  if vim.tbl_isempty(results) then vim.notify("No root found! Create one first.") end
  return finders.new_table({
    results = results,
    entry_maker = entry_makers.gen_from_branch(opts),
  })
end

function M.picker(opts)
  opts = if_nil(opts, {})
  opts = config.extend_pickers({ branches = opts }).branches
  local hooks = opts.hooks
  state.load()

  local finder = M.finder(opts, M.resulter(opts))
  if vim.tbl_isempty(finder.results) then
    vim.notify("Directory is not being tracked.")
    return
  end

  local picker = pickers.new(opts, {
    prompt_title = "Branches",
    finder = finder,
    sorter = tele_config.values.generic_sorter(opts),
    on_complete = {
      function(self)
        if not opts.serial_map then return end
        for entry in self.manager:iter() do
          vim.keymap.set("n", tostring(entry.index), function()
            actions.close(self.layout.prompt.bufnr)
            opts.hooks.on_serial(entry.value)
          end, { buffer = self.layout.prompt.bufnr })
        end
      end,
    },
    attach_mappings = function(buffer, _)
      local self = tele_state.get_status(buffer).picker
      actions.close:enhance({
        post = function(_)
          if opts.save_on_close then
            state.save()
            log.info("Telescope.Branches.picker(): closed telescope.track.branches and saved state")
          end
          hooks.on_close(self)
        end,
      })
      actions.select_default:replace(function(...)
        actions.close(...)
        hooks.on_choose(self)
        require("track.core")(util.cwd())
      end)
      -- dynamic keymaps
      return true
    end,
  })

  hooks.on_open(opts)
  picker:find()
end

return M
