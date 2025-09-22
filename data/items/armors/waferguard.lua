local item, super = Class(Item, "waferguard")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Waferguard"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/armor"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = "Holey\namulet"
    -- Menu description
    self.description = "Although it looks brittle, it contains a magical\nenergy that blunts damage on impact. +4DF"

    -- Default shop price (sell price is halved)
    self.price = 900
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
        defense = 4,
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {
        susie = "(Don't eat it. Don't eat it.)",
        ralsei = {
            susie = "(Too bad)",
            ralsei = "It's got drool on it.",
        },
        noelle = "What's next, cheezy armor? Faha!",
    }
end

return item