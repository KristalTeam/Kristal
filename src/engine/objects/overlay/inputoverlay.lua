---@class InputOverlay: Object
local InputOverlay, super = Class(Object)

function InputOverlay:init(w,h)
    super.init(self,0,0,w,h)
    self.buttons = {
        key_pressed = {},
        key_down = {},
        key_released = {},
    }
    self:reset()
end
function InputOverlay:reset()
    for i,v in pairs(self.children) do
        v:remove()
    end
    self.confirm = self:addChild(InputButton("confirm",self.buttons, 540,276, 2))
    self.cancel = self:addChild(InputButton("cancel",self.buttons, 510,336, 2))
    self.menu = self:addChild(InputButton("menu",self.buttons, 474,276, 2))

    self.dpad = self:addChild(Dpad(self.buttons, 10,300))
end

return InputOverlay