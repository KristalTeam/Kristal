---@class AbstractMenuItemComponent : Component
---@overload fun(...) : AbstractMenuItemComponent
local AbstractMenuItemComponent, super = Class(Component)

function AbstractMenuItemComponent:init(x, y, width, height, callback)
    super.init(self, x, y, width, height)

    self.selected = false
    self.callback = nil

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
        self:setFocused(self:callback())
    end
    self:setFocused(true)
end

return AbstractMenuItemComponent
