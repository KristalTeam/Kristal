local Assets = {}
local self = Assets

function Assets.clear()
    self.loaded = false
    self.data = {
        texture = {},
        texture_data = {},
        frame_ids = {},
        frames = {},
        fonts = {}
    }
    self.frames_for = {}
    self.quads = {}
end

function Assets.loadData(data)
    Utils.merge(self.data, data, true)

    -- thread can't create images, we do it here
    for key,image_data in pairs(data.texture_data) do
        self.data.texture[key] = love.graphics.newImage(image_data)
    end

    -- create frame tables with images
    for key,ids in pairs(data.frame_ids) do
        self.data.frames[key] = self.data.frames[key] or {}
        for i,id in pairs(ids) do
            self.data.frames[key][i] = self.data.texture[id]
            self.frames_for[id] = {key, i}
        end
    end

    for key,path in pairs(data.fonts) do
        self.data.fonts[key] = love.graphics.newFont(path, 32, "mono")
    end

    self.loaded = true
end

function Assets.getFont(path)
    if path:sub(1, 1) == "^" then
        self.data.fonts[path] = self.data.fonts[path] or love.graphics.newFont(path:sub(2)..".ttf", 32, "mono")
    end
    return self.data.fonts[path]
end

function Assets.getTexture(path)
    if path:sub(1, 1) == "^" then
        self.data.texture[path] = self.data.texture[path] or love.graphics.newImage(path:sub(2)..".png")
    end
    return self.data.texture[path]
end

function Assets.getTextureData(path)
    if path:sub(1, 1) == "^" then
        self.data.texture_data[path] = self.data.texture_data[path] or love.image.newImageData(path:sub(2)..".png")
    end
    return self.data.texture_data[path]
end

function Assets.getFrames(path)
    return self.data.frames[path]
end

function Assets.getFrameIds(path)
    return self.data.frame_ids[path]
end

function Assets.getFramesFor(texture)
    if self.frames_for[texture] then
        return unpack(self.frames_for[texture])
    end
end

function Assets.getQuad(x, y, width, height, sw, sh)
    local idstr = x..","..y..","..width..","..sw..","..sh
    return self.quads[idstr] or love.graphics.newQuad(x, y, width, height, sw, sh)
end

Assets.clear()

return Assets