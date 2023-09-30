-- Various metatable tweaks

local string_metatable = getmetatable(" ")

-- "string" + "string2"
string_metatable.__add = function (a, b) return a .. tostring(b) end

-- "string" * number
string_metatable.__mul = function (a, b)
    local result = ""
    for i = 1, b do
        result = result .. a
    end
    return result
end

-- ("string")[1]
string_metatable.__index = function (a, b)
    if type(b) == "number" then
        return string.sub(a, b, b)
    else
        return string[b]
    end
end
