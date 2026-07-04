local item, super = Class(Item, "yellowhat")

function item:init()
    super.init(self)

    -- Display name
    self.name = "YellowHat"

    -- Item type (item, key, weapon, armor)
    self.type = "armor"
    -- Item icon (for equipment)
    self.icon = "ui/menu/icon/cowboy_hat"

    -- Battle description
    self.effect = ""
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "The hat of a just cowboy. Makes spells\n20% more effective."

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
        attack = 4,
        defense = 4,
        magic = 4
    }
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = "Skill20%"
    self.bonus_icon = "ui/menu/icon/up"

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions
    self.reactions = {
        susie = "Get in Horse Mode, Ralsei.",
        ralsei = "Can Susie be the horse?",
        noelle = "(At least I'm not the horse)",
    }
end

return item
