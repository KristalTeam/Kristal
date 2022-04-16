local DarkBox, super = Class(Object)

function DarkBox:init(x, y, width, height)
    super:init(self, x, y, width, height)

    self.frame = 0

    self.left = Assets.getTexture("ui/textbox_left")
    self.top = Assets.getTexture("ui/textbox_top")
    self.corner = Assets.getFrames("ui/textbox_corner")

    self.corners = {{0, 0}, {1, 0}, {1, 1}, {0, 1}}
end

function DarkBox:getBorder()
    return self.left:getWidth()*2, self.top:getHeight()*2
end

function DarkBox:draw()
    self.frame = ((self.frame + (DTMULT / 10)) - 1) % #self.corner + 1

    love.graphics.setColor(0, 0, 0, self.alpha)
    love.graphics.rectangle("fill", 0, 0, self.width, self.height)

    love.graphics.setColor(self:getDrawColor())

    love.graphics.draw(self.left, 0, 0, 0, 2, self.height / self.left:getHeight(), self.left:getWidth(), 0)
    love.graphics.draw(self.left, self.width, 0, math.pi, 2, self.height / self.left:getHeight(), self.left:getWidth(), self.left:getHeight())

    love.graphics.draw(self.top, 0, 0, 0, self.width / self.top:getWidth(), 2, 0, self.top:getHeight())
    love.graphics.draw(self.top, 0, self.height, math.pi, self.width / self.top:getWidth(), 2, self.top:getWidth(), self.top:getHeight())

    for i = 1, 4 do
        local cx, cy = self.corners[i][1] * self.width, self.corners[i][2] * self.height
        local sprite = self.corner[math.floor(self.frame)]
        love.graphics.draw(sprite, cx, cy, (i - 1) * (math.pi / 2), 2, 2, sprite:getWidth(), sprite:getHeight())
    end

    super:draw(self)
end

return DarkBox