require("love.image")

json = require("src.lib.json")

local args = {...}
local mdir = args[1]

local channel = love.thread.getChannel("assets")

local data = {
    assets = {
        texture = {},
        texture_data = {},
        fonts = {}
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
    if not love.filesystem.getInfo(dir) then return end

    -- Load textures
    for _,file in ipairs(getFilesRecursive(dir.."/sprites")) do
        if file:sub(-4) == ".png" then
            local short = file:sub(1, -5)
            data.assets.texture_data[short] = love.image.newImageData(dir.."/sprites/"..file)
        end
    end
    -- Load fonts
    for _,file in ipairs(getFilesRecursive(dir.."/fonts")) do
        if file:sub(-4) == ".ttf" then
            local short = file:sub(1, -5)
            data.assets.fonts[short] = dir.."/fonts/"..file
        end
    end
end

function loadData(dir)
    if not love.filesystem.getInfo(dir) then return end

    -- Load animations
    for _,file in ipairs(getFilesRecursive(dir.."/animations")) do
        if file:sub(-5) == ".json" then
            local short = file:sub(1, -6)
            local json_str = love.filesystem.read(dir.."/animations/"..file)
            local animations = json.decode(json_str)
            for k,v in pairs(animations) do
                data.data.animations[k] = v
            end
        end
    end
end

loadAssets(mdir and (mdir.."/assets") or "assets")
loadData(mdir and (mdir.."/data") or "data")

channel:push(data)
data = nil