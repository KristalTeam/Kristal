---@class AbstractMenuComponent : Component
---@overload fun(...) : AbstractMenuComponent
local AbstractMenuComponent, super = Class(Component)

function AbstractMenuComponent:init(x, y, x_sizing, y_sizing)
    super.init(self, x, y, x_sizing, y_sizing)

    self.selected_item = 1
end

function AbstractMenuComponent:onAddToStage(stage)
    super.onAddToStage(self, stage)

    if #self.children <= 0 then
        error("Menu components must have at least one child before becoming active")
    end

    if self.children[self.selected_item] and self.children[self.selected_item].onHovered then
        self.children[self.selected_item]:onHovered(true, true)
    end
end

return AbstractMenuComponent
