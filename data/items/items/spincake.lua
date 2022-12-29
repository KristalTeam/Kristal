local item, super = Class(HealItem, "spincake")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Spincake"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Amount healed (HealItem variable)
    if Game.chapter == 1 then
        self.heal_amount = 80
    else
        self.heal_amount = 140
    end

    -- Battle description
    self.effect = "Heals\nteam\n"..self.heal_amount.."HP"
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A pastry in the shape of a top.\nHeals "..self.heal_amount.." HP to the team."

    -- Default shop price (sell price is halved)
    self.price = 5
    -- Whether the item can be sold
    self.can_sell = true

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "party"
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
        susie = "I'm dizzy.",
        ralsei = "Mmm, thank you!",
        noelle = "My eyes are spinning..."
    }
end

return item