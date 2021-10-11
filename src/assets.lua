local assets = {}

function assets.clear()
    assets.loaded = false
    assets.data = {
        texture = {},
        texture_data = {},
        frame_ids = {},
        frames = {},
        fonts = {}
    }
end

function assets.loadData(data)
    utils.merge(assets.data, data, true)

    -- thread can't create images, we do it here
    for key,image_data in pairs(data.texture_data) do
        assets.data.texture[key] = love.graphics.newImage(image_data)
    end

    -- create frame tables with images
    for _,ids in pairs(data.frame_ids) do
        for key,id in pairs(ids) do
            assets.data.frames[key] = assets.data.texture[id]
        end
    end

    for key,path in pairs(data.fonts) do
        assets.data.fonts[key] = love.graphics.newFont(path, 32, "mono")
    end

    assets.loaded = true
end

function assets.getFont(path)
    if path:sub(1, 1) == "^" then
        assets.data.fonts[path] = assets.data.fonts[path] or love.graphics.newFont(path:sub(2)..".ttf", 32, "mono")
    end
    return assets.data.fonts[path]
end

function assets.getTexture(path)
    if path:sub(1, 1) == "^" then
        assets.data.texture[path] = assets.data.texture[path] or love.graphics.newImage(path:sub(2)..".png")
    end
    return assets.data.texture[path]
end

function assets.getTextureData(path)
    if path:sub(1, 1) == "^" then
        assets.data.texture_data[path] = assets.data.texture_data[path] or love.image.newImageData(path:sub(2)..".png")
    end
    return assets.data.texture_data[path]
end

function assets.getFrames(path)
    return assets.data.frames[path] or {}
end

function assets.getFrameIds(path)
    return assets.data.frame_ids[path] or {}
end

assets.clear()

return assets