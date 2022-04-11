local item, super = Class(Item, "wood_blade")

function item:init()
    super:init(self)

    -- Display name
    self.name = "Wood Blade"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/sword"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = "Practice\nblade"
    -- Menu description
    self.description = "A wooden practice blade with a carbon-\nreinforced core."

    -- Shop buy price
    self.buy_price = 60
    -- Shop sell price (usually half of buy price)
    self.sell_price = 30

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    self.target = nil
    -- Where this item can be used (world, battle, all, or none/nil)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {
        attack = 0,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        kris = true,
    }

    -- Character reactions
    self.reactions = {
        susie = "What's this!? A CHOPSTICK?",
        ralsei = "That's yours, Kris...",
        noelle = "(It has bite marks...)",
    }
end

return item