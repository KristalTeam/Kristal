---@class EasingSoulMenuComponent : BasicMenuComponent
---@field soul_sprite Sprite
---@field soul EasingSoul
---@field soul_target_x number
---@field soul_target_y number
---@field scroll_target_x number
---@field scroll_target_y number
---@field soul_offset_x number
---@field soul_offset_y number
---@overload fun(...) : EasingSoulMenuComponent
local EasingSoulMenuComponent, super = Class(BasicMenuComponent)

---@param x_sizing? Sizing
---@param y_sizing? Sizing
---@param options? table
function EasingSoulMenuComponent:init(x_sizing, y_sizing, options)
    super.init(self, x_sizing, y_sizing, options)
    options = options or {}

    if not options.soul then
        self.soul_sprite = self:addChild(Sprite("player/heart_menu", 0, 10))
        self.soul_sprite:setScale(2, 2)
        self.soul_sprite:setColor(Kristal.getSoulColor())
        self.soul_sprite.layer = 100
    else
        self.soul = options.soul
    end

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

    local item = self:getMenuItems()[self.selected_item]
    if self.scroll_type == "paged" then
        self.scroll_target_x = math.floor((self.scroll_x + item.x) / self.width) * self.width
        self.scroll_target_y = math.floor((self.scroll_y + item.y) / self.height) * self.height
    else
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
    end

    self.soul_target_x = (item.x - (self.scroll_target_x - self.scroll_x)) + (item.soul_offset_x or 0) + self.soul_offset_x
    self.soul_target_y = (item.y - (self.scroll_target_y - self.scroll_y)) + (item.soul_offset_y or 0) + self.soul_offset_y

    if self.soul and self:isFocused() then
        local x, y = self:getRelativePos(self.soul_target_x, self.soul_target_y, self.soul.parent)
        self.soul:setTarget(x, y)
    end
end

function EasingSoulMenuComponent:update()
    super.update(self)

    if self.soul_sprite then
        if (math.abs((self.soul_target_x - self.soul_sprite.x)) <= 2) then
            self.soul_sprite.x = self.soul_target_x
        end
        if (math.abs((self.soul_target_y - self.soul_sprite.y)) <= 2) then
            self.soul_sprite.y = self.soul_target_y
        end
        self.soul_sprite.x = self.soul_sprite.x + ((self.soul_target_x - self.soul_sprite.x) / 2) * DTMULT
        self.soul_sprite.y = self.soul_sprite.y + ((self.soul_target_y - self.soul_sprite.y) / 2) * DTMULT
    end

    if (math.abs((self.scroll_target_x - self.scroll_x)) <= 2) then
        self.scroll_x = self.scroll_target_x
    end
    if (math.abs((self.scroll_target_y - self.scroll_y)) <= 2) then
        self.scroll_y = self.scroll_target_y
    end
    self.scroll_x = self.scroll_x + ((self.scroll_target_x - self.scroll_x) / 2) * DTMULT
    self.scroll_y = self.scroll_y + ((self.scroll_target_y - self.scroll_y) / 2) * DTMULT

    if self.soul and self:isFocused() then
        self.soul:moveSoul()
    end
end

return EasingSoulMenuComponent
