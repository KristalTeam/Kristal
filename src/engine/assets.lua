local Assets = {}
local self = Assets

Assets.saved_data = nil

function Assets.clear()
    self.loaded = false
    self.data = {
        texture = {},
        texture_data = {},
        frame_ids = {},
        frames = {},
        fonts = {},
        font_data = {},
        font_image_data = {},
        font_settings = {},
        sound_data = {},
        music = {},
    }
    self.frames_for = {}
    self.sounds = {}
    self.sound_instances = {}
end

function Assets.loadData(data)
    Utils.merge(self.data, data, true)

    self.parseData(data)

    self.loaded = true
end

function Assets.saveData()
    self.saved_data = {
        data = Utils.copy(self.data, true),
        frames_for = Utils.copy(self.frames_for, true),
        sounds = Utils.copy(self.sounds, true),
    }
end

function Assets.restoreData()
    if self.saved_data then
        Assets.clear()
        for k,v in pairs(self.saved_data) do
            self[k] = Utils.copy(v, true)
        end
        self.loaded = true
        return true
    else
        return false
    end
end

function Assets.parseData(data)
    -- thread can't create images, we do it here
    for key,image_data in pairs(data.texture_data) do
        self.data.texture[key] = love.graphics.newImage(image_data)
    end

    -- create frame tables with images
    for key,ids in pairs(data.frame_ids) do
        self.data.frames[key] = {}
        for i,id in pairs(ids) do
            self.data.frames[key][i] = self.data.texture[id]
            self.frames_for[id] = {key, i}
        end
    end

    -- create TTF fonts
    for key,file_data in pairs(data.font_data) do
        local default = data.font_settings[key] and data.font_settings[key]["defaultSize"] or 12
        self.data.fonts[key] = {default = default}
        self.data.fonts[key][default] = love.graphics.newFont(file_data, default)
    end
    -- create image fonts
    for key,image_data in pairs(data.font_image_data) do
        local glyphs = data.font_settings[key] and data.font_settings[key]["glyphs"] or ""
        self.data.fonts[key] = love.graphics.newImageFont(image_data, glyphs)
    end

    -- create single-instance audio sources
    for key,sound_data in pairs(data.sound_data) do
        local src = love.audio.newSource(sound_data)
        self.sounds[key] = src
    end
    -- may be a memory hog, we clone the existing source so we dont need the sound data anymore
    --self.data.sound_data = {}
end

function Assets.update(dt)
    local sounds_to_remove = {}
    for key,sounds in pairs(self.sound_instances) do
        for _,sound in ipairs(sounds) do
            if not sound:isPlaying() then
                table.insert(sounds_to_remove, {key = key, value = sound})
            end
        end
    end
    for _,sound in ipairs(sounds_to_remove) do
        Utils.removeFromTable(self.sound_instances[sound.key], sound.value)
    end
end

function Assets.getFont(path, size)
    local font = self.data.fonts[path]
    if font then
        if type(font) == "table" then
            size = size or font.default
            if not font[size] then
                font[size] = love.graphics.newFont(self.data.font_data[path], size)
            end
            return font[size]
        else
            return font
        end
    end
end

function Assets.getFontData(path)
    return self.data.font_settings[path] or {}
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

function Assets.getSound(sound)
    return self.sounds[sound]
end

function Assets.newSound(sound)
    return self.sounds[sound]:clone()
end

function Assets.startSound(sound)
    if self.sounds[sound] then
        self.sounds[sound]:stop()
        self.sounds[sound]:play()
        return self.sounds[sound]
    end
end

function Assets.stopSound(sound)
    for _,src in ipairs(self.sound_instances[sound] or {}) do
        src:stop()
    end
    self.sound_instances[sound] = {}
end

function Assets.playSound(sound, volume, pitch)
    if self.sounds[sound] then
        local src = self.sounds[sound]:clone()
        if volume then
            src:setVolume(volume)
        end
        if pitch then
            src:setPitch(pitch)
        end
        src:play()
        self.sound_instances[sound] = self.sound_instances[sound] or {}
        table.insert(self.sound_instances[sound], src)
        return src
    end
end

function Assets.stopAndPlaySound(sound, volume, pitch)
    self.stopSound(sound)
    return self.playSound(sound, volume, pitch)
end

function Assets.getMusicPath(music)
    return self.data.music[music]
end

Assets.clear()

return Assets