local M = {}

local config = require("track.config")
local util = require("track.util")
local log = require("track.log")

local state = require("track.state")
local entry_makers = require("telescope._extensions.track.entry_makers")

local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")

local tele_config = require("telescope.config")
local tele_state = require("telescope.state")

function M.resulter(opts)
  opts = vim.F.if_nil(opts, {})
  opts = config.extend_pickers({ views = opts }).views
  local _, bundle = util.root_and_bundle()
  return bundle and not bundle:empty() and bundle.views() or {}
end

-- this can be passed into picker:refresh(<finder>)
function M.finder(opts, results)
  opts = vim.F.if_nil(opts, {})
  opts = config.extend_pickers({ views = opts }).views
  return finders.new_table({
    results = results,
    entry_maker = entry_makers.gen_from_view(opts),
  })
end

function M.picker(opts)
  opts = vim.F.if_nil(opts, {})
  opts = config.extend_pickers({ views = opts }).views
  local hooks = opts.hooks
  state.load()

  opts._focused = vim.fn.fnamemodify(vim.fn.bufname(), ":p")
  local finder = M.finder(opts, M.resulter(opts))
  if vim.tbl_isempty(finder.results) then
    vim.notify("Bundle is empty. No marks found.")
    return
  end

  local picker = pickers.new(opts, {
    prompt_title = "Views",
    finder = finder,
    sorter = tele_config.values.file_sorter(opts),
    attach_mappings = function(buffer, _)
      local status = tele_state.get_status(buffer)
      actions.close:enhance({
        post = function(_)
          if opts.save_on_close then
            state.save()
            log.info("Telescope.Views.picker(): closed telescope.track.views and saved state")
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
        if opts.switch_directory and entry.value.type == "directory" and state._roots[new_root_path] then
          vim.loop.chdir(new_root_path)
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
