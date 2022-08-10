---@diagnostic disable: undefined-global
--[[
Copyright (c) 2010-2013 Matthias Richter

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]--

local function include_helper(to, from, seen)
    if from == nil then
        return to
    elseif type(from) ~= 'table' then
        return from
    elseif seen[from] then
        return seen[from]
    end

    seen[from] = to
    for k,v in pairs(from) do
        if from.__dont_include and from.__dont_include[k] then
            -- skip
        else
            k = include_helper({}, k, seen) -- keys might also be tables
            if to[k] == nil then
                to[k] = include_helper({}, v, seen)
            end
        end
    end
    return to
end

-- deeply copies `other' into `class'. keys in `other' that are already
-- defined in `class' are omitted
local function include(class, other)
    return include_helper(class, other, {})
end

-- returns a deep copy of `other'
local function clone(other)
    return Utils.copy(other, true)
    --return setmetatable(include({}, other), getmetatable(other))
end

local function get_all_includes(class)
    local includes = {[class] = true}
    for _, other in ipairs(class.__includes) do
        if type(other) == "string" then
            other = _G[other]
        end
        for c, _ in pairs(get_all_includes(other)) do
            includes[c] = true
        end
    end
    return includes
end

local function includes(class, other)
    if type(other) == "string" then
        other = _G[other]
    end
    return class.__includes_all[other] and true or false
end

local function index(class, t, k)
    local cv = rawget(class, k)
    if cv ~= nil then
        return cv
    end
    local gv = rawget(class, "__getters")[k]
    if gv ~= nil then
        return gv(t)
    end
end

local function newindex(class, t, k, v)
    local iv = rawget(class, "__setters")[k]
    if iv ~= nil then
        iv(t, v)
        return
    end
    rawset(t, k, v)
end

local function class_index(t, k)
    local prop = rawget(t, "__propfuncs")[k]
    if prop ~= nil then
        return prop
    end
end

local function class__newindex(t, k, v)
    if type(k) == "string" then
        local property_part = k:sub(1, 4)
        if property_part == "get_" then
            rawget(t, "__propfuncs")[k] = v
            rawget(t, "__getters")[k:sub(5)] = v
            return
        elseif property_part == "set_" then
            rawget(t, "__propfuncs")[k] = v
            rawget(t, "__setters")[k:sub(5)] = v
            return
        end
    end
    rawset(t, k, v)
end

local function new(class)
    -- mixins
    class = class or {}  -- class can be nil
    class.__includes = class.__includes or {}
    if getmetatable(class.__includes) then class.__includes = {class.__includes} end

    class.__includes_all = get_all_includes(class)

    for _, other in ipairs(class.__includes) do
        if type(other) == "string" then
            other = _G[other]
        end
        include(class, other)
    end

    -- class implementation
    class.__class     = class
    --class.__index     = class
    class.__index     = function(t, k)    return index(class, t, k) end
    class.__newindex  = function(t, k, v) newindex(class, t, k, v)  end
    class.__getters   = class.__getters or {}
    class.__setters   = class.__setters or {}
    class.__propfuncs = class.__propfuncs or {}
    class.init        = class.init      or class[1] or function() end
    class.include     = class.include   or include
    class.includes    = class.includes  or includes
    class.clone       = class.clone     or clone

    class.canDeepCopy    = class.canDeepCopy    or function() return true end
    class.canDeepCopyKey = class.canDeepCopyKey or function(key) return true end

    -- keys that shouldn't be included from this class
    class.__dont_include = {
        ["__class"] = true,
        ["__dont_include"] = true,
        ["__includes"] = true,
        ["__includes_all"] = true,
        ["__index"] = true,
        ["__newIndex"] = true,
        ["include"] = true,
        ["includes"] = true,
    }

    -- constructor call
    return setmetatable(class, {__call = function(c, ...)
        local o = setmetatable({}, c)
        rawset(o, "__class", c)
        o:init(...)
        return o
    end, __index = class_index, __newindex = class__newindex})
end

-- interface for cross class-system compatibility (see https://github.com/bartbes/Class-Commons).
if class_commons ~= false and not common then
    common = {}
    function common.class(name, prototype, parent)
        return new{__includes = {prototype, parent}}
    end
    function common.instance(class, ...)
        return class(...)
    end
end


-- the module
return setmetatable({new = new, include = include, includes = includes, clone = clone},
    {__call = function(_,...) return new(...) end})
