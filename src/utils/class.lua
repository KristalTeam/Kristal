MOD_SUBCLASSES = {}

DEFAULT_CLASS_NAME_GETTER = function(k) return _G[k] end
CLASS_NAME_GETTER = DEFAULT_CLASS_NAME_GETTER

---@diagnostic disable-next-line: lowercase-global
function isClass(o)
    return type(o) == "table" and getmetatable(o) and true or false
end

---@class BaseClass
---@overload fun() : BaseClass
---@field id string|nil The ID of the class.
---@field super table|BaseClass|nil The base class of the class.
---@field clone fun(self: BaseClass) : BaseClass Makes a clone of the class.
---@field includes fun(self: BaseClass, class: table|BaseClass) : included : boolean Returns whether if `self` is a child class of `class`.

--- Creates a new class, which can then be instantiated by calling it as a function.
---
---@generic T : table|BaseClass
---
---@param include? T|string  # The class to extend from. If passed as a string, will be looked up from the current registry (e.g. `scripts/data/actors` if creating an actor) or the global namespace.
---@param id? string|boolean # The id of the class used for registry. If `true`, will use the `id` field of the included class.
---
---@return T class           # The new class, extended from `include` if provided.
---@return T super           # Allows calling methods from the base class. `self` must be passed as the first argument to each method.
---
return function(include, id)
    local o = {}
    if include then
        if type(include) == "string" then
            local r = CLASS_NAME_GETTER(include)
            if not r then
                error("Failed to include "..include)
            end
            if id == true then
                id = r.id or include
            end
            include = r
        end
        o.__includes = include
    end
    local class, super = _Class(o), setmetatable({}, {__index = function(t, k)
        if k == "super" then
            if include ~= nil then
                include = getmetatable(include) and {include} or include
                return include[1].__super
            end
            return nil
        end
        return function(a, ...)
            if include ~= nil then
                include = getmetatable(include) and {include} or include
                for _,c in ipairs(include) do
                    if c[k] then
                        if a == t then
                            return c[k](...)
                        else
                            return c[k](a, ...)
                        end
                    end
                end
            end
        end
    end})
    class.id = id
    class.__super = super
    class.__includers = {}
    for c,_ in pairs(class.__includes_all) do
        if c ~= class then
            c.__includers = c.__includers or {}
            table.insert(c.__includers, class)
            if Mod then
                MOD_SUBCLASSES[c] = MOD_SUBCLASSES[c] or {}
                table.insert(MOD_SUBCLASSES[c], class)
            end
        end
    end
    class.__dont_include["__super"] = true
    class.__dont_include["__includers"] = true
    return class, super
end