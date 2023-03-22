<samp>

# track.nvim

Harpoon like file tracking. Supercharged by [telescope.nvim](https:/github.com/nvim-telescope/telescope.nvim).

## Install

```lua
-- lazy.nvim and packer.nvim
{ "dharmx/track.nvim" }

-- lazy.nvim and packer.nvim load on cmd
{ "dharmx/track.nvim", cmd = { "Track", "Mark", "Unmark" } }
```

## Config

```lua
local ok, track = pcall(require, "track")
if not ok then return end

-- INFO: These are optional track.setup() shouild simply work.
track.setup({
  prompt_prefix = " > ",
  previewer = false,
  save = {
    on_mark = true,
    on_unmark = true,
  },
  layout_config = {
    preview_cutoff = 1,
    width = function(_, max_columns, _)
      return math.min(max_columns, 80)
    end,
    height = function(_, _, max_lines)
      return math.min(max_lines, 15)
    end,
  },
  border = true,
  borderchars = {
    prompt = { "─", "│", " ", "│", "╭", "╮", "│", "│" },
    results = { "─", "│", "─", "│", "├", "┤", "╯", "╰" },
    preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
  },
})
```

## Map

```lua
local function lnmap(key, ...)
  vim.keymap.set("n", "<leader>" .. key, ...)
end

lnmap("xx", ":Track<CR>", { desc = "Show/Hide trackmenu.", silent = true })
lnmap("xm", ":Mark<CR>", { desc = "Add file to tracklist.", silent = true })
lnmap("xu", ":Unmark<CR>", { desc = "Remove file from tracklist.", silent = true })
```

## Defaults

> NOTE: Subject to heavy change.

```lua
local ok, track = pcall(require, "track")
if not ok then return end

track.setup({
  state_path = vim.fn.stdpath("state") .. "/track.json",
  prompt_prefix = "  ",
  previewer = false,
  save = {
    on_mark = false,
    on_unmark = false,
    on_close = true,
  },
  layout_config = { width = 0.3, height = 0.4 },
  callbacks = {
    on_open = util.mute,
    on_close = util.mute,
    on_mark = util.mute,
    on_unmark = util.mute,
    on_save = util.mute,
    on_delete = function(_, picker)
      local entries = vim.F.if_nil(picker:get_multi_selection(), {})
      if #entries == 0 then table.insert(entries, picker:get_selection()) end
      vim.tbl_map(function(entry)
        require("track.mark").unmark(entry.value)
      end, entries)
    end,
    on_choose = function(_, picker)
      local entries = vim.F.if_nil(picker:get_multi_selection(), {})
      if #entries == 0 then table.insert(entries, picker:get_selection()) end
      vim.tbl_map(function(entry)
        vim.cmd("confirm edit " .. entry.value)
      end, entries)
    end,
  },
  roots = {
    [vim.fn.config("config")] = {
      label = "Neovim Configuration.",
      describe = "EMPTY",
      marks = { "init.lua", "init.vim", "README.md" },
    }
  },
})
```

## Cache

```json
{
  "/home/maker/Dotfiles/neovim/track.nvim": {
    "describe": "NONE",
    "label": "NONE",
    "marks": {
      ".github/README.md": {
        "exists": true,
        "absolute": "/home/maker/Dotfiles/neovim/track.nvim/.github/README.md",
        "position": [1, 0]
      },
      "LICENSE": {
        "exists": true,
        "absolute": "/home/maker/Dotfiles/neovim/track.nvim/LICENSE",
        "position": [1, 20]
      }
    }
  },
  "/home/maker/Dotfiles/dots.sh/config/_term/nvim": {
    "describe": "Configuration directory for Neovim. Commonly contains a init.lua/init.vim.",
    "label": "Neovim Configuration",
    "marks": {
      "init.lua": {
        "exists": true,
        "absolute": "/home/maker/Dotfiles/dots.sh/config/_term/nvim/init.lua",
        "position": [1, 0]
      }
    }
  }
}
```

## Demo

![demo](./demo.gif)

</samp>
