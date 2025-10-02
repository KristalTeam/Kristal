local item, super = Class(Item, "winglade")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Winglade"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/sword"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A majestic sword with a white feathered hilt.\nSlightly increases money won."

    -- Default shop price (sell price is halved)
    self.price = 999
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
        attack = 8,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "$ +5%"
    self.bonus_icon = "ui/menu/icon/up"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        kris = true,
    }

    -- Character reactions
    self.reactions = {
        susie = "Don't make me sneeze!",
        ralsei = "Th-that tickles!",
        noelle = "... whose feather is this?",
    }
end

function item:convertToLightEquip(chara)
    return "light/quillpen"
end

function item:applyMoneyBonus(gold)
    return gold * 1.05
end

return item