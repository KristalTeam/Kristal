---@class Assets
---
---@field loaded boolean
---
---@field data Assets.data
---
---@field frames_for table<string, {[1]: string, [2]: number}>
---@field texture_ids table<love.Image, string>
---@field sounds table<string, love.Source>
---@field sound_instances table<string, love.Source[]>
---@field quads table<string, love.Quad>
---
---@field saved_data table|nil
---
local Assets = {}
local self = Assets

---@class Assets.data
---@field texture table<string, love.Image>
---@field texture_data table<string, love.ImageData>
---@field frames table<string, love.Image[]>
---@field frame_ids table<string, string[]>
---@field fonts table<string, love.Font|{default: number, [number]: love.Font}>
---@field font_data table<string, love.Data>
---@field font_bmfont_data table<string, string>
---@field font_image_data table<string, love.ImageData>
---@field font_settings table<string, table>
---@field sound_data table<string, love.SoundData>
---@field music table<string, string>
---@field videos table<string, string>
---@field bubble_settings table<string, table>

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
        font_bmfont_data = {},
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

---@param data Assets.data
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

---@return boolean
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

---@param data Assets.data
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
    -- create bmfont fonts
    for key,file_path in pairs(data.font_bmfont_data) do
        data.font_settings[key] = data.font_settings[key] or {}
        if data.font_settings[key]["autoScale"] == nil then
            data.font_settings[key]["autoScale"] = true
        end
        self.data.fonts[key] = love.graphics.newFont(file_path)
    end
    -- set up bmfont font fallbacks
    for key,_ in pairs(data.font_bmfont_data) do
        if data.font_settings[key]["fallbacks"] then
            local fallbacks = {}
            for _,fallback in ipairs(data.font_settings[key]["fallbacks"]) do
                local font = self.data.fonts[fallback["font"]]
                if type(font) == "table" or (self.data.font_settings[fallback["font"]] and self.data.font_settings[fallback["font"]]["glyphs"]) then
                    error("Attempt to use TTF or image fallback on BMFont font: " .. key)
                else
                    table.insert(fallbacks, font)
                end
            end
            self.data.fonts[key]:setFallbacks(unpack(fallbacks))
        end
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
            for _,fallback in ipairs(data.font_settings[key]["fallbacks"]) do
                local font = self.data.fonts[fallback["font"]]
                if type(font) == "table" or not (self.data.font_settings[fallback["font"]] and self.data.font_settings[fallback["font"]]["glyphs"]) then
                    error("Attempt to use TTF or BMFont fallback on image font: " .. key)
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

---@param path string
---@return table
function Assets.getBubbleData(path)
    return self.data.bubble_settings[path] or {}
end

---@param path string
---@param size? number
---@return love.Font
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
                ---@diagnostic disable-next-line: param-type-mismatch
                font[size] = love.graphics.newFont(self.data.font_data[path], size, settings["hinting"] or "mono")

                if settings["fallbacks"] then
                    local fallbacks = {}

                    for _,fallback in ipairs(settings["fallbacks"]) do
                        local fb_font = self.data.fonts[fallback["font"]]

                        if type(fb_font) ~= "table" then
                            error("Attempt to use image or BMFont fallback on TTF font: " .. path)
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
    ---@diagnostic disable-next-line: return-type-mismatch
    return nil
end

---@param path string
---@return table
function Assets.getFontData(path)
    return self.data.font_settings[path] or {}
end

---@param path string
---@param size? number
---@return number
function Assets.getFontScale(path, size)
    local data = self.data.font_settings[path]
    if data and data["autoScale"] then
        return (size or 1) / (data["defaultSize"] or 1)
    else
        return 1
    end
end

---@param path string
---@return love.Image
function Assets.getTexture(path)
    return self.data.texture[path]
end

---@param path string
---@return love.ImageData
function Assets.getTextureData(path)
    return self.data.texture_data[path]
end

---@param texture love.Image|string
---@return string
function Assets.getTextureID(texture)
    if type(texture) == "string" then
        return texture
    else
        return self.texture_ids[texture]
    end
end

---@param path string
---@return love.Image[]
function Assets.getFrames(path)
    return self.data.frames[path]
end

---@param path string
---@return string[]
function Assets.getFrameIds(path)
    return self.data.frame_ids[path]
end

---@param texture string
---@return string texture, number frame
function Assets.getFramesFor(texture)
    if self.frames_for[texture] then
        -- annoying type annotations
        ---@diagnostic disable-next-line: return-type-mismatch
        return unpack(self.frames_for[texture])
    end
    ---@diagnostic disable-next-line: return-type-mismatch
    return nil, nil
end

---@param path string
---@return love.Image[]
function Assets.getFramesOrTexture(path)
    local texture = Assets.getTexture(path)
    if texture then
        return {texture}
    else
        return Assets.getFrames(path)
    end
end

---@param x number
---@param y number
---@param w number
---@param h number
---@param sw number
---@param sh number
---@return love.Quad
function Assets.getQuad(x, y, w, h, sw, sh)
    local key = x..","..y..","..w..","..h..","..sw..","..sh
    if not self.quads[key] then
        self.quads[key] = love.graphics.newQuad(x, y, w, h, sw, sh)
    end
    return self.quads[key]
end

---@param sound string
---@return love.Source
function Assets.getSound(sound)
    return self.sounds[sound]
end

---@param sound string
---@return love.Source
function Assets.newSound(sound)
    return self.sounds[sound]:clone()
end

---@param sound string
---@return love.Source
function Assets.startSound(sound)
    if self.sounds[sound] then
        self.sounds[sound]:stop()
        self.sounds[sound]:play()
        return self.sounds[sound]
    end
    ---@diagnostic disable-next-line: return-type-mismatch
    return nil
end

---@param sound string
---@param actually_stop? boolean
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

---@param sound string
---@param volume? number
---@param pitch? number
---@return love.Source
function Assets.playSound(sound, volume, pitch)
    if self.sounds[sound] then
        self.sound_instances[sound] = self.sound_instances[sound] or {}
        local src
        local function play(v)
            src = self.sounds[sound]:clone()
            if v then
                src:setVolume(v)
            end
            if pitch then
                src:setPitch(pitch)
            end
            src:play()
            table.insert(self.sound_instances[sound], src)
        end
        if volume and volume > 1 then
            for _=1,math.floor(volume) do
                play(1)
            end
            if volume % 1 > 0 then
                play(volume % 1)
            end
        else
            play(volume)
        end
        return src
    end
    ---@diagnostic disable-next-line: return-type-mismatch
    return nil
end

---@param sound string
---@param volume? number
---@param pitch? number
---@param actually_stop? boolean
---@return love.Source
function Assets.stopAndPlaySound(sound, volume, pitch, actually_stop)
    self.stopSound(sound, actually_stop)
    return self.playSound(sound, volume, pitch)
end

---@param music string
---@return string
function Assets.getMusicPath(music)
    return self.data.music[music]
end

---@param video string
---@return string
function Assets.getVideoPath(video)
    return self.data.videos[video]
end

---@param video string
---@param load_audio? boolean
---@return love.Video
function Assets.newVideo(video, load_audio)
    if not self.data.videos[video] then
        error("No video found: "..video)
    end
    return love.graphics.newVideo(self.data.videos[video], {audio = load_audio})
end

Assets.clear()

return Assets