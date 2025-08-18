---@class DPad: Object
local DPad, super = Class(Object)

function DPad:init(buttons_table, x,y,w,h)
    super.init(self,x,y,32*3,32*3)
    self:addChild(InputButton("up", buttons_table, 46,16, 1)):setDpadMode()
    self:addChild(InputButton("left", buttons_table, 18,44, 1)):setDpadMode()
    self:addChild(InputButton("down", buttons_table, 46,72, 1)):setDpadMode()
    self:addChild(InputButton("right", buttons_table, 74,44, 1)):setDpadMode()
    self:setScale(2)
end

function DPad:draw()
    super.draw(self)
    Draw.setColor(COLORS.white, 0.5)
    love.graphics.rectangle("fill", 32,30,28,28)
end

return DPad