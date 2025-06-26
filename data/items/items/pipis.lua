local item, super = Class(Item, "pipis")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Pipis"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Does\nnothing"
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A certain person's special \"???\"\nCannot be used in battle."

    -- Default shop price (sell price is halved)
    self.price = 0
    -- Whether the item can be sold
    self.can_sell = true

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"
    -- Where this item can be used (world, battle, all, or none)
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
        kris = {
            susie = "Huh?",
            ralsei = "Where'd it go?",
            noelle = "Kris! (I wanted that...)"
        },
        susie = "Hell no.",
        ralsei = "Is... that, um, nutritious?",
        noelle = "C... Can we keep it?"
    }
end

function item:onWorldUse(target)
    if target.id == "kris" then
        -- ????
        Game.world:heal(target, 100)
        return true
    else
        return false
    end
end

return item