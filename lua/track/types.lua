---@class TrackPickersViewsHooks
---@field on_open function This will be called before the picker window is opened.
---@field on_close function(buffer: number, picker: Picker) This will be called right after the picker window is closed.
---@field on_choose function(buffer: number, picker: Picker) Will be called after the choice is made and the picker os closed.
---@field on_serial function(entry: table, picker: Picker)|nil|false Map a callback numerical keys with respect to entry index.

---@class TrackPickersViewsIcons
---@field separator string Separator between columns in the views picker.
---@field missing string Indicator icon for representing a missing/deleted file.
---@field accessible string Indicator icon for representing a file that allows reading.
---@field inaccessible string Indicator icon for representing a file that does not allow reading from it.
---@field focused string Indicator icon for representing a file that is currently being edited on.
---@field listed string Indicator icon for representing if a file is already open.
---@field unlisted string Indicator icon for representing if a file is not open.
---@field file string Default file icon. This will be visible when `disable_devicons` is `true`.
---@field directory string Directory icon. This will be visible when a directory mark is added.

---Other config opts that are not documented here can be found at |telecope.nvim| help page.
---@class TrackPickersViews
---@field hooks TrackPickersViewsHooks Callbacks related to the views picker.
---@field save_on_close boolean Save state when the views telescope buffer is closed.
---@field switch_directory boolean Change directory and refresh picker if a marked directory is in state.
---@field icons TrackPickersViewsIcons File-indicators, state-indicators, separators and default icons.

---Other config opts that are not documented here can be found at |telecope.nvim| help page.
---@class TrackPickersBundles
---@field hooks TrackPickersBundlesHooks Callbacks related to the views picker.
---@field icons TrackPickersBundlesIcons File-indicators, state-indicators, separators and default icons.
---@field save_on_close boolean Save state when the bundles telescope buffer is closed.

---@class TrackPickersBundlesHooks
---@field on_open function This will be called before the picker window is opened.
---@field on_close function(buffer: number, picker: Picker) This will be called right after the picker window is closed.
---@field on_choose function(buffer: number, picker: Picker) Will be called after the choice is made and the picker os closed.
---@field on_serial function(entry: table, picker: Picker)|nil|false Map a callback numerical keys with respect to entry index.

---@class TrackPickersBundlesIcons

---@class TrackPickers
---@field views TrackPickersViews Configuration opts relating to the `views` telescope picker.
---@field bundles TrackPickersBundles Configuration opts relating to the `bundles` telescope picker.

---@class TrackLog
---@field level "error"|"warn"|"info"|"trace"|"debug"|"off" Log level. The higher the level is, lesser the STDOUT messages will be shown.
---@field plugin string Name of the plugin.

---@class TrackPad
---@field config table
---@field root_path? string Function that must return the path to the current working directory.
---@field save_on_close boolean Save state when the views pad buffer is closed.

---@class TrackOpts
---@field save_path string JSON file where the current state will be saved.
---@field root_path string|true Default `root_path`. Setting to to true fetches automatically.
---@field bundle_label string|true Default `bundle_label` to open based on `root_path`.
---@field disable_history boolean Change state of all bundle histories.
---@field maximum_history number Change the maximum number of marks to be stored in all bundle history tables.
---@field pickers TrackPickers Sub-configuration for telescope pickers.
---@field log TrackLog Sub-configuration for logging and debugging.
---@field pad TrackPad Sub-configuration for pad UI.
---@field exclude string[] Patterns that won't be allowed to be added into the marks list.

---@class Root
---@field path string Path to root.
---@field label? string Small description/title about the root.
---@field links? string[] Shortcuts to other roots.
---@field bundles Bundle[] Bundle map. Key is the same as `Bundle.label` and value is a `Bundle` instance.
---@field main string Master bundle. This is similar to the `main` branch in GIT.
---@field stashed? string Flag variable that will be set if a bundle has been stashed.
---@field previous? string Flag variable that will be set if the `main` bundle has an alternate bundle.
---@field disable_history? boolean Deleting bundles will not store said bundles in the `history` table.
---@field maximum_history? number Maximum number of bundles that are allowed to be in `history` table.
---@field history Bundle[] Deleted/Uneeded bundle are sent here. This acts as a recycle bin for bundles.
---@field _NAME string Type.

---@class RootFields
---@field path string Path to root.
---@field label? string Small description/title about the root.
---@field links? string[] Shortcuts to other roots.
---@field bundles? Bundle[] Bundle map. Key is the same as `Bundle.label` and value is a `Bundle` instance.
---@field main? string Master bundle. This is similar to the `main` branch in GIT.
---@field stashed? string Flag variable that will be set if a bundle has been stashed.
---@field previous? string Flag variable that will be set if the `main` bundle has an alternate bundle.
---@field disable_history? boolean Deleting bundles will not store said bundles in the `history` table.
---@field maximum_history? number Maximum number of bundles that are allowed to be in `history` table.
---@field history Bundle[] Deleted/Uneeded bundle are sent here. This acts as a recycle bin for bundles.

---@class Bundle
---@field label string Name of the bundle. Similar to setting a GIT branch name.
---@field disable_history? boolean Deleting marks will not store said marks in the `history` table.
---@field maximum_history? number Maximum number of marks that are allowed to be in `history` table.
---@field history Mark[] Deleted/Uneeded marks are sent here. This acts as a recycle bin for marks.
---@field marks table<string, Mark> Mark map. Key is the same as `Mark.path`. Therefore, no duplicates.
---@field views string[] Paths of newly added marks are inserted into this list. This is to maintain order.
---@field _NAME string Type.

---@class BundleFields
---@field label string Name of the bundle. Similar to setting a GIT branch name.
---@field disable_history? boolean Deleting marks will not store marks in the `history` table.
---@field maximum_history? number Maximum number of marks that are allowed to be in `history` table.
---@field history Mark[] Deleted/Uneeded marks are sent here. This acts as a recycle bin for marks.

---@alias MarkType "directory"|"link"|"file"

---A class that represents a mark. A mark is a path inside (most of the time)
---your current working directory. It serves as a project-scoped file-bookmark.
---@class Mark
---@field path string Path to mark.
---@field label? string Optional label for that the mark.
---@field absolute string Absolute path to mark.
---@field type? string Type of mark.
---@field _NAME string Type.

---@class MarkFields
---@field path string Path to mark.
---@field label? string Optional label for the mark.
---@field type? MarkType Optional type for the mark.

---@alias Core table
