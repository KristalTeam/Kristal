local item, super = Class(Item, "truetie")

function item:init()
    super.init(self)

    -- Display name
    self.name = "TrueTie"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/armor"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "The genuine tie worn by a forgotten TV star.\nDefends against the Puppet&Cat element."

    -- Default shop price (sell price is halved)
    self.price = 1000
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
        attack = 1,
        defense = 5
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "CatDefend"
    self.bonus_icon = "ui/menu/icon/smile_dog"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {
        susie = "More hand-me-downs?",
        ralsei = "Ready for my close-up!",
        noelle = "What's next, a fedora?",
    }

    -- TODO: Elemental resistance
    -- Resists element 6 by 0.2
end

return item
