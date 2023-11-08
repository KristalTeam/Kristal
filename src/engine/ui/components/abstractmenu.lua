---@class AbstractMenuComponent : Component
---@overload fun(...) : AbstractMenuComponent
local AbstractMenuComponent, super = Class(Component)

function AbstractMenuComponent:init(x, y, x_sizing, y_sizing)
    super.init(self, x, y, x_sizing, y_sizing)

    self.selected_item = 1
end

function AbstractMenuComponent:previous()
    local old_item = self.selected_item
    self.selected_item = self.selected_item - 1

    self:keepInBounds()

    if old_item ~= self.selected_item then
        self:updateSelected(old_item)
    end
end

function AbstractMenuComponent:next()
    local old_item = self.selected_item
    self.selected_item = self.selected_item + 1

    self:keepInBounds()

    if old_item ~= self.selected_item then
        self:updateSelected(old_item)
    end
end

function AbstractMenuComponent:keepInBounds()
    if self.selected_item < 1 then
        self.selected_item = #self.children
    elseif self.selected_item > #self.children then
        self.selected_item = 1
    end
end

function AbstractMenuComponent:updateSelected(old_item)
    if old_item then
        if self.children[old_item] and self.children[old_item].onHovered then
            self.children[old_item]:onHovered(false, false)
        end
    end
    if self.children[self.selected_item] and self.children[self.selected_item].onHovered then
        self.children[self.selected_item]:onHovered(true, false)
    end
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
