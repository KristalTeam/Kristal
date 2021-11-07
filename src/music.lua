local Music = {}

local _handlers = setmetatable({}, {__mode="v"})

function Music:init()
    self.volume = 1

    self.pitch = 1

    self.target_volume = 0
    self.fade_speed = 0
    self.fade_callback = nil

    self.current = nil
    self.source = nil
end

function Music:fade(to, speed, callback)
    self.target_volume = to or 0
    self.fade_speed = speed or 0.1
    self.fade_callback = callback
end

function Music:getVolume()
    return self.volume * MUSIC_VOLUME * (self.current and MUSIC_VOLUMES[self.current] or 1)
end

function Music:getPitch()
    return self.pitch * (self.current and MUSIC_PITCHES[self.current] or 1)
end

function Music:play(music, volume, pitch)
    if music then
        local path = Assets.getMusicPath(music)
        if path then
            if volume then
                self.volume = volume
            end
            if self.current ~= music or not self.source or not self.source:isPlaying() then
                if self.source then
                    self.source:stop()
                end
                self.current = music
                self.pitch = pitch or 1
                self.source = love.audio.newSource(path, "stream")
                self.source:setVolume(self:getVolume())
                self.source:setPitch(self:getPitch())
                self.source:setLooping(true)
                self.source:play()
            else
                if volume then
                    self.source:setVolume(self:getVolume())
                end
                if pitch then
                    self.pitch = pitch
                    self.source:setPitch(self:getPitch())
                end
            end
        end
    elseif self.source then
        if volume then
            self.volume = volume
            self.source:setVolume(self:getVolume())
        end
        if pitch then
            self.pitch = pitch
            self.source:setPitch(self:getPitch())
        end
        self.source:play()
    end
end

function Music:stop()
    if self.source then
        self.source:stop()
    end
end

function Music:pause()
    if self.source then
        self.source:pause()
    end
end

function Music:resume()
    if self.source then
        self.source:play()
    end
end

function Music:isPlaying()
    return self.source and self.source:isPlaying() or false
end

local function update(dt)
    for _,handler in ipairs(_handlers) do
        if handler.fade_speed ~= 0 and handler.volume ~= handler.target_volume then
            handler.volume = Utils.approach(handler.volume, handler.target_volume, handler.fade_speed * DTMULT)
    
            if handler.volume == handler.target_volume then
                handler.fade_speed = 0
    
                if handler.fade_callback then
                    handler.fade_callback()
                end
            end
        end
    
        if handler.source then
            local volume = handler:getVolume()
            if handler.source:getVolume() ~= volume then
                handler.source:setVolume(volume)
            end
            local pitch = handler:getPitch()
            if handler.source:getPitch() ~= pitch then
                handler.source:setPitch(pitch)
            end
        end
    end
end

local function new(music, volume, pitch)
    local handler = setmetatable({}, {__index = Music})

    table.insert(_handlers, handler)
    handler:init()

    if music then
        handler.current = music
        handler.volume = volume or 1
        handler.pitch = pitch or 1
        handler:play(music, volume, pitch)
    end

    return handler
end

local default = new()
local module = {
    new = new,
    update = update
}
for k in pairs(Music) do
    module[k] = function(...) return default[k](default, ...) end
end

return setmetatable(module, {__call = function(t, ...) return new(...) end})