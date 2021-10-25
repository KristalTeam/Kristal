function isClass(o)
    return o and getmetatable(o) and true or false
end

return setmetatable({}, {__index=_Class, __call = function(_, include, o)
    o = o or {}
    if include then
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