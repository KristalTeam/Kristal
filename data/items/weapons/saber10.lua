local item, super = Class(Item, "saber10")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Saber10"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/sword"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = "Tsun-type\narmaments"
    -- Menu description
    self.description = "A saber made of 10 cactus needles.\nFortunately, can deal more than 10 damage."

    -- Default shop price (sell price is halved)
    self.price = Game.chapter <= 3 and 610 or 710
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
        attack = 6,
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
        susie = "Nah, I'd snap it.",
        ralsei = "You want to... pierce my ears...?",
        noelle = "(I'm not against using it, but...)",
    }
end

function item:convertToLightEquip(chara)
    return "light/cactusneedle"
end

return item