# track.nvim

Harpoon like file tracking. Supercharged by [telescope.nvim](https:/github.com/nvim-telescope/telescope.nvim).

https://github.com/dharmx/track.nvim/assets/80379926/47cb7fab-6ab2-4191-a1e8-6235d0de8fea

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim).

```lua
-- no configuration needed
"dharmx/track.nvim",

-- recommended lazy load
{
  "dharmx/track.nvim",
  config = function()
    local set = vim.keymap.set -- tweak to suit your own
    set("n", "<leader><leader>", "<cmd>Track<cr>", silent)
    set("n", "<leader>ee", "<cmd>Track bundles<cr>", silent)
    set("n", "<leader>aa", "<cmd>Mark<cr>", silent)
    set("n", "<leader>dd", "<cmd>Unmark<cr>", silent)

    -- alternatively require("track").setup()
    require("track").setup({ -- non-nerdfonts icons
      pickers = {
        bundles = {
          prompt_prefix = " > ",
          selection_caret = " > ",
          icons = {
            separator = " ",
            main = "*",
            alternate = "/",
            inactive = "#",
            mark = "=",
            history = "<",
          }
        },
        views = {
          selection_caret = " > ",
          prompt_prefix = " > ",
          icons = {
            separator = " ",
            terminal = "#",
            manual = "^",
            missing = "?",
            accessible = "*",
            inaccessible = "x",
            focused = "@",
            listed = "S",
            unlisted = "$",
            file = ".",
            directory = "~",
          },
        },
      },
    })
  end,
  cmd = {
    "Mark",
    "MarkOpened",
    "StashBundle",
    "RestoreBundle",
    "AlternateBundle",
    "Unmark"
  },
},
```

## Quickstart

Q. How does tracking files work?

- Create a mark by `:Mark`. You can map a key to it.
- Now, open the telescope window by `:Track` views.
- You can move the entries up and down by pressing `i_<C-n>` and `i_<C-p>`.
- You can select all entries by pressing `v`. And, `<cr>` to open.
- Or, press `<tab>` to select multiple entries.
- You can delete an entry by `i_<C-d>`.
- You can change the view name in telescope by pressing `i_<C-e>` on the entry.
- Close the telescope window then do `:Unmark`.
- Open `:Track views` again. And, you should see the mark being erased.

Note, that you can also track commands, manpages and helpdocs.

Q. How does bundles work?

- Open `:Track bundles`.
- If the picker is empty then the current diretory is not being tracked.
- Then start by marking a file in that directory `:Mark some/path/to/file` or, just `:Mark`.
- Now, open `:Track bundles` again. You will see a `main` branch being created.
- You can change the bundle name in telescope by pressing `i_<C-e>` on the entry.
- `:StashBundle` will create another bundle with a auto-generated label and replace the place of the **main** bundle.
- Try `Track bundles` again.
- `:AlternateBundle` will swap the current **main** bundle with the **alternate** bundle. This functions same as Vim's
  default `^` mapping.

Note that there can only be one `main` bundle and one **alternate** bundle. And, a bundle will have a main bundle
always. It is not recommended to remove it.

## Defaults

```lua
local Util = require("track.util")

local defaults = {
  save_path = vim.fn.stdpath("state") .. "/track.json",
  disable_history = true,
  maximum_history = 10,
  pad = {
    icons = {
      saved = "",
      save = "",
    },
    serial_maps = true,
    save_on_close = true,
    auto_create = true,
    save_on_hide = true,
    hooks = {
      on_choose = Util.open_entry,
      on_serial_choose = Util.open_entry,
    },
    window = {
      style = "minimal",
      border = "solid",
      focusable = true,
      relative = "editor",
      width = 60,
      height = 10,
      title_pos = "left",
    },
  },
  pickers = {
    bundles = {
      save_on_close = true,
      bundle_label = nil,
      root_path = nil,
      prompt_prefix = "   ",
      selection_caret = "   ",
      previewer = false,
      initial_mode = "insert", -- alternatively: "normal"
      layout_config = {
        preview_cutoff = 1,
        width = function(_, max_col, _) return math.min(max_col, 70) end,
        height = function(_, _, max_line) return math.min(max_line, 15) end,
      },
      hooks = {
        on_close = Util.mute,
        on_open = Util.mute,
        on_choose = function(status, opts)
          local selected = status.picker:get_selection()
          if not selected then return end
          require("track.state")._roots[opts.root_path]:change_main_bundle(selected.value.label)
        end,
      },
      attach_mappings = function(_, map)
        local actions = require("telescope.actions")
        map("n", "q", actions.close)
        map("n", "v", actions.select_all)

        local Actions = require("telescope._extensions.track.actions")
        map("n", "D", actions.select_all + Actions.delete_bundle)
        map("n", "dd", Actions.delete_bundle)
        map("i", "<C-D>", Actions.delete_bundle)
        map("i", "<C-E>", Actions.change_bundle_label)
        return true -- compulsory
      end,
      icons = {
        separator = " ┃ ",
        main = " ",
        alternate = " ",
        inactive = " ",
        mark = "",
        history = "",
      }
    },
    views = {
      save_on_close = true, -- save when the view telescope picker is closed
      bundle_label = nil,
      root_path = nil,
      selection_caret = "   ",
      path_display = {
        absolute = false, -- /home/name/projects/hello/mark.lua -> hello/mark.lua
        shorten = 1, -- /aname/bname/cname/dname.e -> /a/b/c/dname.e
      },
      prompt_prefix = "   ",
      previewer = false,
      initial_mode = "insert", -- alternatively: "normal"
      layout_config = {
        preview_cutoff = 1,
        width = function(_, max_col, _) return math.min(max_col, 70) end,
        height = function(_, _, max_line) return math.min(max_line, 15) end,
      },
      hooks = {
        on_close = Util.mute,
        on_open = Util.mute,
        on_choose = function(status, _)
          local entries = vim.F.if_nil(status.picker:get_multi_selection(), {})
          if #entries == 0 then table.insert(entries, status.picker:get_selection()) end
          for _, entry in ipairs(entries) do Util.open_entry(entry.value.path) end
        end,
      },
      attach_mappings = function(_, map)
        local actions = require("telescope.actions")
        map("n", "q", actions.close)
        map("n", "v", actions.select_all)

        local Actions = require("telescope._extensions.track.actions")
        map("n", "D", actions.select_all + Actions.delete_view)
        map("n", "dd", Actions.delete_view)
        map("i", "<C-D>", Actions.delete_view)
        map("i", "<C-N>", Actions.move_view_next)
        map("i", "<C-P>", Actions.move_view_previous)
        map("i", "<C-E>", Actions.change_mark_view)
        return true -- compulsory
      end,
      disable_devicons = false,
      icons = {
        separator = " ",
        terminal = " ",
        manual = " ",
        missing = " ",
        accessible = " ",
        inaccessible = " ",
        focused = " ",
        listed = "",
        unlisted = "≖",
        file = "",
        directory = "",
      },
    },
  },
  log = {
    plugin = "track",
    level = "warn",
  },
}
```
