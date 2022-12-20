---@class Fader : Object
---@overload fun(...) : Fader
local Fader, super = Class(Object)

function Fader:init()
    super:init(self, 0, 0)
    self.width = SCREEN_WIDTH
    self.height = SCREEN_HEIGHT

    self:setParallax(0, 0)

    self:setColor(0, 0, 0)
    self.fade_color = self.color
    self.alpha = 0

    self.state = "NONE"
    self.callback_function = nil

    self.default_speed = 0.25
    self.speed = self.default_speed

    self.music = nil

    self.debug_select = false

    self.blocky = false
end

function Fader:parseOptions(options, reset_values)
    options = options or {}

    self.speed = options["speed"] or (reset_values and self.default_speed or self.speed)
    self.fade_color = options["color"] or (reset_values and self.color or self.fade_color)
    self.alpha = options["alpha"] or self.alpha
    self.blocky = options["blocky"] or self.blocky

    return options
end

function Fader:parseMusicFade(to, options)
    options = options or {}
    if options["music"] then
        local speed = type(options["music"]) == "number" and options["music"] or self.speed
        local music = self.music or Game:getActiveMusic()
        if music then
            if music:canResume() then
                music:setVolume(0)
                music:resume()
            end
            if speed > 0 then
                music:fade(to, speed, function()
                    if music.volume == 0 then
                        music:pause()
                        music:setVolume(1)
                    end
                end)
            else
                music:setVolume(to)
            end
        end
    end
end

function Fader:transition(middle_callback, end_callback, options)
    options = options or {}
    self:fadeOut(function()
        if middle_callback then
            middle_callback()
        end
        options.alpha = nil
        options.music = nil
        self:fadeIn(end_callback, options)
    end, options)
end

function Fader:fadeOut(callback, options)
    if type(callback) == "table" then
        options = callback
        callback = nil
    end
    self:parseOptions(options, true)
    self:parseMusicFade(0, options)
    self.callback_function = callback
    self.state = "FADEOUT"
end

function Fader:fadeIn(callback, options)
    if type(callback) == "table" then
        options = callback
        callback = nil
    end
    self:parseOptions(options, false)
    self:parseMusicFade(1, options)
    self.callback_function = callback
    self.state = "FADEIN"
end

function Fader:update()
    if self.state == "FADEOUT" then
        self.alpha = self.alpha + (DT / self.speed)
        if (self.alpha >= 1) then
            self.alpha = 1
            self.state = "NONE"
            if self.callback_function then
                self.callback_function()
            end
            self.callback_function = nil
        end
    end
    if self.state == "FADEIN" then
        self.alpha = self.alpha - (DT / self.speed)
        if (self.alpha <= 0) then
            self.alpha = 0
            self.state = "NONE"
            if self.callback_function then
                self.callback_function()
                self.callback_function = nil
            end
        end
    end
end

function Fader:draw()
    local color = Utils.copy(self.fade_color)
    local alpha = self.alpha * (color[4] or 1)

    if self.blocky then
        if self.state == "FADEIN" then
            alpha = (math.floor(alpha * 4) / 4)
        else
            alpha = (math.ceil(alpha * 4) / 4)
        end
    end

    color[4] = alpha
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

    love.graphics.setColor(1, 1, 1, 1)
    super:draw(self)
end

return Fader