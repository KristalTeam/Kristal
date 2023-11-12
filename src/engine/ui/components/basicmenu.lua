---@class BasicMenuComponent : AbstractMenuComponent
---@overload fun(...) : BasicMenuComponent
local BasicMenuComponent, super = Class(AbstractMenuComponent)

function BasicMenuComponent:init(x_sizing, y_sizing, options)
    super.init(self, x_sizing, y_sizing, options)
    options = options or {}
    self.horizontal = options.horizontal or false
    self.hold = options.hold or false
end

function BasicMenuComponent:update()
    super.update(self)

    if self:isSpecificallyFocused() then
        if self.horizontal and Input.pressed("left", self.hold) or Input.pressed("up", self.hold) then
            self:previous()
        elseif self.horizontal and Input.pressed("right", self.hold) or Input.pressed("down", self.hold) then
            self:next()
        elseif Input.pressed("confirm") then
            if self:getMenuItems()[self.selected_item] and self:getMenuItems()[self.selected_item].onSelected then
                self:getMenuItems()[self.selected_item]:onSelected()
            end
        end
    end
end

return BasicMenuComponent
