local Assets = {
    loaded = false,
    data = {
        texture = {},
        texture_data = {}
    }
}

function Assets:loadData(data)
    self.data = data

    -- thread can't create images, we do it here
    for key,image_data in pairs(self.data.texture_data) do
        self.data.texture[key] = love.graphics.newImage(image_data)
    end

    self.loaded = true
end

function Assets:getTexture(path)
    return self.data.texture[path]
end

function Assets:getTextureData(path)
    return self.data.texture_data[path]
end

return Assets