local item, super = Class(Item, "mechasaber")

function item:init()
    super.init(self)

    -- Display name
    self.name = "MechaSaber"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/sword"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = "Press hilt\nto extend"
    -- Menu description
    self.description = "The blade extends when you press the hilt.\nCHA-CHK!"

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
    self.bonus_name = "Annoying"
    self.bonus_icon = "ui/menu/icon/demon"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        kris = true,
    }

    -- Character reactions
    self.reactions = {
        susie = "*chk chk chk chk* Nah.",
        ralsei = "You'd look cool holding it, Kris!",
        noelle = "*chk* A-AHH! Scared myself...",
    }
end

function item:convertToLightEquip(chara)
    return "light/mech_pencil"
end

return item