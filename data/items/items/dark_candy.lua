local item, super = Class(HealItem, "dark_candy")

function item:init()
    super:init(self)

    -- Display name
    self.name = "Dark Candy"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Heals\n40HP"
    -- Shop description
    self.shop = nil
    -- Menu description
    self.description = "Heals 40 HP. A red-and-black star\nthat tastes like marshmallows."

    -- Amount healed (HealItem variable)
    self.heal_amount = 40

    -- Shop sell price
    self.price = 13

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    self.target = "party"
    -- Where this item can be used (world, battle, all, or none/nil)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {}
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions (key = party member id)
    self.reactions = {
        susie = "Yeahh!! That's good!",
        ralsei = {
            ralsei = "A bit burnt...?",
            susie = "Hey, feed ME!!!"
        },
        noelle = "Oh, it's... sticky?"
    }
end

return item