---@class AbstractMenuItemComponent : Component
---@overload fun(...) : AbstractMenuItemComponent
local AbstractMenuItemComponent, super = Class(Component)

function AbstractMenuItemComponent:init(x_sizing, y_sizing, callback, options)
    super.init(self, x_sizing, y_sizing, options)

    self.selected = false
    self.callback = callback

    self.soul_offset_x = 0
    self.soul_offset_y = 0
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
