---@class HPText : Object
---@overload fun(...) : HPText
local HPText, super = Class(Object)

function HPText:init(text, x, y)
    super.init(self, x, y)
    self.text = text
    self:setOrigin(0, 0)
    self.color = {0, 1, 0}
    self.physics.speed_y = -5
    self.alpha = 1
    self.parallax_x = 0
    self.parallax_y = 0
    self.font = Assets.getFont("main")
    self.timer = Timer()
    self:addChild(self.timer)

    self.timer:after(8/30, function()
        self:fadeOutSpeedAndRemove(1 / 8)
    end)
end

function HPText:draw()
    love.graphics.setFont(self.font)
    love.graphics.print(self.text, 0, 0)

    Draw.setColor(1, 1, 1, 1)
    super.draw(self)
end

return HPText