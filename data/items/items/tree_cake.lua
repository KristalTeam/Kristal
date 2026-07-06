local item, super = Class(HealItem, "tree_cake")

function item:init()
    super.init(self)

    -- Display name
    self.name = "TreeCake"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Amount healed (HealItem variable)
    self.heal_amount = 160

    -- Battle description
    self.effect = "Heals team\n" .. self.heal_amount .. "HP"
    -- Menu description
    self.description = "A cake of bread laden with joyful memories.\nRecovers" .. self.heal_amount .. "HP to all."

    -- Default shop price (sell price is halved)
    self.price = 200
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
        susie = "Mmm, Ralsei's cake.",
        ralsei = "Mmm, cotton candy.",
        noelle = "Mmm, water bubbler. I mean, fruitcake."
    }
end

return item