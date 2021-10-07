function newClass(include, o)
    if include and not getmetatable(include) then
        o = include
        include = nil
    elseif not o then
        o = {}
    end
    if include then
        o.__includes = include
    end
    return Class(o)
end

super = setmetatable({},{__index=function(tbl,k)
    return function(...)
        local args = {...}
        if #args > 0 then
            if args[1] == tbl then
                table.remove(args, 1)
            end
            local includes = args[1].__includes
            if includes ~= nil then
                includes = getmetatable(includes) and {includes} or includes
                for _,c in ipairs(includes) do
                    if c[k] then
                        return c[k](unpack(args))
                    end
                end
            end
        end
    end
end})