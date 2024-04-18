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
  local results = {}
  local root_path = opts.root_path
  local root = State._roots[root_path]
  local bundle_label = opts.bundle_label

  if root then
    local bundle = root.bundles[bundle_label]
    if bundle and not bundle:empty() then
      local views = bundle.views()

      for index, view in ipairs(views) do
        local view_copy = vim.deepcopy(view)
        view_copy.index = index -- needed for dynamic keymaps
        view_copy.root_path = root_path
        view_copy.bundle_label = bundle_label
        table.insert(results, index, view_copy)
      end
    end
  end
  return results
end

-- this can be passed into picker:refresh(<finder>)
function M.finder(opts, results)
  return finders.new_table({
    results = results,
    entry_maker = EntryMakers.gen_from_view(opts),
  })
end

function M.picker(opts)
  opts = vim.F.if_nil(opts, {})
  ---@diagnostic disable-next-line: missing-fields
  opts = Config.extend_pickers({ views = opts }).views
  local hooks = opts.hooks
  State.load()

  local picker = pickers.new(opts, {
    prompt_title = "Views",
    finder = M.finder(opts, M.resulter(opts)),
    sorter = config.values.file_sorter(opts),
    attach_mappings = function(buffer, _)
      local status = state.get_status(buffer)
      status.picker._current_opts = opts
      ---@diagnostic disable-next-line: undefined-field
      actions.close:enhance({
        post = function(_)
          if opts.save_on_close then
            State.save()
            Log.info("Telescope.Views.picker(): closed telescope.track.views and saved state")
          end
          hooks.on_close(status, opts)
        end,
      })
      actions.select_default:replace(function(...)
        -- add navigation controls for traversing back and forth through other roots
        -- if the exist otherwise open the directory
        local entry = status.picker:get_selection()
        local new_root_path = entry.value.absolute
        if new_root_path:len() > 1 then new_root_path = new_root_path:gsub("/$", "") end
        if entry.value.type == "directory" and State._roots[new_root_path] then
          vim.cmd.chdir(new_root_path)
          status.picker:refresh(M.finder(opts, M.resulter(opts)), { reset_prompt = true })
          return
        end
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
