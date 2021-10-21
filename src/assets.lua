local Assets = {}
local self = Assets

function Assets.clear()
    self.loaded = false
    self.data = {
        texture = {},
        texture_data = {},
        frame_ids = {},
        frames = {},
        fonts = {},
        font_data = {},
        font_settings = {}
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

    for key,path in pairs(data.font_data) do
        local default = data.font_settings[key] and data.font_settings[key]["defaultSize"] or 12
        self.data.fonts[key] = {default = default}
        self.data.fonts[key][default] = love.graphics.newFont(path, default)
    end

    self.loaded = true
end

function Assets.getFont(path, size)
    local font = self.data.fonts[path]
    if font then
        size = size or font.default
        if not font[size] then
            font[size] = love.graphics.newFont(self.data.font_data[path], size)
        end
        return font[size]
    end
end

function Assets.getTexture(path)
    return self.data.texture[path]
end

function Assets.getTextureData(path)
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