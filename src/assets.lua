local Assets = {}

function Assets:load(dir)
    self.texture = {}
    self.texture_data = {}

    self:loadDir("assets/")
    if dir and love.filesystem.getInfo(dir, "directory") then
        self:loadDir(dir)
    end
end

function Assets:loadDir(dir)
    self:loadTextures(dir)
end

function Assets:loadTextures(dir)
    for _,file in ipairs(FileSystem.getFilesRecursive(dir.."/sprites")) do
        local is_png, short = StrUtil.endsWith(file, ".png")
        if is_png then
            local data = love.image.newImageData(dir.."/sprites/"..file)
            self.texture[short] = love.graphics.newImage(data)
            self.texture_data[short] = data
        end
    end
end

function Assets:getTexture(path)
    return self.texture[path]
end

function Assets:getTextureData(path)
    return self.texture_data[path]
end

return Assets