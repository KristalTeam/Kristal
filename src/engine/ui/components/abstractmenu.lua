---@class AbstractMenuComponent : Component
---@field selected_item integer
---@field scroll_type string
---| "'scroll'"
---| "'paged'"
---@field open_sound string
---@field close_sound string
---@overload fun(...) : AbstractMenuComponent
local AbstractMenuComponent, super = Class(Component)

---@param x_sizing? Sizing
---@param y_sizing? Sizing
---@param options? table
function AbstractMenuComponent:init(x_sizing, y_sizing, options)
    super.init(self, x_sizing, y_sizing, options)

    self.selected_item = 1

    self.scroll_type = "scroll"

    self.open_sound = nil
    self.close_sound = "ui_move"

    self.close_callback = nil
end

function AbstractMenuComponent:setScrollType(type)
    self.scroll_type = type
end

function AbstractMenuComponent:update()
    super.update(self)

    self:keepSelectedOnScreen()
end

function AbstractMenuComponent:setSelected(item)
    local old_item = self.selected_item
    self.selected_item = item
    self:keepInBounds()

    if self:getStage() then
        self:updateSelected(old_item)
    end
end

function AbstractMenuComponent:keepSelectedOnScreen()
    local items = self:getMenuItems()
    local selected = items[self.selected_item]

    if self.scroll_type == "paged" then
        self.scroll_x = math.floor((self.scroll_x + selected.x) / self.width) * self.width
        self.scroll_y = math.floor((self.scroll_y + selected.y) / self.height) * self.height
    else
        if selected.x + selected:getScaledWidth() > self.width then
            self.scroll_x = self.scroll_x + selected.x + selected:getScaledWidth() - self.width
        end

        if selected.x < 0 then
            self.scroll_x = self.scroll_x + selected.x
        end

        if selected.y + selected:getScaledHeight() > self.height then
            self.scroll_y = self.scroll_y + selected.y + selected:getScaledHeight() - self.height
        end

        if selected.y < 0 then
            self.scroll_y = self.scroll_y + selected.y
        end
    end
end

function AbstractMenuComponent:previous()
    self:setSelected(self.selected_item - 1)
end

function AbstractMenuComponent:next()
    self:setSelected(self.selected_item + 1)
end

function AbstractMenuComponent:close()
    if self.close_callback then
        self.close_callback()
    end
    if self.close_sound then
        Assets.playSound(self.close_sound)
    end
    self:remove()
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

    if self.open_sound then
        Assets.playSound(self.open_sound)
    end
end

function AbstractMenuComponent:onFocused()
    local item = self:getMenuItems()[self.selected_item]
    if item and item.onHovered then
        item:onHovered(true, true)
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
