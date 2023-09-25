---@class UIMenu : UIComponent
---@overload fun(...) : UIMenu
local UIMenu, super = Class(UIComponent)

function UIMenu:init(x, y, width, height)
    super.init(self, x, y, width, height)

    self.selected_item = 1
end

function UIMenu:update()
end

return UIMenu
