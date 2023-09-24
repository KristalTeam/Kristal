---@class Music : Class
---
---@field volume number
---@field pitch number
---@field looping boolean
---
---@field started boolean
---
---@field target_volume number
---@field fade_speed number
---@field fade_callback fun(music:Music)|nil
---
---@field removed boolean
---
---@field current string|nil
---@field source love.Source|nil
---
---@overload fun() : Music
local Music = {}

local _handlers = {}

function Music:init()
    self.volume = 1

    self.pitch = 1
    self.looping = true

    self.started = false

    self.target_volume = 0
    self.fade_speed = 0
    self.fade_callback = nil

    self.removed = false

    self.current = nil
    self.source = nil
end

---@param to? number
---@param speed? number
---@param callback? fun(music:Music)
function Music:fade(to, speed, callback)
    self.target_volume = to or 0
    self.fade_speed = speed or (10/30)
    self.fade_callback = callback
end

---@return number
function Music:getVolume()
    return self.volume * MUSIC_VOLUME * (self.current and MUSIC_VOLUMES[self.current] or 1)
end

---@return number
function Music:getPitch()
    return self.pitch * (self.current and MUSIC_PITCHES[self.current] or 1)
end

---@param music? string
---@param volume? number
---@param pitch? number
function Music:play(music, volume, pitch)
    if music then
        local path = Assets.getMusicPath(music)
        if not path then
            return
        end
        self:playFile(path, volume, pitch, music)
    else
        self:playFile(nil, volume, pitch)
    end
end

---@param path? string
---@param volume? number
---@param pitch? number
---@param name? string
function Music:playFile(path, volume, pitch, name)
    if self.removed then
        return
    end

    self.fade_speed = 0

    if path then
        name = name or path
        if volume then
            self.volume = volume
        end
        if self.current ~= name or not self.source or not self.source:isPlaying() then
            if self.source then
                self.source:stop()
            end
            self.current = name
            self.pitch = pitch or 1
            self.source = love.audio.newSource(path, "stream")
            self.source:setVolume(self:getVolume())
            self.source:setPitch(self:getPitch())
            self.source:setLooping(self.looping)
            self.source:play()
            self.started = true
        else
            if volume then
                self.source:setVolume(self:getVolume())
            end
            if pitch then
                self.pitch = pitch
                self.source:setPitch(self:getPitch())
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
        self.started = true
    end
end

---@param volume number
function Music:setVolume(volume)
    self.volume = volume
    if self.source then
        self.source:setVolume(self:getVolume())
    end
end

---@param pitch number
function Music:setPitch(pitch)
    self.pitch = pitch
    if self.source then
        self.source:setPitch(self:getPitch())
    end
end

---@param loop boolean
function Music:setLooping(loop)
    self.looping = loop
    if self.source then
        self.source:setLooping(loop)
    end
end

---@param time number
function Music:seek(time)
    self.source:seek(time)
end

---@return number
function Music:tell()
    return self.source:tell()
end

function Music:stop()
    self.fade_speed = 0
    if self.source then
        self.source:stop()
    end
    self.started = false
end

function Music:pause()
    if self.source then
        self.source:pause()
    end
    self.started = false
end

function Music:resume()
    if self.source then
        self.source:play()
    end
    self.started = true
end

---@return boolean
function Music:isPlaying()
    return self.source and self.source:isPlaying() or false
end

---@return boolean
function Music:canResume()
    return self.source ~= nil and not self.source:isPlaying()
end

function Music:remove()
    Utils.removeFromTable(_handlers, self)
    if self.source then
        self.source:stop()
        self.source = nil
    end
    self.started = false
    self.removed = true
end

-- Static Functions

local function getAll()
    return _handlers
end

local function getPlaying()
    local result = {}
    for _,handler in ipairs(_handlers) do
        if handler.source and handler.source:isPlaying() then
            table.insert(result, handler)
        end
    end
    return result
end

local function stop()
    for _,handler in ipairs(_handlers) do
        if handler.source and handler.source:isPlaying() then
            handler.source:stop()
        end
    end
end

local function clear()
    for _,handler in ipairs(_handlers) do
        if handler.source then
            handler.source:stop()
        end
    end
    _handlers = {}
end

local function update()
    for _,handler in ipairs(_handlers) do
        if handler.fade_speed ~= 0 and handler.volume ~= handler.target_volume then
            handler.volume = Utils.approach(handler.volume, handler.target_volume, DT / handler.fade_speed)

            if handler.volume == handler.target_volume then
                handler.fade_speed = 0

                if handler.fade_callback then
                    handler:fade_callback()
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

local module = {
    new = new,
    update = update,
    clear = clear,
    stop = stop,
    getAll = getAll,
    getPlaying = getPlaying,
    lib = Music,
}

return setmetatable(module, {__call = function(t, ...) return new(...) end})