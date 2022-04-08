local Fader, super = Class(Object)

function Fader:init()
    super:init(self, 0, 0)
    self.width = SCREEN_WIDTH
    self.height = SCREEN_HEIGHT

    self.color = {0, 0, 0, 1}
    self.alpha = 0

    self.state = "NONE"
    self.callback_function = nil

    self.speed = 0.25
end

function Fader:transition(middle_callback, end_callback)
    self:fadeOut(function()
        if middle_callback then
            middle_callback()
        end
        self:fadeIn(end_callback)
    end)
end

function Fader:fadeOut(callback)
    self.callback_function = callback
    self.state = "FADEOUT"
end

function Fader:fadeIn(callback)
    self.callback_function = callback
    self.state = "FADEIN"
end

function Fader:update(dt)
    if self.state == "FADEOUT" then
        self.alpha = self.alpha + (dt / self.speed)
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
        self.alpha = self.alpha - (dt / self.speed)
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
    local color = Utils.copy(self.color)
    color[4] = self.alpha * (color[4] or 1)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

    love.graphics.setColor(1, 1, 1, 1)
    super:draw(self)
end

return Fader