---@class BasicMenuComponent : AbstractMenuComponent
---@overload fun(...) : BasicMenuComponent
local BasicMenuComponent, super = Class(AbstractMenuComponent)

function BasicMenuComponent:init(x, y, x_sizing, y_sizing)
    super.init(self, x, y, x_sizing, y_sizing)
end

function BasicMenuComponent:update()
    super.update(self)

    if Input.pressed("up") then
        self:previous()
    elseif Input.pressed("down") then
        self:next()
    elseif Input.pressed("confirm") then
        if self.children[self.selected_item] and self.children[self.selected_item].onSelected then
            self.children[self.selected_item]:onSelected()
        end
    end
end

return BasicMenuComponent
