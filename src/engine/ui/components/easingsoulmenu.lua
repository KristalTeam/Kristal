---@class EasingSoulMenuComponent : BasicMenuComponent
---@overload fun(...) : EasingSoulMenuComponent
local EasingSoulMenuComponent, super = Class(BasicMenuComponent)

function EasingSoulMenuComponent:init(x, y, x_sizing, y_sizing)
    super.init(self, x, y, x_sizing, y_sizing)

    self.soul_sprite = self:addChild(Sprite("player/heart_menu", 0, 10))
    self.soul_sprite:setScale(2, 2)
    self.soul_sprite:setColor(Kristal.getSoulColor())

    self.soul_target_x = 0
    self.soul_target_y = 10
end

function EasingSoulMenuComponent:getComponents()
    -- Don't include the soul sprite in the list of items, since it's not a menu item
    -- and shouldn't be selectable
    -- It also shouldn't affect the flow either
    local items = {}
    for _, child in ipairs(super.getComponents(self)) do
        if child ~= self.soul_sprite then
            table.insert(items, child)
        end
    end
    return items
end

function EasingSoulMenuComponent:updateSelected(old_item)
    super.updateSelected(self, old_item)

    local item = self:getComponents()[self.selected_item]
    if item then
        self.soul_target_x = item.x
        self.soul_target_y = item.y + 10
    end
end

function EasingSoulMenuComponent:update()
    super.update(self)

    if (math.abs((self.soul_target_x - self.soul_sprite.x)) <= 2) then
        self.soul_sprite.x = self.soul_target_x
    end
    if (math.abs((self.soul_target_y - self.soul_sprite.y)) <= 2)then
        self.soul_sprite.y = self.soul_target_y
    end
    self.soul_sprite.x = self.soul_sprite.x + ((self.soul_target_x - self.soul_sprite.x) / 2) * DTMULT
    self.soul_sprite.y = self.soul_sprite.y + ((self.soul_target_y - self.soul_sprite.y) / 2) * DTMULT
end

return EasingSoulMenuComponent
