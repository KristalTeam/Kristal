-- Instead of Item, create a HealItem, a convenient class for consumable healing items
local item, super = Class(HealItem, "ultimate_candy")

function item:init()
    super.init(self)

    -- Display name
    self.name = "UltimatCandy"
    -- Name displayed when used in battle (optional)
    self.use_name = "ULTIMATE CANDY"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Best\nhealing"
    -- Shop description
    self.shop = "Perfection"
    -- Menu description
    self.description = "Sparkles with perfection.\nMust be shared with everyone. +??HP"

    -- Amount healed (HealItem variable)
    self.heal_amount = 1

    -- Default shop price (sell price is halved)
    self.price = 100
    -- Whether the item can be sold
    self.can_sell = true

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "party"
    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
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
    self.reactions = {
        susie = "Hey! It's hollow inside!",
        ralsei = "I like the texture!",
        noelle = "That was underwhelming...",
    }
end

return item