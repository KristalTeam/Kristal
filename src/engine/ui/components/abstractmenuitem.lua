---@class AbstractMenuItemComponent : Component
---@overload fun(...) : AbstractMenuItemComponent
local AbstractMenuItemComponent, super = Class(Component)

function AbstractMenuItemComponent:init(x, y, width, height)
    super.init(self, x, y, width, height)

    self.selected = false
end

function AbstractMenuItemComponent:onHovered(hovered, initial)
    self.selected = hovered
    if hovered then
        Assets.playSound("ui_move")
    end
end

function AbstractMenuItemComponent:onSelected()
    Assets.playSound("ui_select")
end

return AbstractMenuItemComponent
