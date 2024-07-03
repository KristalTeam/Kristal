local item, super = Class(Item, "shadowcrystal")

function item:init()
    super.init(self)

    -- Display name
    self.name = "ShadowCrystal"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "key"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A sharp shadow moves like water in the hand."

    -- Default shop price (sell price is halved)
    self.price = 0
    -- Whether the item can be sold
    self.can_sell = false

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "none"
    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "world"
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

function item:getCollected()
    return Game:getFlag("shadow_crystals", 0)
end

function item:getDescription()
    local desc = super.getDescription(self)
    if self:getCollected() > 0 then
        desc = desc .. "\nYou have collected [" .. self:getCollected() .. "]."
    end
    return desc
end

function item:onWorldUse()
    if Kristal.callEvent(KRISTAL_EVENT.onShadowCrystal, self, false) then
        return
    elseif not self:getFlag("used_none") then
        self:setFlag("used_none", true)

        Game.world:showText({
            "* You held the crystal up to your\neye.",
            "* ...[wait:5] but nothing happened."
        })
    else
        Game.world:showText("* It doesn't seem very useful.")
    end
end

function item:convertToLight(inventory)
    local glass = inventory:addItem("light/glass")
    glass.flags = self.flags
    return true
end

return item