---@class DPad: Object
local DPad, super = Class(Object)

function DPad:init(buttons_table, x,y,w,h)
    super.init(self,x,y,12*13,12*13)
    local b = 30
    self:addChild(InputButton("up", buttons_table, b,0, 1)):setDpadMode()
    self:addChild(InputButton("left", buttons_table, 0,b, 1)):setDpadMode()
    self:addChild(InputButton("down", buttons_table, b,b+b, 1)):setDpadMode()
    self:addChild(InputButton("right", buttons_table, b+b,b, 1)):setDpadMode()
    self:setScale(2)
end

function DPad:draw()
    super.draw(self)
    Draw.setColor(COLORS.white, 0.5)
    love.graphics.rectangle("fill", 32,30,28,28)
end

return DPad