---@class HookSystem
local HookSystem = {}

HookSystem.__MOD_HOOKS = {}

---
--- Replaces a function within a class with a new function. \
--- Also allows calling the original function, allowing you to add code to the beginning or end of existing functions. \
--- `HookSystem.hook()` should always be called in `Mod:init()`. An example of how to hook a function is as follows:
--- ```lua
--- -- this code will hook 'Object:setPosition(x, y)', and will be run whenever that function is called
--- -- all class functions receive the object instance as the first argument. in this function, i name that argument 'obj', and it refers to whichever object is calling 'setPosition()'
--- HookSystem.hook(Object, "setPosition", function(orig, obj, x, y)
---     -- calls the original code (setting its position as normal)
---     orig(obj, x, y)
---     
---     -- sets 'new_x' and 'new_y' variables for the object instance
---     obj.new_x = x
---     obj.new_y = y
--- end)
--- ```
---
---@param target table                 # The class variable containing the function you want to hook.
---@param name string                  # The name of the function to hook.
---@param hook fun(orig:fun(...), ...) # The function containing the new code to replace the old code with. Receives the original function as an argument, followed by the arguments the original function receives.
---@param exact_func? boolean          # *(Used internally)* Whether the function should be replaced exactly, or whether it should be replaced with a function that calls the hook function. Should not be specified by users.
---
function HookSystem.hook(target, name, hook, exact_func)
    -- Get the original function.
    local orig = target[name]

    -- If a mod is currently loaded, store information about the hook so it can be disabled later.
    if Mod then
        table.insert(HookSystem.__MOD_HOOKS, 1, { target = target, name = name, hook = hook, orig = orig })
    end

    local orig_func = orig or function () end
    if not exact_func then
        -- If the function should not be copied directly (such as when we're applying hooks to sub-classes),
        -- create a new function that calls the hook function, giving it the original function as an argument.
        target[name] = function (...)
            return hook(orig_func, ...)
        end
    else
        -- Otherwise, just replace the function with the hook function.
        target[name] = hook
    end

    -- If the target is a class, we need to apply the hook to all sub-classes
    -- that reference the original function.
    if isClass(target) then
        for _, includer in ipairs(target.__includers or {}) do
            if includer[name] == orig then
                HookSystem.hook(includer, name, target[name], true)
            end
        end
    end
end

---@type metatable
HookSystem.HOOKSCRIPT_MT = {
    __newindex = function (self, k, v)
        self.__hookscript_super[k] = self.__hookscript_super[k] or self.__hookscript_class[k]
        assert(Mod)
        HookSystem.hook(self.__hookscript_class, k, v, true)
    end
}
---@generic T : Class|function
---
---@param include? T|`T`|string   # The class to extend from. If passed as a string, will be looked up from the current registry (e.g. `scripts/data/actors` if creating an actor) or the global namespace.
---
---@return T class                # The new class, extended from `include` if provided.
---@return T|superclass<T> super  # Allows calling methods from the base class. `self` must be passed as the first argument to each method.
function HookSystem.hookScript(include)
    if type(include) == "string" then
        local r = CLASS_NAME_GETTER(include)
        if not r then
            error({
                included = include,
                msg = "Failed to include " .. include
            })
        end
        include = r
    end
    local super = { super = include.__super }
    local class = setmetatable({ __hookscript_super = super, __hookscript_class = include }, HookSystem.HOOKSCRIPT_MT)
    return class, super
end

---
--- Returns a function that calls a new function, giving it an older function as an argument. \
--- Essentially, it's a version of `HookSystem.hook()` that works with local functions.
---
---@generic T : function
---@param old_func T                # The function to be passed into the new function.
---@param new_func fun(orig:T, ...) # The new function that will be called by the result function.
---@return T result_func            # A function that will call the new function, providing the original function as an argument, followed by any other arguments that this function receives.
---
function HookSystem.override(old_func, new_func)
    old_func = old_func or function () end
    return function (...)
        return new_func(old_func, ...)
    end
end

return HookSystem
