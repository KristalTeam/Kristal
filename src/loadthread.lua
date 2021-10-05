require("love.image")

JSON = require("src.lib.json")

local args = {...}
local mdir = args[1]

local channel = love.thread.getChannel("assets")

local data = {
    assets = {
        texture = {},
        texture_data = {}
    },
    data = {
        animations = {}
    }
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

function loadAssets(dir)
    -- Load textures
    for _,file in ipairs(getFilesRecursive(dir.."/sprites")) do
        if file:sub(-4) == ".png" then
            local short = file:sub(1, -5)
            data.assets.texture_data[short] = love.image.newImageData(dir.."/sprites/"..file)
        end
    end
end

function loadData(dir)
    -- Load animations
    for _,file in ipairs(getFilesRecursive(dir.."/animations")) do
        if file:sub(-5) == ".json" then
            local short = file:sub(1, -6)
            local json_str = love.filesystem.read(dir.."/animations/"..file)
            local animations = JSON.decode(json_str)
            for k,v in pairs(animations) do
                data.data.animations[k] = v
            end
        end
    end
end

loadAssets("assets")
if mdir ~= nil then
    loadAssets(mdir.."/assets")
end

loadData("data")
if mdir ~= nil then
    loadData(mdir.."/data")
end

channel:push(data)
data = nil