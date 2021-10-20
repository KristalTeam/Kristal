function isClass(o)
    return o and getmetatable(o) and true or false
end

local function get(t, k, c)
    if type(k) == "string" and k:sub(1, 1) ~= "_" then
        local getters = rawget(c, "__getters")
        if getters and getters[k] then
            return (rawget(t, getters[k]) or rawget(c, getters[k]))(t)
        end
    end
    return c[k]
end

local function set(t, k, v)
    if type(k) == "string" and k:sub(1, 1) ~= "_" then
        local setters = t.__setters
        if setters and setters[k] then
            t[setters[k]](t, v)
        end
    end
    rawset(t, k, v)
end

return setmetatable({}, {__index=_Class, __call = function(_, include, o, getsetters)
    if include and not getmetatable(include) then
        o = include
        include = nil
    elseif not o then
        o = {}
    end
    if include then
        o.__includes = include
    end

    local class = _Class(o)
    class.__getters = class.__getters or {}
    class.__setters = class.__setters or {}
    if getsetters then
        for k,v in pairs(getsetters.getters or {}) do
            class.__getters[k] = v
        end
        for k,v in pairs(getsetters.setters or {}) do
            class.__setters[k] = v
        end
    end

    setmetatable(class, {
        __call = function(c, ...)
            local o = setmetatable({__class_index = c}, {
                __index = function(t, k) return get(t, k, c) end,
                __newindex = set
            })
            o:init(...)
            return o
        end
    })

    return class, setmetatable({}, {__index = function(t, k)
        return function(...)
            local args = {...}
            if #args > 0 then
                if args[1] == t then
                    table.remove(args, 1)
                end
                if include ~= nil then
                    include = getmetatable(include) and {include} or include
                    for _,c in ipairs(include) do
                        if c[k] then
                            return c[k](unpack(args))
                        end
                    end
                end
            end
        end
    end})
end})