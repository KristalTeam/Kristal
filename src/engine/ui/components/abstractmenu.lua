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
        self.selected_item = #self:getMenuItems()
    elseif self.selected_item > #self:getMenuItems() then
        self.selected_item = 1
    end
end

function AbstractMenuComponent:updateSelected(old_item)
    if old_item then
        if self:getMenuItems()[old_item] and self:getMenuItems()[old_item].onHovered then
            self:getMenuItems()[old_item]:onHovered(false, false)
        end
    end
    if self:getMenuItems()[self.selected_item] and self:getMenuItems()[self.selected_item].onHovered then
        self:getMenuItems()[self.selected_item]:onHovered(true, false)
    end
end

function AbstractMenuComponent:onAddToStage(stage)
    super.onAddToStage(self, stage)

    if #self:getMenuItems() <= 0 then
        error("Menu components must have at least one item before becoming active")
    end

    if self:getMenuItems()[self.selected_item] and self:getMenuItems()[self.selected_item].onHovered then
        self:getMenuItems()[self.selected_item]:onHovered(true, true)
    end
end

function AbstractMenuComponent:getMenuItems()
    local components = {}
    for _, child in ipairs(self.children) do
        if child:includes(AbstractMenuItemComponent) then
            table.insert(components, child)
        end
    end
    return components
end

return AbstractMenuComponent
