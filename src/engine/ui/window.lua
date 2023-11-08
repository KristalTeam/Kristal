---@class UIWindow : UIComponent
---@overload fun(...) : UIWindow
local UIWindow, super = Class(UIComponent)

function UIWindow:init(x, y, x_sizing, y_sizing)
    super.init(self, x, y, x_sizing, y_sizing)
end

return UIWindow
