local item, super = Class(Item, "absorbax")

function item:init()
    super.init(self)

    -- Display name
    self.name = "AbsorbAx"

    -- Item type (item, key, weapon, armor)
    self.type = "weapon"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/axe"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A long, curved axe with an indent.\nScoop up HP when you attack."

    -- Default shop price (sell price is halved)
    self.price = 1234
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
    self.bonus_name = "Vampire"
    self.bonus_icon = "ui/menu/icon/demon"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {
        susie = true,
    }

    -- Character reactions
    self.reactions = {
        susie = "Scoopin' time.",
        ralsei = "Don't scoop me!",
        noelle = "That red... is that blood?",
    }
end

function item:onAttackHit(battler, enemy, damage)
    local heal_amount = math.ceil(battler.chara:getStat("health") * 0.1)

    battler:heal(heal_amount)
end

return item