local item, super = Class(HealItem, "favwich")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Favwich"
    -- Name displayed when used in battle (optional)
    self.use_name = "FAV SANDWICH"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Heals\nALL HP"
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "You'd think it tastes perfect.\nHeals 500HP."

    -- Amount healed (HealItem variable)
    self.heal_amount = 500

    -- Default shop price (sell price is halved)
    self.price = 10
    -- Whether the item can be sold
    self.can_sell = true

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"
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
        susie = "(It's SO good!)",
        ralsei = "K-Kris!? I...",
        noelle = "(Huh? I didn't know Kris liked this flavor.)"
    }
end

return item