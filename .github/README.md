# track.nvim

Most over-engineered marking system. Harpoon-like file tracking.
Supercharged by [telescope.nvim](https:/github.com/nvim-telescope/telescope.nvim).

https://github.com/dharmx/track.nvim/assets/80379926/3d928ebc-7829-4e84-a81b-9c87a631d5d7

[Read WIKI.](https://github.com/dharmx/track.nvim/wiki)

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
    local silent = { silent = true }
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

## Defaults

<details>

```lua
local if_nil = vim.F.if_nil
local util = require("track.util")

M._defaults = {
  save_path = vim.fn.stdpath("state") .. "/track.json", -- db
  root_path = true, -- string or, true for automatically fetching root_path
  bundle_label = true, --  string or, true for automatically fetching bundle_label
  disable_history = true, -- save deleted marks
  maximum_history = 10, -- limit history
  pad = { -- built-in UI for viewing marks
    icons = {
      save_done = "", -- not in use
      save = "", -- not in use
      directory = "",
      terminal = "",
      manual = "",
      site = "",
      locked = " ", -- existence cannot be checked (not a path i.e. a command/link/man)
      missing = " ", -- path has been moved/deleted/renamed
      accessible = " ", -- path still exists
      inaccessible = " ", -- N/A / invalid perms
      focused = " ", -- active buffer path (visible)
      listed = "", -- loaded into a listed buffer (invisible)
      unlisted = "≖", -- loaded into an unlisted buffer
    },
    spacing = 1, -- not implemented
    disable_status = true,
    disable_devicons = true, -- recommended
    save_on_close = true, -- save state automatically when pad window is closed
    serial_map = false, -- run hooks.on_serial when an entry's line number is pressed
    switch_directory = false, -- if selected entry is a Root object then chdir to it
    path_display = { -- see :help telescope.defaults.path_display
      absolute = false,
      shorten = 1,
    },
    hooks = {
      on_choose = util.open_entry, -- when an item is selected <CR>
      on_serial = util.open_entry, -- when a number co-responding to an entry's line number is pressed
      on_close = util.mute, -- run after the pad window closes
    },
    mappings = { -- similar to :help telescope.mappings
      n = {
        q = function(self) self:close() end,
        ["<C-s>"] = function(self) self:sync(true) end, -- manual save state
      },
    },
    config = { -- see :help api-win_config
      style = "minimal",
      border = "solid",
      focusable = true,
      relative = "editor",
      width = 60,
      height = 10,
      -- row and col will be overridden
      title_pos = "left",
    },
  },
  pickers = {
    bundles = {
      serial_map = false,
      icons = {
        separator = " │ ",
        main = " ",
        alternate = " ",
        inactive = " ",
        mark = "",
        history = "",
      },
      save_on_close = true,
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
        on_close = util.mute,
        on_open = util.mute,
        on_serial = function(entry)
          local root, _ = util.root_and_bundle()
          root:change_main_bundle(entry.value.label)
        end,
        on_choose = function(self) -- mappings WRT to line numbers
          local entry = self:get_selection()
          if not entry then return end
          local root, _ = util.root_and_bundle()
          root:change_main_bundle(entry.value.label)
        end,
      },
      attach_mappings = function(_, map)
        local actions = require("telescope.actions")
        map("n", "q", actions.close)
        map("n", "v", actions.select_all)

        local track_actions = require("telescope._extensions.track.actions")
        map("n", "D", actions.select_all + track_actions.delete_bundle)
        map("n", "dd", track_actions.delete_bundle)
        map("i", "<C-D>", track_actions.delete_bundle)
        map("i", "<C-E>", track_actions.change_bundle_label)
        map("n", "s", track_actions.change_bundle_label)
        return true -- compulsory
      end,
    },
    views = {
      icons = {
        separator = " ",
        locked = " ", -- existence cannot be checked (not a path i.e. a command/link/man)
        missing = " ", -- path has been moved/deleted/renamed
        accessible = " ", -- path still exists
        inaccessible = " ", -- N/A / invalid perms
        focused = " ", -- active buffer path (visible)
        listed = "", -- loaded into a listed buffer (invisible)
        unlisted = "≖", -- loaded into an unlisted buffer
        file = "", -- default icon
        directory = " ", -- directory icon
        terminal = "", -- terminal URI icon
        manual = " ", -- manpage URI type icon i.e. :Man find(1) or, :edit man://find(1)
        site = " ", -- website link https://www.google.com
      },
      switch_directory = true, -- switch when a directory i.e. marked is a Root object
      save_on_close = true, -- save when the view telescope picker is closed
      selection_caret = "   ",
      path_display = {
        absolute = false, -- /home/name/projects/hello/mark.lua -> hello/mark.lua
        shorten = 1, -- /aname/bname/cname/dname.e -> /a/b/c/dname.e
      },
      prompt_prefix = "   ",
      previewer = false,
      serial_map = false,
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
        on_close = util.mute,
        on_open = util.mute,
        on_serial = util.open_entry,
        on_choose = function(self)
          local entries = if_nil(self:get_multi_selection(), {})
          if #entries == 0 then table.insert(entries, self:get_selection()) end
          for _, entry in ipairs(entries) do
            util.open_entry(entry)
          end
        end,
      },
      attach_mappings = function(_, map)
        local actions = require("telescope.actions")
        map("n", "q", actions.close)
        map("n", "v", actions.select_all)

        local track_actions = require("telescope._extensions.track.actions")
        map("n", "D", actions.select_all + track_actions.delete_view)
        map("n", "dd", track_actions.delete_view)
        map("n", "s", track_actions.change_mark_view)
        map("n", "<C-b>", track_actions.delete_buffer)
        map("n", "<C-j>", track_actions.move_view_next)
        map("n", "<C-k>", track_actions.move_view_previous)

        map("i", "<C-d>", track_actions.delete_view)
        map("i", "<C-n>", track_actions.move_view_next)
        map("i", "<C-p>", track_actions.move_view_previous)
        map("i", "<C-e>", track_actions.change_mark_view)
        return true -- compulsory
      end,
      disable_devicons = false,
    },
  },
  -- do not mark files that contain these patterns
  exclude = {
    ["^%.git/.*$"] = true,
    ["^%.git$"] = true,
    ["^LICENSE$"] = true,
  },
  -- dev / debugging
  log = {
    plugin = "track",
    level = "warn",
  },
}
```

</details>

## Theme

Modify these to change colors. This section is mainly geared towards theme plugin authors.

<details>

```lua
HI("TrackPadTitle", { link = "TelescopeResultsTitle" })
HI("TrackPadEntryFocused", { foreground = "#7AB0DF" })
HI("TrackPadAccessible", { foreground = "#79DCAA" })
HI("TrackPadInaccessible", { foreground = "#F87070" })
HI("TrackPadFocused", { foreground = "#7AB0DF" })
HI("TrackPadMarkListed", { foreground = "#4B5259" })
HI("TrackPadMarkUnlisted", { foreground = "#C397D8" })
HI("TrackPadMissing", { foreground = "#FFE59E" })
HI("TrackPadLocked", { foreground = "#E37070" })
HI("TrackPadDivide", { foreground = "#4B5259" })

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
HI("TrackBundlesIndex", { foreground = "#54CED6" })
```

</details>

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
```

## Credits

- harpoon
- @nikfp
