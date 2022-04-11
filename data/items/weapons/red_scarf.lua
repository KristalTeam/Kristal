local item, super = Class(Item, "red_scarf")

function item:init()
    super:init(self)

    -- Display name
    self.name = "Red Scarf"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/scarf"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = "Basic\nscarf"
    -- Menu description
    self.description = "A basic scarf made of lightly\nmagical fiber."

    -- Shop buy price
    self.buy_price = 100
    -- Shop sell price (usually half of buy price)
    self.sell_price = 50

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
        ralsei = true,
    }

    -- Character reactions
    self.reactions = {
        susie = "No. Just... no.",
        ralsei = "Comfy! Touch it, Kris!",
        noelle = "Huh? No, I'm not cold.",
    }
end

return item