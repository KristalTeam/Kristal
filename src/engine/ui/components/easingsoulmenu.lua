---@class EasingSoulMenuComponent : BasicMenuComponent
---@overload fun(...) : EasingSoulMenuComponent
local EasingSoulMenuComponent, super = Class(BasicMenuComponent)

function EasingSoulMenuComponent:init(x, y, x_sizing, y_sizing)
    super.init(self, x, y, x_sizing, y_sizing)

    self.soul_sprite = self:addChild(Sprite("player/heart_menu", 0, 10))
    self.soul_sprite:setScale(2, 2)
    self.soul_sprite:setColor(Kristal.getSoulColor())
    self.soul_sprite.layer = 100

    self.soul_target_x = 0
    self.soul_target_y = 10

    self.scroll_target_x = 0
    self.scroll_target_y = 0

    self.soul_offset_x = -28
    self.soul_offset_y = 10

    self:setPadding(-self.soul_offset_x, 0, 0, 0)
end

function EasingSoulMenuComponent:getComponents()
    -- Take the soul sprite out of the flow
    local items = {}
    for _, child in ipairs(super.getComponents(self)) do
        if child ~= self.soul_sprite then
            table.insert(items, child)
        end
    end
    return items
end

function EasingSoulMenuComponent:keepSelectedOnScreen()

end

function EasingSoulMenuComponent:update()
    super.update(self)

    local item = self:getMenuItems()[self.selected_item]
    if item then
        if item.x + item:getScaledWidth() > self.width then
            self.scroll_target_x = item.x + self.scroll_x + item:getScaledWidth() - self.width
        end

        if item.x < 0 then
            self.scroll_target_x = item.x + self.scroll_x
        end

        if item.y + item:getScaledHeight() > self.height then
            self.scroll_target_y = item.y + self.scroll_y + item:getScaledHeight() - self.height
        end

        if item.y < 0 then
            self.scroll_target_y = item.y + self.scroll_y
        end

        self.soul_target_x = (item.x - (self.scroll_target_x - self.scroll_x)) + (item.soul_offset_x or 0) + self.soul_offset_x
        self.soul_target_y = (item.y - (self.scroll_target_y - self.scroll_y)) + (item.soul_offset_y or 0) + self.soul_offset_y
    end

    if (math.abs((self.soul_target_x - self.soul_sprite.x)) <= 2) then
        self.soul_sprite.x = self.soul_target_x
    end
    if (math.abs((self.soul_target_y - self.soul_sprite.y)) <= 2) then
        self.soul_sprite.y = self.soul_target_y
    end
    self.soul_sprite.x = self.soul_sprite.x + ((self.soul_target_x - self.soul_sprite.x) / 2) * DTMULT
    self.soul_sprite.y = self.soul_sprite.y + ((self.soul_target_y - self.soul_sprite.y) / 2) * DTMULT

    if (math.abs((self.scroll_target_x - self.scroll_x)) <= 2) then
        self.scroll_x = self.scroll_target_x
    end
    if (math.abs((self.scroll_target_y - self.scroll_y)) <= 2) then
        self.scroll_y = self.scroll_target_y
    end
    self.scroll_x = self.scroll_x + ((self.scroll_target_x - self.scroll_x) / 2) * DTMULT
    self.scroll_y = self.scroll_y + ((self.scroll_target_y - self.scroll_y) / 2) * DTMULT
end

return EasingSoulMenuComponent
