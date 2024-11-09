---@class InputOverlay: Object
local InputOverlay, super = Class(Object)

function InputOverlay:init(w,h)
    super.init(self,0,0,w,h)
    self:addChild(InputButton("a",540,276, 3))
    self:addChild(InputButton("b",510,336, 3))
    self:addChild(InputButton("y",474,276, 3))

    self:addChild(Dpad(10,300))
end

return InputOverlay