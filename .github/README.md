# track.nvim

Most over-engineered marking system. Harpoon like file tracking.
Supercharged by [telescope.nvim](https:/github.com/nvim-telescope/telescope.nvim).

<details>

![views](./views.png) 

![bundles](./bundles.png) 

</details>

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

Feature walkthrough.

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

- Open terminal by `:terminal ls /sys/class`
- Alternatively, you can also do `:edit term://ls /sys/class`
- Then `:Mark` that buffer.
- Open `:Track` and you should see the command being stored there.

See <samp>:help terminal</samp> for more details.

### Q. How do I mark a command that'll run on a particular directory?

- Open terminal by `:edit term:///home/dharmx//rg --files \| awk -F'.' '{print $NF}'`
- Then `:Mark` that buffer.
- Open `:Track` and you should see the command being stored there.
- Run it by pressing enter and it should run that command in that particualar directory.

Note that, if you mark with `:edit` then you would only need to escape pipes i.e. `| -> \|`.

### Q. What else can we mark?

- You can mark websites i.e. `:Mark https://www.google.com/search?q=gnu+rule34`.
- You can mark manpages i.e. `:Mark man://find(1)`.
- You can mark a directory as well.

Note that, selecting a directory i.e. tracked will `:chdir` into that directory and
refresh the UI for viewing that directory's marks. This behavior is off by default.

Additionally, while you can mark virtually anything, it is not recommended to do so.
This is because only a few filetypes are actually handled. For instance, marking a
PDF file and opening it won't open it in a PDF reader but in Neovim albeit you can
use `on_choose` for each UI to override that.

### Q. How do I exclude files that should not be marked?

Just pass an `exclude` list into the setup function.

```lua
-- we use lua regexp for this
require("track").setup({
  exclude = {
    vim.env.XDG_CONFIG_HOME .. "/nvim/.*", -- always skip
    "lua/track/pad%.lua", -- does not allow marking
    ["^%.git/.*$"] = true, -- does not allow marking
    ["^%.git$"] = false, -- allow marking
    ["^LICENSE$"] = true, -- does not allow marking
  },
})
```

Note that, Lua patterns are used for this normal regex expressions will not completely
work.

### Q. How do I unmark a website?

There's is no way of doing that. You'd need to open an UI and then press `dd`
on the entry that is a website.

### Q. What are serial mappings?

Open any UI and then press any entry's line number and it'll run the
`config.{pickers.views,pickers.bundles,pad}.hooks.on_serial` callback on it.

So, by default if you open `:Track pad` and press `3` then it should open the
entry at that line number.

## Defaults

```lua
local if_nil = vim.F.if_nil
local util = require("track.util")

M._defaults = {
  save_path = vim.fn.stdpath("state") .. "/track.json",
  root_path = true, -- true for auto fetching the root_path, string otherwise
  bundle_label = true, -- same as root_path
  pad = {
    icons = {
      save_done = "",
      save = "",
      directory = "",
      terminal = "",
      manual = "",
      site = "",
    },
    serial_maps = true,
    save_on_close = true,
    path_display = {
      absolute = false,
      shorten = 1,
    },
    hooks = {
      on_choose = util.open_entry,
      on_serial = util.open_entry,
      on_close = util.mute,
    },
    mappings = {
      n = {
        q = function(self) self:close() end,
        ["<C-s>"] = function(self) self:sync(true) end,
      },
    },
    disable_devicons = true,
    config = {
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
        on_serial = function(entry) -- mappings WRT to line numbers
          local root, _ = util.root_and_bundle()
          root:change_main_bundle(entry.value.label)
        end,
        on_choose = function(self)
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
      switch_directory = true, -- switch when a directory i.e. marked is a root object
      save_on_close = true, -- save when the view telescope picker is closed
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
    ["^%.git/.*$"] = true, -- or, false
    ["^%.git$"] = true,
    ["^LICENSE$"] = true,
  },
  -- debugging
  log = {
    plugin = "track",
    level = "warn",
  },
  -- dev features / not implemented
  maximum_history = 10,
  disable_history = true, -- do not recycle deleted marks
}
```

## Integrations

Use track.nvim for marking elements in other plugins.

### rnvimr

Mark current selected file.

```lua
vim.g.rnvimr_action = {
  ["<C-t>"] = "NvimEdit Mark true",
}
```

## Theme

Modify these to change colors. This section is mainly geared towards theme plugin authors.

```lua
local function HI(...) vim.api.nvim_set_hl(0, ...) end

HI("TrackPadTitle", { link = "TelescopeResultsTitle" })
HI("TrackPadEntryFocused", { foreground = "#7AB0DF" })

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

## Caveats

Some features need special attention when using. Workarounds are always being on the way.
But, for the time being be careful.

### Marking when pad icons are enabled.

If `Pad` UI has `disable_devicons` set to `false` then, file paths (not URIs) that contains
spaces i.e. `~/Documents/cv for applying as reddit mod.md` then the file that will actually
be saved is `for applying as reddit mod.md` only.

A workaround for this is to have a dot or, any placeholder at the very beginning of the path
i.e., `= ~/Documents/cv for applying as reddit mod.md` this way only `= ` will be eliminated
and `~/Documents/cv for applying as reddit mod.md` will be saved.

### Unmarking manpages and commands.

This might not work all the time. No fixes for this.

### Preserving `$ENV_VAR` notations and not expanding it.

We normalize the mark paths so this not possible. But, if there's enough demand then I will
add it.

## Credits

- harpoon
- @nikfp
