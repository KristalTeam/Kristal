local FileSystem = {}

function FileSystem.getFilesRecursive(dir)
    local result = {}

    local paths = love.filesystem.getDirectoryItems(dir)
    for _,path in ipairs(paths) do
        local info = love.filesystem.getInfo(dir.."/"..path)
        if info then
            if info.type == "directory" then
                local inners = FileSystem.getFilesRecursive(dir.."/"..path)
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

return FileSystem