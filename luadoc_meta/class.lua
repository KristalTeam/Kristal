---@meta

---
--- Creates a new class, which can then be instantiated by calling it as a function.
---
---@generic T : Class|function
---
---@param include? T|string     # The class to extend from. If passed as a string, will be looked up from the current registry (e.g. `scripts/data/actors` if creating an actor) or the global namespace.
---@param id? string|boolean      # The id of the class used for registry. If `true`, will use the `id` field of the included class.
---
---@return T class                # The new class, extended from `include` if provided.
---@return T|superclass<T> super  # Allows calling methods from the base class. `self` must be passed as the first argument to each method.
---
function Class(include, id) end

---@class Class
---
---@field private __index self
---@field private __super Class|superclass<self>|nil
---@field private __includes Class[]
---@field private __includes_all { [Class]: boolean }
---@field private __dont_include { [string]: boolean }
---
---@field private init fun(self: Class, ...)
---
---@field id string|nil                      # The ID of the class.
---
---@overload fun(self: Class, ...) : Class
local _Class = {}

---@class superclass<T> : { super: T|superclass<T>|nil }

---
--- Returns a deep copy of this class.
---
---@return self
---
function _Class:clone() end

---
--- Returns whether this class will be deep copied
--- when a table/class which contains it is deep copied.
---
---@return boolean
---
function _Class:canDeepCopy() end

---
--- Returns whether the specified variable from this class
--- should be deep copied.
---
---@param key string
---@return boolean
---
function _Class:canDeepCopyKey(key) end

---
--- Checks whether this class is or extends another class.
---
---@param other Class|function
---@return boolean
---
function _Class:includes(other) end

---
--- *(Called internally)*
--- Deeply copies `other` into `class`.
--- Keys in `other` that are already defined in `class` are omitted.
---
---@private
---@generic T : Class|function
---@param other T
---@return self|T
---
function _Class:include(other) end