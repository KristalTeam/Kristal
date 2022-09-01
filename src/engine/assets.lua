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
        videos = {},
        bubbles = {},
        bubble_settings = {},
    }
    self.frames_for = {}
    self.texture_ids = {}
    self.sounds = {}
    self.sound_instances = {}
    self.quads = {}
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
        texture_ids = Utils.copy(self.texture_ids, true),
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
        self.texture_ids[self.data.texture[key]] = key
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
    end
    -- create image fonts
    for key,image_data in pairs(data.font_image_data) do
        local glyphs = data.font_settings[key] and data.font_settings[key]["glyphs"] or ""
        data.font_settings[key] = data.font_settings[key] or {}
        if data.font_settings[key]["autoScale"] == nil then
            data.font_settings[key]["autoScale"] = true
        end
        self.data.fonts[key] = love.graphics.newImageFont(image_data, glyphs)
    end
    -- set up image font fallbacks
    for key,_ in pairs(data.font_image_data) do
        if data.font_settings[key]["fallbacks"] then
            local fallbacks = {}
            for _,fallback in ipairs(data.font_settings["fallbacks"]) do
                local font = self.data.fonts[fallback["font"]]
                if type(font) == "table" then
                    error("Attempt to use TTF fallback on image font: " .. key)
                else
                    table.insert(fallbacks, font)
                end
            end
            self.data.fonts[key]:setFallbacks(unpack(fallbacks))
        end
    end

    -- create single-instance audio sources
    for key,sound_data in pairs(data.sound_data) do
        local src = love.audio.newSource(sound_data)
        self.sounds[key] = src
    end
    -- may be a memory hog, we clone the existing source so we dont need the sound data anymore
    --self.data.sound_data = {}
end

function Assets.update()
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

function Assets.getBubbleData(path)
    return self.data.bubble_settings[path] or {}
end

function Assets.getFont(path, size)
    local font = self.data.fonts[path]
    if font then
        local settings = self.data.font_settings[path] or {}
        if type(font) == "table" then
            if settings["autoScale"] then
                size = font.default
            else
                size = size or font.default
            end
            if not font[size] then
                font[size] = love.graphics.newFont(self.data.font_data[path], size, settings["hinting"] or "mono")

                if settings["fallbacks"] then
                    local fallbacks = {}

                    for _,fallback in ipairs(settings["fallbacks"]) do
                        local fb_font = self.data.fonts[fallback["font"]]

                        if type(fb_font) ~= "table" then
                            error("Attempt to use image fallback on TTF font: " .. path)
                        else
                            local ratio = (fallback["size"] or fb_font.default) / font.default
                            table.insert(fallbacks, self.getFont(fallback["font"], size * ratio))
                        end
                    end

                    font[size]:setFallbacks(unpack(fallbacks))
                end
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

function Assets.getFontScale(path, size)
    local data = self.data.font_settings[path]
    if data and data["autoScale"] then
        return (size or 1) / (data["defaultSize"] or 1)
    else
        return 1
    end
end

function Assets.getTexture(path)
    return self.data.texture[path]
end

function Assets.getTextureData(path)
    return self.data.texture_data[path]
end

function Assets.getTextureID(texture)
    if type(texture) == "string" then
        return texture
    else
        return self.texture_ids[texture]
    end
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

function Assets.getFramesOrTexture(path)
    local texture = Assets.getTexture(path)
    if texture then
        return {texture}
    else
        return Assets.getFrames(path)
    end
end

function Assets.getQuad(x, y, w, h, sw, sh)
    local key = x..","..y..","..w..","..h..","..sw..","..sh
    if not self.quads[key] then
        self.quads[key] = love.graphics.newQuad(x, y, w, h, sw, sh)
    end
    return self.quads[key]
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

function Assets.stopSound(sound, actually_stop)
    for _,src in ipairs(self.sound_instances[sound] or {}) do
        if actually_stop then
            src:stop()
        else
            src:setVolume(0)
            if src:isLooping() then
                src:setLooping(false)
            end
        end
    end
    if actually_stop then
        self.sound_instances[sound] = {}
    end
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

function Assets.stopAndPlaySound(sound, volume, pitch, actually_stop)
    self.stopSound(sound, actually_stop)
    return self.playSound(sound, volume, pitch)
end

function Assets.getMusicPath(music)
    return self.data.music[music]
end

function Assets.getVideoPath(video)
    return self.data.videos[video]
end

function Assets.newVideo(video, load_audio)
    if not self.data.videos[video] then
        error("No video found: "..video)
    end
    return love.graphics.newVideo(self.data.videos[video], {audio = load_audio})
end

Assets.clear()

return Assets