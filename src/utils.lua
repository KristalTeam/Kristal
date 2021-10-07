local utils = {}

function utils.copy(tbl, deep)
    local new_tbl = {}
    for k,v in pairs(tbl) do
        if type(v) == "table" and deep then
            new_tbl[k] = utils.copy(v, true)
        else
            new_tbl[k] = v
        end
    end
    return new_tbl
end

local function dumpKey(key)
    if type(key) == 'table' then
        return '('..tostring(key)..')'
    elseif type(key) == 'string' and not key:find("[^%a_%-]") then
        return key
    else
        return '['..utils.dump(key)..']'
    end
end

function utils.dump(o)
    if type(o) == 'table' then
        local s = '{'
        local cn = 1
        if #o ~= 0 then
            for _,v in ipairs(o) do
                if cn > 1 then s = s .. ', ' end
                s = s .. utils.dump(v)
                cn = cn + 1
            end
        else
            for k,v in pairs(o) do
                if cn > 1 then s = s .. ', ' end
                s = s .. dumpKey(k) .. ' = ' .. utils.dump(v)
                cn = cn + 1
            end
        end
        return s .. '}'
    elseif type(o) == 'string' then
        return '"' .. o .. '"'
    else
        return tostring(o)
    end
end

function utils.split(str, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(str, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

function utils.hook(target, func)
    return function(...)
        return func(target, ...)
    end
end

function utils.getFilesRecursive(dir)
    local result = {}

    local paths = love.filesystem.getDirectoryItems(dir)
    for _,path in ipairs(paths) do
        local info = love.filesystem.getInfo(dir.."/"..path)
        if info then
            if info.type == "directory" then
                local inners = getFilesRecursive(dir.."/"..path)
                for _,inner in ipairs(inners) do
                    table.insert(result, path.."/"..inner)
                end
            else
                table.insert(result, path)
            end
        end
    end

    return result
end

return utils