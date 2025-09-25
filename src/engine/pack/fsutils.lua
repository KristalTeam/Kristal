local FSUtils = {}

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

return FSUtils