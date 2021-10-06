local assets = {
    loaded = false,
    data = {
        texture = {},
        texture_data = {}
    }
}

function assets.loadData(data)
    assets.data = data

    -- thread can't create images, we do it here
    for key,image_data in pairs(assets.data.texture_data) do
        assets.data.texture[key] = love.graphics.newImage(image_data)
    end

    assets.loaded = true
end

function assets.getTexture(path)
    return assets.data.texture[path]
end

function assets.getTextureData(path)
    return assets.data.texture_data[path]
end

return assets