---@class BasicMenuComponent : AbstractMenuComponent
---@overload fun(...) : BasicMenuComponent
local BasicMenuComponent, super = Class(AbstractMenuComponent)

function BasicMenuComponent:init(x, y, x_sizing, y_sizing)
    super.init(self, x, y, x_sizing, y_sizing)
end

function BasicMenuComponent:update()
    super.update(self)

    local old_item = self.selected_item
    if Input.pressed("up") then
        self.selected_item = self.selected_item - 1
    elseif Input.pressed("down") then
        self.selected_item = self.selected_item + 1
    elseif Input.pressed("confirm") then
        if self.children[self.selected_item] and self.children[self.selected_item].onSelected then
            self.children[self.selected_item]:onSelected()
        end
    end

    if self.selected_item < 1 then
        self.selected_item = #self.children
    elseif self.selected_item > #self.children then
        self.selected_item = 1
    end

    if old_item ~= self.selected_item then
        if self.children[old_item] and self.children[old_item].onHovered then
            self.children[old_item]:onHovered(false, false)
        end
        if self.children[self.selected_item] and self.children[self.selected_item].onHovered then
            self.children[self.selected_item]:onHovered(true, false)
        end
    end
end

return BasicMenuComponent
