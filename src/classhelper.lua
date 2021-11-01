DEFAULT_CLASS_NAME_GETTER = function(k) return _G[k] end
CLASS_NAME_GETTER = DEFAULT_CLASS_NAME_GETTER

function isClass(o)
    return type(o) == "table" and getmetatable(o) and true or false
end

return setmetatable({}, {__index=_Class, __call = function(_, include, o)
    o = o or {}
    if include then
        if type(include) == "string" then
            local r = CLASS_NAME_GETTER(include)
            if not r then
                error{included=include, msg="Failed to include "..include}
            end
            include = r
        end
        o.__includes = include
    end
    return _Class(o), setmetatable({}, {__index = function(t, k)
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