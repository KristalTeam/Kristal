---@class AbstractMenuItemComponent : Component
---@overload fun(...) : AbstractMenuItemComponent
local AbstractMenuItemComponent, super = Class(Component)

function AbstractMenuItemComponent:init(x, y, width, height, callback)
    super.init(self, x, y, width, height)

    self.selected = false
    self.callback = nil
end

function AbstractMenuItemComponent:onHovered(hovered, initial)
    self.selected = hovered
    if hovered then
        Assets.playSound("ui_move")
    end
end

function AbstractMenuItemComponent:onSelected()
    Assets.playSound("ui_select")
    if self.callback then
        self:callback()
    end
end

return AbstractMenuItemComponent
