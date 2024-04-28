# track.nvim

Harpoon like file tracking. Supercharged by [telescope.nvim](https:/github.com/nvim-telescope/telescope.nvim).

![views](./views.png) 
![bundles](./bundles.png) 

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim).

<details>

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

</details>

## Quickstart

### Q. How does tracking files work?

- Create a mark by `:Mark`. You can map a key to it.
- Now, open the telescope window by `:Track views`.
- You can move the entries up and down by pressing `i_<C-n>` and `i_<C-p>`.
- You can select all entries by pressing `v`. And, `<cr>` to open.
- Or, press `<tab>` to select multiple entries.
- You can delete an entry by `i_<C-d>`.
- You can change the view name in telescope by pressing `i_<C-e>` on the entry.
- Close the telescope window then do `:Unmark`.
- Open `:Track views` again. And, you should see the mark being erased.

Note that, you can also track commands, man-pages and help-docs.

### Q. How does bundles work?

- Open `:Track bundles`.
- If the picker is empty then the current directory is not being tracked.
- Then start by marking a file in that directory `:Mark some/path/to/file` or,
  just `:Mark`.
- Now, open `:Track bundles` again. You will see a `main` branch being created.
- You can change the bundle name in telescope by pressing `i_<C-e>` on the entry.
- `:StashBundle` will create another bundle with an auto-generated label and
  replace the place of the **main** bundle.
- Try `Track bundles` again.
- `:AlternateBundle` will swap the current **main** bundle with the **alternate**
  bundle. This functions the same way as Vim's default `^` mapping.

Note that, there can only be one `main` bundle and one **alternate** bundle. And,
a bundle will always have a main bundle. It is not recommended to remove it.

### Q. How do I mark a terminal command?

- Open terminal by `:terminal`

## Defaults

```lua
local Util = require("track.util")

local defaults = {
  save_path = vim.fn.stdpath("state") .. "/track.json",
  pickers = {
    bundles = {
      save_on_close = true,
      bundle_label = nil,
      root_path = nil,
      prompt_prefix = "   ",
      selection_caret = "   ",
      previewer = false,
      initial_mode = "normal", -- alternatively: "insert"
      sorting_strategy = "ascending",
      results_title = false,
      layout_config = {
        prompt_position = "top",
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
      initial_mode = "normal", -- alternatively: "insert"
      results_title = false,
      sorting_strategy = "ascending",
      layout_config = {
        prompt_position = "top",
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
          for _, entry in ipairs(entries) do Util.open_entry(entry) end
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
        locked = " ",
        separator = " ",
        terminal = " ",
        manual = " ",
        site = " ",
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
  -- dev features / not implemented
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
}
```

## Theme

Modify these to change colors. This section is mainly geared towards theme plugin authors.

```lua
local function HI(...) vim.api.nvim_set_hl(0, ...) end

HI("TrackPadTitle", { link = "TelescopeResultsTitle" })

HI("TrackViewsAccessible", { foreground = "#79DCAA" })
HI("TrackViewsInaccessible", { foreground = "#F87070" })
HI("TrackViewsFocusedDisplay", { foreground = "#7AB0DF" })
HI("TrackViewsFocused", { foreground = "#7AB0DF" })
HI("TrackViewsIndex", { foreground = "#54CED6" })
HI("TrackViewsMarkListed", { foreground = "#4B5259" })
HI("TrackViewsMarkUnlisted", { foreground = "#C397D8" })
HI("TrackViewsMissing", { foreground = "#FFE59E" })
HI("TrackViewsFile", { foreground = "#FFE59E" })
HI("TrackViewsDirectory", { foreground = "#FFE59E" })
HI("TrackViewsSite", { foreground = "#66B3FF" })
HI("TrackViewsTerminal", { foreground = "#36C692" })
HI("TrackViewsManual", { foreground = "#5FB0FC" })
HI("TrackViewsDivide", { foreground = "#4B5259" })
HI("TrackViewsLocked", { foreground = "#E37070" })

HI("TrackBundlesInactive", { foreground = "#4B5259" })
HI("TrackBundlesDisplayInactive", { foreground = "#4B5259" })
HI("TrackBundlesMain", { foreground = "#7AB0DF" })
HI("TrackBundlesDisplayMain", { foreground = "#7AB0DF" })
HI("TrackBundlesAlternate", { foreground = "#36C692" })
HI("TrackBundlesDisplayAlternate", { foreground = "#79DCAA" })
HI("TrackBundlesMark", { foreground = "#FFE59E" })
HI("TrackBundlesHistory", { foreground = "#F87070" })
HI("TrackBundlesDivide", { foreground = "#151A1F" })
```
## Commands

```vim
:Mark                   " add current buffer as mark
:Mark <URI>             " add passed <URI> as mark
:Unmark                 " rm current mark (if exists)
:Unmark <URI>           " rm <URI> mark (if exists)
:MarkOpened             " mark all opened buffers
:StashBundle            " stash current main bundle and make new bundle as main 
:RestoreBundle          " restore previous bundle
:DeleteBundle           " rm main bundle
:AlternateBundle        " swap stashed and main bundles
:Track                  " open default pad UI (view)
:Track pad              " open default pad UI (view)
:Track views            " open views telescope picker
:Track bundles          " open bundles telescope picker
:Track save             " save current state to file
:Track load             " load saved state for the first time
:Track loadsave         " load saved state from a file
:Track reload           " load last saved state to cache
:Track wipe             " clear caches
:Track remove           " rm save file
:Track menu             " telescope picker for available track pickers
" TODO: no root, roots, bundles indicators for Track menu
```

## Credits

- harpoon
- @nikfp
