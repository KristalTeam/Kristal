local item, super = Class(Item, "dogwidow")

function item:init()
    super.init(self)

    -- Display name
    self.name = "DogWidow"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/armor"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A brooch in the shape of a golden pooch.\nYou lose almost all money after battle."

    -- Default shop price (sell price is halved)
    self.price = 6000
    -- Whether the item can be sold
    self.can_sell = true

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "none"
    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {
        defense = 6
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "$ -90%"
    self.bonus_icon = "ui/menu/icon/down"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {
        susie = "This is annoying.",
        ralsei = "This is annoying.",
        noelle = "Pff... YOU should wear it, Kris.",
    }
end

function item:calculateBattleMoney(money, base_money, num_equipped)
    return MathUtils.clamp(money - (money * (0.9 * num_equipped)), 0, money)
end

function item:calculateBattleMoneyPriority()
    return 0.6
end

return item
