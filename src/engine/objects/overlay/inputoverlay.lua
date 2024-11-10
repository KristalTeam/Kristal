---@class InputOverlay: Object
local InputOverlay, super = Class(Object)

function InputOverlay:init(w,h)
    super.init(self,0,0,w,h)
    self.buttons = {
        key_pressed = {},
        key_down = {},
        key_released = {},
    }
    self:addChild(InputButton("confirm",self.buttons, 540,276, 2))
    self:addChild(InputButton("cancel",self.buttons, 510,336, 2))
    self:addChild(InputButton("menu",self.buttons, 474,276, 2))

    self:addChild(Dpad(self.buttons, 10,300))
end

return InputOverlay