local item, super = Class(Item, "trefoil")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Trefoil"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/sword"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "Mossy rapier with a clover emblem.\nIncreases $ found by 5%."

    -- Default shop price (sell price is halved)
    self.price = 250
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
        attack = 4,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "Money Earned UP"
    self.bonus_icon = "ui/menu/icon/up"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        kris = true,
    }

    -- Character reactions
    self.reactions = {
        susie = "That tacky thing? No!",
        ralsei = "Not my shade of green...",
        noelle = "Okay! ...? What do you mean, unused!?",
    }
end

function item:applyMoneyBonus(gold)
    return gold * 1.05
end

function item:convertToLightEquip(chara)
    return "light/lucky_pencil"
end

return item