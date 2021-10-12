return setmetatable({}, {__index=_Class, __call = function(_, include, o)
    if include and not getmetatable(include) then
        o = include
        include = nil
    elseif not o then
        o = {}
    end
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