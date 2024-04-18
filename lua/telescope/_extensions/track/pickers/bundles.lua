local M = {}

local Config = require("track.config")
local Log = require("track.log")

local State = require("track.state")
local EntryMakers = require("telescope._extensions.track.entry_makers")

local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local config = require("telescope.config")
local state = require("telescope.state")

function M.resulter(opts)
  return State._roots[opts.root_path].bundles()
end

-- this can be passed into picker:refresh(<finder>)
function M.finder(opts, results)
  return finders.new_table({
    results = results,
    entry_maker = EntryMakers.gen_from_bundle(opts),
  })
end

function M.picker(opts)
  opts = vim.F.if_nil(opts, {})
  ---@diagnostic disable-next-line: missing-fields
  opts = Config.extend_pickers({ bundles = opts }).bundles
  local hooks = opts.hooks
  State.load()

  local picker = pickers.new(opts, {
    prompt_title = "Bundles",
    finder = M.finder(opts, M.resulter(opts)),
    sorter = config.values.generic_sorter(opts),
    attach_mappings = function(buffer, _)
      local status = state.get_status(buffer)
      status.picker._current_opts = opts
      ---@diagnostic disable-next-line: undefined-field
      actions.close:enhance({
        post = function(_)
          if opts.save_on_close then
            State.save()
            Log.info("Telescope.Bundles.picker(): closed telescope.track.bundles and saved state")
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
