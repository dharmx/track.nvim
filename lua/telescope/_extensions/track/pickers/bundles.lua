local M = {}

local config = require("track.config")
local util = require("track.util")
local log = require("track.log")

local state = require("track.state")
local entry_makers = require("telescope._extensions.track.entry_makers")

local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local mappings = require("telescope.mappings")

local tele_config = require("telescope.config")
local tele_state = require("telescope.state")

function M.resulter(opts)
  opts = vim.F.if_nil(opts, {})
  opts = config.extend_pickers({ bundles = opts }).bundles
  local root, _ = util.root_and_bundle()
  return root and root.bundles() or {}
end

-- this can be passed into picker:refresh(<finder>)
function M.finder(opts, results)
  opts = vim.F.if_nil(opts, {})
  opts = config.extend_pickers({ bundles = opts }).bundles
  if vim.tbl_isempty(results) then vim.notify("No root found! Create one first.") end
  return finders.new_table({
    results = results,
    entry_maker = entry_makers.gen_from_bundle(opts),
  })
end

function M.picker(opts)
  opts = vim.F.if_nil(opts, {})
  opts = config.extend_pickers({ bundles = opts }).bundles
  local hooks = opts.hooks
  state.load()

  local finder = M.finder(opts, M.resulter(opts))
  if vim.tbl_isempty(finder.results) then
    vim.notify("Directory is not being tracked.")
    return
  end

  local picker = pickers.new(opts, {
    prompt_title = "Bundles",
    finder = finder,
    sorter = tele_config.values.generic_sorter(opts),
    on_complete = {
      function(self)
        if not opts.hooks.on_serial then return end
        for entry in self.manager:iter() do
          vim.keymap.set("n", tostring(entry.index), function()
            actions.close(self.layout.prompt.bufnr)
            opts.hooks.on_serial(entry, self)
          end, { buffer = self.layout.prompt.bufnr })
        end
      end,
    },
    attach_mappings = function(buffer, _)
      local status = tele_state.get_status(buffer)
      actions.close:enhance({
        post = function(_)
          if opts.save_on_close then
            state.save()
            log.info("Telescope.Bundles.picker(): closed telescope.track.bundles and saved state")
          end
          hooks.on_close(status, opts)
        end,
      })
      actions.select_default:replace(function(...)
        actions.close(...)
        hooks.on_choose(status, opts)
      end)
      -- dynamic keymaps
      return true
    end,
  })

  hooks.on_open(opts)
  picker:find()
end

return M
