---@class UIMenuItem : UIComponent
---@overload fun(...) : UIMenuItem
local UIMenuItem, super = Class(UIComponent)

function UIMenuItem:init(x, y, width, height)
    super.init(self, x, y, width, height)

    self.selected = false
end

function UIMenuItem:update()
end

return UIMenuItem
