local item, super = Class(Item, "darkgoldband")

function item:init()
    super.init(self)

    -- Display name
    self.name = "DarkGoldBand"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/armor"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A black metal with a golden shine."

    -- Default shop price (sell price is halved)
    self.price = (Game.chapter * 200) + ((Game.chapter - 1) * 220)
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
    self.bonuses = {}
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = " "
    self.bonus_icon = "ui/menu/icon/up"

    -- Equippable characters (default true for armors, false for weapons, false for this item in particular)
    self.can_equip = {
        kris = true,
    }

    -- Character reactions
    self.reactions = {
        susie = "Not even gonna ask.",
        ralsei = "Um, the d-dress is cute...",
        noelle = "(Why did they spend $300 on this!?)",
    }
end

function item:canEquip(character, slot_type, slot_index)
    -- Default equippable to false, like weapons
    return self.can_equip[character.id]
end

return item