---@class DPad: Object
local DPad, super = Class(Object)

function DPad:init(x,y,w,h)
    
    super.init(self,x,y,12*13,12*13)
    self:addChild(InputButton("up",42,0, 3)):setDpadMode()
    self:addChild(InputButton("down",42,84, 3)):setDpadMode()
    self:addChild(InputButton("left",0,42, 3)):setDpadMode()
    self:addChild(InputButton("right",84,42, 3)):setDpadMode()
end

return DPad