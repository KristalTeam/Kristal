local item, super = Class(Item, "amber_card")

function item:init()
    super:init(self)

    -- Display name
    self.name = "Amber Card"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/armor"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = "Defensive\ncharm"
    -- Menu description
    self.description = "A thin square charm that sticks\nto you, increasing defense."

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
        defense = 1,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {
        susie = "... better than nothing.",
        ralsei = "It's sticky, huh, Kris...",
        noelle = "It's like a name-tag!",
    }
end

return item