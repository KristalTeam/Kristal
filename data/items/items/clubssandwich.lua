local item, super = Class(HealItem, "clubssandwich")

function item:init()
    super.init(self)

    -- Display name
    self.name = "ClubsSandwich"
    -- Name displayed when used in battle (optional)
    self.use_name = "CLUBS SANDWICH"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Amount healed (HealItem variable)
    if Game.chapter == 1 then
        self.heal_amount = 30
    else
        self.heal_amount = 70
    end

    -- Battle description
    self.effect = "Heals\nteam\n"..self.heal_amount.."HP"
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A sandwich that can be split into 3.\nHeals "..self.heal_amount.." HP to the team."

    -- Default shop price (sell price is halved)
    self.price = 70
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
        susie = "Quit hogging!",
        ralsei = "(It's cut evenly...)",
        noelle = "(Kris took two thirds of it...)"
    }
end

function item:getWorldMenuName()
    return "Clubswich"
end

return item