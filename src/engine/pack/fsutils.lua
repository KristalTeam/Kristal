local FSUtils = {}

--- Joins provided paths
--- @param ... string
--- @return string|nil
function FSUtils.path(...)
    local arg = { ... }
    if #arg == 0 then
        return nil
    end
    local p = table.remove(arg, 1)
    for _, v in ipairs(arg) do
        p = p .. "/" .. v
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

function FSUtils.copy(from, to)
    local contents = love.filesystem.read(from)
    return love.filesystem.write(to, contents)
end

function FSUtils.recursiveCopy(folder, to, excludePattern)
    excludePattern = excludePattern or {}

    local filesTable = love.filesystem.getDirectoryItems(folder)
    for _, v in ipairs(filesTable) do
        local file = FSUtils.path(folder, v)
        local saveFile = FSUtils.path(to, v)
        local realDir = FSUtils.path(love.filesystem.getRealDirectory(file), file)
        local exclude = false
        for _, pat in ipairs(excludePattern) do
            if realDir:find(pat) ~= nil then
                exclude = true
            end
        end
        if exclude == false then
            local info = love.filesystem.getInfo(file)
            if info then
                if info.type == "file" then
                    print("Copying file " .. file .. " to " .. saveFile)
                    local ok, err = FSUtils.copy(file, saveFile)
                    if not ok then
                        print("Error: " .. err)
                    end
                elseif info.type == "directory" then
                    print("Traversing " .. file)
                    love.filesystem.createDirectory(saveFile)
                    FSUtils.recursiveCopy(file, saveFile, excludePattern)
                end
            end
        end
    end
end

function FSUtils.recursiveDel(folder)
    local filesTable = love.filesystem.getDirectoryItems(folder)
    for _, v in ipairs(filesTable) do
        local file = FSUtils.path(folder, v)
        local info = love.filesystem.getInfo(file)
        if info then
            if info.type == "file" then
                print("Removing " .. file)
                love.filesystem.remove(file)
            elseif info.type == "directory" then
                print("Traversing " .. file)
                FSUtils.recursiveDel(file)
                love.filesystem.remove(file)
            end
        end
    end
end

local function recursivelyExtract(folder, saveDir)
    local filesTable = love.filesystem.getDirectoryItems(folder)
    if saveDir ~= "" and not love.filesystem.isDirectory(saveDir) then
        love.filesystem.createDirectory(saveDir)
    end

    for _, f in ipairs(filesTable) do
        local file = FSUtils.path(folder, f)
        local saveFile = FSUtils.path(saveDir, f)
        if saveDir == "" then
            saveFile = f
        end

        if love.filesystem.isDirectory(file) then
            print("Traversing " .. file)
            love.filesystem.createDirectory(saveFile)
            recursivelyExtract(file, saveFile)
        else
            print("Extracting " .. file)
            love.filesystem.write(saveFile, tostring(love.filesystem.read(file)))
        end
    end
end

function FSUtils.extractZIP(file, dir)
    dir = dir or ""
    local temp = tostring(math.random(1, 2000))
    local success = love.filesystem.mount(file, temp)
    if success then
        recursivelyExtract(temp, dir)
    end
    love.filesystem.unmount(file)
end

function FSUtils.fuseFiles(file1, file2, out)
    local f1 = love.filesystem.read(file1)
    local f2 = love.filesystem.read(file2)
    return love.filesystem.write(out, f1 .. f2)
end

return FSUtils
