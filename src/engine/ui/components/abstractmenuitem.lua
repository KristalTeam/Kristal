---@class AbstractMenuItemComponent : Component
---@field selected boolean
---@field callback function
---@field soul_offset_x number
---@field soul_offset_y number
---@overload fun(...) : AbstractMenuItemComponent
local AbstractMenuItemComponent, super = Class(Component)

---@param x_sizing? Sizing
---@param y_sizing? Sizing
---@param callback? function
---@param options? table
function AbstractMenuItemComponent:init(x_sizing, y_sizing, callback, options)
    super.init(self, x_sizing, y_sizing, options)

    self.selected = false
    self.callback = callback

    self.soul_offset_x = 0
    self.soul_offset_y = 0
end

function AbstractMenuItemComponent:onHovered(hovered, from_focused)
    self.selected = hovered
    if hovered and not from_focused then
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
