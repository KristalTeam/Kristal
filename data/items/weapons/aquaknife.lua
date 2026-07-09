local item, super = Class(Item, "aquaknife")

function item:init()
    super.init(self)

    -- Display name
    self.name = "AquaKnife"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/knife"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A mischievous blade. Attacks with this\nweapon are easier to make critical."

    -- Default shop price (sell price is halved)
    self.price = 2
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
        attack = 10,
        defense = 2
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "Critical"
    self.bonus_icon = "ui/menu/icon/up"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        kris = true
    }

    -- Character reactions
    self.reactions = {
        susie = "Too small. Kris-size.",
        ralsei = "Umm, I might hurt myself...",
        noelle = "That's, um, nostalgic."
    }
end

function item:convertToLightEquip(chara)
    return "light/petal"
end

function item:getAttackCritBoxSize(battler)
    return 2
end

return item
