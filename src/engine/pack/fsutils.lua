local FSUtils = {}

--- Joins provided paths
--- @param ... string
--- @return string|nil
function FSUtils.path(...)
    local arg = {...}
    if #arg == 0 then
        return nil
    end
    local p = table.remove(arg, 1)
    for _, v in ipairs(arg) do
        p = p.."/"..v
    end
    return p
end

function FSUtils.modPaths(modID)
    local build = assert(FSUtils.path("pack", "build", modID)) 
    local cache = assert(FSUtils.path("pack", "cache"))
    local dist = assert(FSUtils.path("pack", "dist", modID))
    return {
        build = build,
        cache = cache,
        dist = dist
    }
end

return FSUtils