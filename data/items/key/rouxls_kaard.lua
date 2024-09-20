local item, super = Class(Item, "rouxls_kaard")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Rouxls Kaard"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "key"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = nil
    -- Menu description
    self.description = "Thou gazeth upon a man most handsometh.\nThis daringst genius, adoredeth beyondth all hey let me speakest"

    -- Default shop price (sell price is halved)
    self.price = nil
    -- Whether the item can be sold
    self.can_sell = false

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "none"
    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = nil
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {}
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions (key = party member id)
    self.reactions = {}
end

function item:onMenuOpen(menu)
    menu.box:setLayer(WORLD_LAYERS["ui"])
end

function item:isVisible()
    return true
end

function item:onMenuDraw(menu)
    local x, y = menu.box:screenToLocalPos(0, 0)
    if menu.box.state == "SELECT" and self:isVisible() then
        love.graphics.draw(Assets.getTexture("kristal/rouxls_kaard", x, y), x + 470, y + 230, 0, 2)
    end
end

function item:convertToLight(inventory)
    if inventory:hasItem("light/cards") then
        local light_item = inventory:getItemByID("light/cards")
        table.insert(light_item.cards, self.id)
        return true
    else
        local light_item = Registry.createItem("light/cards")
        table.insert(light_item.cards, self.id)
        return light_item
    end
end

return item
