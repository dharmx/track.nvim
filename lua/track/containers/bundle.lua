---A virtual mark-map. Allows one to create different versions of marks that
---is better suitted to a part of a project that you might be working on.
---
---For instance:
---Working at part `A` of a project will require you to frequent
---`A1`, `A2` and `A3` files and working part `B` would require `B1`, `B2`, `B3`.
---Normally, without bundles one may put all project files (`A1-3` and `B1-3`) in
---the mark-list or, remove all `A1-3` files and add `B1-3` files and vice-versa.
---This adds overhead.
---Now, with bundles you just need to **stash** the current bundle which contains A1-3
---(say) and add `B1-3` to the new bundle. (Yes, this is just like GIT.)
local Bundle = {}
Bundle.__index = Bundle
setmetatable(Bundle, {
  __call = function(class, ...)
    local self = setmetatable({}, class)
    self:_new(...)
    self._callize_views(self)
    self._callize_marks(self)
    return self
  end,
})

local Mark = require("track.containers.mark")
local Log = require("track.log")

---Create a new `Bundle` object.
---@param fields BundleFields Available bundle attributes/fields.
---@return Bundle
function Bundle:_new(fields)
  local fieldstype = type(fields)
  assert(fieldstype ~= "table" or fieldstype ~= "string", "expected: fields: string|table found: " .. fieldstype)
  if fieldstype == "string" then fields = { label = fields } end
  assert(fields.label and type(fields.label) == "string", "fields.label: string cannot be nil")

  self.label = fields.label
  self.marks = {}
  self.views = {}
  self.disable_history = vim.F.if_nil(fields.disable_history, true)
  self.maximum_history = vim.F.if_nil(fields.maximum_history, 10)
  self.history = vim.F.if_nil(fields.history, {})
  self._NAME = "bundle"
end

-- Metatable Setters {{{
---@private
---Helper for re-registering the `__call` metatable to `Bundle.views` field.
function Bundle:_callize_views()
  setmetatable(self.views, {
    ---@return Mark[]?
    __call = function(views, _)
      local view_marks = {}
      for _, view in ipairs(views) do
        table.insert(view_marks, self.marks[view])
      end
      return view_marks
    end,
  })
end

---@private
---Helper for re-registering the `__call` metatable to `Bundle.marks` field.
function Bundle:_callize_marks()
  setmetatable(self.marks, {
    __call = function(marks, action)
      if action == "string" then return vim.tbl_keys(marks) end
      return vim.tbl_values(marks)
    end,
  })
end
-- }}}

---Add a mark into the `Bundle`.
---@param mark Mark|string `Mark` or, the path that will be turned into a `Mark`.
---@param label? string Title of the mark.
---@return Mark
function Bundle:add_mark(mark, label)
  if type(mark) == "table" and mark._NAME == "mark" then
    self.marks[mark.path] = mark
    Log.trace("Bundle.add_mark(): new mark " .. mark.path .. " has been added")
    return self.marks[mark.path]
  end
  -- if it does not exist then create it
  self.marks[mark] = Mark({ path = mark, label = label })
  -- adding a mark will add its path to the views table
  table.insert(self.views, mark)
  Log.trace("Bundle.add_mark(): new mark " .. mark .. " has been added")
  return self.marks[mark]
end

---Remove a mark from the Bundle. Returns the removed mark (if available).
---@param mark Mark|string `Mark` or, the path that will be removed from the `Bundle.marks` table.
---@return Mark
function Bundle:remove_mark(mark)
  local removed_mark
  if type(mark) == "table" and mark._NAME == "mark" then
    removed_mark = self.marks[mark.path]
  else
    removed_mark = self.marks[mark]
  end

  self.marks[removed_mark.path] = nil
  -- removing a mark will also remove its path from the views table
  -- how do I make this faster O(N) is not good.
  -- thinking more about this... can the marklist go beyond 100 :thonk:
  self.views = vim.tbl_filter(function(item) return item ~= removed_mark.path end, self.views)
  -- self.views is being overwritten which means any metatable will also be overwritten
  -- we need to re-register the __call metatable so that external parties can call
  -- Bundle.view() again.
  self:_callize_views()
  -- record history: removed marks will be inserted into the self.history table (by your will)
  self:insert_history(removed_mark)
  Log.trace("Bundle.remove_mark(): mark " .. removed_mark.path .. " has been removed")
  return removed_mark
end

---Reset the `Bundle`. All marks will be purged.
function Bundle:clear()
  for _, mark in pairs(self.marks) do
    self:insert_history(mark)
  end
  self.marks = {}
  self.views = {}
  -- re-attach __call.
  self:_callize_views()
  self:_callize_marks()
  Log.trace("Bundle.clear(): Bundle.marks and Bundle.views has been emptied")
end

---Insert mark into the history list.
---@param mark Mark The `Mark` object that needs to be inserted into the history list.
---@param force? boolean overrides `Bundle.disable_history`.
function Bundle:insert_history(mark, force)
  local mark_type = type(mark)
  assert(mark_type == "table" and mark._NAME == "mark", "mark: Mark cannot be nil.")
  if self.disable_history and not force then return end
  table.insert(self.history, 1, mark)
  if #self.history > self.maximum_history then table.remove(self.history, #self.history) end
  Log.trace("Bundle.insert_history(): mark " .. mark.path .. " has been recorded into history")
end

---Swap marks.
---@param a number
---@param b number
function Bundle:swap_marks(a, b)
  if not self.views[a] or not self.views[b] then return end
  local temp = self.views[a]
  self.views[a] = self.views[b]
  self.views[b] = temp
end

---Change a mark's path.
---@param mark Mark
---@param new_path string
function Bundle:change_mark_path(mark, new_path)
  assert(type(mark) == "table" and mark._NAME == "mark", "mark: restricted type")
  local new_mark = Mark({ path = new_path, label = mark.label })
  for index, view in ipairs(self.views) do
    if view == mark.path then
      self.views[index] = new_path
      self.marks[view] = nil
      self.marks[new_path] = new_mark
      return new_mark
    end
  end
end

---Check if the `Bundle` has any marks.
---@return boolean
function Bundle:empty() return vim.tbl_isempty(self.marks) end

return Bundle
