---@class UIWindow : UIComponent
---@overload fun(...) : UIWindow
local UIWindow, super = Class(UIComponent)

function UIWindow:init(x, y, width, height)
    super.init(self, x, y, width, height)
end

return UIWindow
