---@class BasicMenuComponent : AbstractMenuComponent
---@overload fun(...) : BasicMenuComponent
local BasicMenuComponent, super = Class(AbstractMenuComponent)

function BasicMenuComponent:init(x, y, x_sizing, y_sizing, options)
    super.init(self, x, y, x_sizing, y_sizing)
    options = options or {}
    self.horizontal = options.horizontal or false
end

function BasicMenuComponent:update()
    super.update(self)

    if self:isSpecificallyFocused() then
        if self.horizontal and Input.pressed("left") or Input.pressed("up") then
            self:previous()
        elseif self.horizontal and Input.pressed("right") or Input.pressed("down") then
            self:next()
        elseif Input.pressed("confirm") then
            if self:getMenuItems()[self.selected_item] and self:getMenuItems()[self.selected_item].onSelected then
                self:getMenuItems()[self.selected_item]:onSelected()
            end
        end
    end
end

return BasicMenuComponent
