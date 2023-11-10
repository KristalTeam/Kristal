---@class BasicMenuComponent : AbstractMenuComponent
---@overload fun(...) : BasicMenuComponent
local BasicMenuComponent, super = Class(AbstractMenuComponent)

function BasicMenuComponent:init(x, y, x_sizing, y_sizing)
    super.init(self, x, y, x_sizing, y_sizing)
end

function BasicMenuComponent:update()
    super.update(self)

    if self:isSpecificallyFocused() then
        if Input.pressed("up") then
            self:previous()
        elseif Input.pressed("down") then
            self:next()
        elseif Input.pressed("confirm") then
            if self:getMenuItems()[self.selected_item] and self:getMenuItems()[self.selected_item].onSelected then
                self:getMenuItems()[self.selected_item]:onSelected()
            end
        end
    end
end

return BasicMenuComponent
