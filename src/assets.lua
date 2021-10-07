local assets = {
    loaded = false,
    data = {
        texture = {},
        texture_data = {},
        fonts = {}
    }
}

function assets.loadData(data)
    assets.data = data

    -- thread can't create images, we do it here
    for key,image_data in pairs(assets.data.texture_data) do
        assets.data.texture[key] = love.graphics.newImage(image_data)
    end

    for key,path in pairs(assets.data.fonts) do
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

return assets