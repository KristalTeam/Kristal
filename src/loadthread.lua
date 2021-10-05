require("love.image")

local args = {...}
local mdir = args[1]

local channel = love.thread.getChannel("assets")

local data = {
    texture = {},
    texture_data = {}
}

function getFilesRecursive(dir)
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

function loadData(dir)
    -- Load textures
    for _,file in ipairs(getFilesRecursive(dir.."/sprites")) do
        if file:sub(-4) == ".png" then
            local short = file:sub(1, -5)
            data.texture_data[short] = love.image.newImageData(dir.."/sprites/"..file)
        end
    end
end

loadData("assets")
if mdir ~= nil then
    loadData(mdir)
end

channel:push(data)
data = nil