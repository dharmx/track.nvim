---@class TrackSave
---@field on_views_close boolean Save state when the views telescope buffer is closed.
---@field on_bundles_close boolean Save state when the bundles telescope buffer is closed.

---@class TrackPickersViewsHooks
---@field on_open function This will be called before the picker window is opened.
---@field on_close function(buffer: number, picker: Picker) This will be called right after the picker window is closed.
---@field on_choose function(buffer: number, picker: Picker) Will be called after the choice is made and the picker os closed.

---@class TrackPickersViewsTrack
---@field bundle_label? string string Function that must return the root path.
---@field root_path? string Function that must return the path to the current working directory.

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
---@field track TrackPickersViewsTrack Defaults like `bundle_label` and `root_path` for calling the view list.
---@field icons TrackPickersViewsIcons File-indicators, state-indicators, separators and default icons.

-- TODO: START {{{

---Other config opts that are not documented here can be found at |telecope.nvim| help page.
---@class TrackPickersBundles
---@field hooks TrackPickersBundlesHooks Callbacks related to the views picker.
---@field track TrackPickersBundlesTrack Defaults like `bundle_label` and `root_path` for calling the view list.
---@field icons TrackPickersBundlesIcons File-indicators, state-indicators, separators and default icons.

---@class TrackPickersBundlesHooks
---@field on_open function This will be called before the picker window is opened.
---@field on_close function(buffer: number, picker: Picker) This will be called right after the picker window is closed.
---@field on_choose function(buffer: number, picker: Picker) Will be called after the choice is made and the picker os closed.

---@class TrackPickersBundlesTrack
---@field root_path? string Function that must return the path to the current working directory.
---@field bundle_label? string string Function that must return the root path.

---@class TrackPickersBundlesIcons

-- TODO: END }}}

---@class TrackPickers
---@field views TrackPickersViews Configuration opts relating to the `views` telescope picker.
---@field bundles TrackPickersBundles Configuration opts relating to the `bundles` telescope picker.

---@class TrackLog
---@field level "error"|"warn"|"info"|"trace"|"debug"|"off" Log level. The higher the level is, lesser the STDOUT messages will be shown.
---@field plugin string Name of the plugin.

---@class TrackOpts
---@field savepath string JSON file where the current state will be saved.
---@field disable_history boolean Change state of all bundle histories.
---@field maximum_history number Change the maximum number of marks to be stored in all bundle history tables.
---@field save TrackSave Sub-configuration for when current state will be saved.
---@field pickers TrackPickers Sub-configuration for telescope pickers.
---@field log TrackLog Sub-configuration for logging and debugging.

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
---@field type? MarkType Type of mark.
---@field _NAME string Type.

---@class MarkFields
---@field path string Path to mark.
---@field label? string Optional label for the mark.
---@field type? MarkType Optional type for the mark.
