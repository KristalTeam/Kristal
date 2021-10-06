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
    return assets.data.fonts[path]
end

function assets.getTexture(path)
    return assets.data.texture[path]
end

function assets.getTextureData(path)
    return assets.data.texture_data[path]
end

return assets