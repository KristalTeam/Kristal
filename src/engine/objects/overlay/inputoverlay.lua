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
    self.bottom_left = Object(0, SCREEN_HEIGHT, SCREEN_WIDTH/2,SCREEN_HEIGHT/2)
    self.bottom_right = Object(SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_WIDTH/2,SCREEN_HEIGHT/2)
    self.bottom_left:setOrigin(0,1)
    self.bottom_right:setOrigin(1,1)
    self:addChild(self.bottom_left)
    self:addChild(self.bottom_right)
    self.confirm = self.bottom_right:addChild(InputButton("confirm",self.buttons, 238, 94, 2))
    self.cancel = self.bottom_right:addChild(InputButton("cancel",self.buttons, 206,146, 2))
    self.menu = self.bottom_right:addChild(InputButton("menu",self.buttons, 174,94, 2))

    self.dpad = self.bottom_left:addChild(Dpad(self.buttons, 24,16))
end

return InputOverlay