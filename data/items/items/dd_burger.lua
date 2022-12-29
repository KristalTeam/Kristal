local item, super = Class(HealItem, "dd_burger")

function item:init()
    super.init(self)

    -- Display name
    self.name = "DD-Burger"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Heals\n60HP 2x"
    -- Shop description
    self.shop = "Double\ndarkburger\n60HP 2x"
    -- Menu description
    self.description = "It's the Double-Dark-Burger.\nIt'll take two bites to finish!"

    -- Amount healed (HealItem variable)
    self.heal_amount = 60
    -- Amount this item heals for specific characters in the overworld (optional)
    self.world_heal_amounts = {
        ["noelle"] = 20
    }

    -- Default shop price (sell price is halved)
    self.price = 110
    -- Whether the item can be sold
    self.can_sell = true

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"
    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = "darkburger"
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
        susie = "C'mon, gimme the rest!",
        ralsei = "M-maybe give Susie the rest?",
        noelle = "Th... there's MORE!?"
    }
end

return item