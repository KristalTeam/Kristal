---@class DPad: Object
local DPad, super = Class(Object)

function DPad:init(buttons_table, x,y,w,h)
    super.init(self,x,y,12*13,12*13)
    self:addChild(InputButton("up", buttons_table, 42,0, 2)):setDpadMode()
    self:addChild(InputButton("down", buttons_table, 42,84, 2)):setDpadMode()
    self:addChild(InputButton("left", buttons_table, 0,42, 2)):setDpadMode()
    self:addChild(InputButton("right", buttons_table, 84,42, 2)):setDpadMode()
end

return DPad