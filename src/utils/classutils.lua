---@class ClassUtils
local ClassUtils = {}

---
--- Returns the name of a given class, using the name of the global variable for the class. \
--- If it cannot find a global variable associated with the class, it will instead return the name of the class it extends, along with the class's ID.
---
---@param class table           # The class instance to check.
---@param parent_check? boolean # Whether the function should only return the extended class, and not attach the class's ID, if the class does not have a global name.
---@return string? name         # The name of the class, or `nil` if it cannot find one.
---
function ClassUtils.getClassName(class, parent_check)
    -- If the class is a global variable, return its name.
    for k, v in pairs(_G) do
        if class.__index == v then
            return k
        end
    end
    -- If the class doesn't have a global variable, find the name of the highest class it extends.
    for i, v in ipairs(class.__includes) do
        local name = ClassUtils.getClassName(v, true)
        if name then
            if not parent_check and class.id then
                -- If the class has an ID, append it to the name of its parent class.
                return name .. "(" .. class.id .. ")"
            else
                return name
            end
        end
    end
end

local special_class_variables = {
    __dont_include = true,
    __includes = true,
    __includes_all = true,
    __index = true,
    __super = true,
    __includers = true,

    init = true,
    include = true,
    includes = true,
    clone = true,
    canDeepCopy = true,
    canDeepCopyKey = true
}

local function next_noclassvars(t, k)
    local v
    repeat
        k, v = next(t, k)
    until not special_class_variables[k]
    return k, v
end

--- Iterates through the fields of a class (e.g. `pairs`) excluding special class variables and functions
---@generic T : table
---@generic K, V
---@param class T
---@return (fun(table: table<K, V>, index?: K):K, V), T
function ClassUtils.iterClass(class)
    return next_noclassvars, class
end

return ClassUtils
