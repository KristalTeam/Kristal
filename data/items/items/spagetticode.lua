local item, super = Class(HealItem, "spagetticode")

function item:init()
    super.init(self)

    -- Display name
    self.name = "SpagettiCode"
    -- Name displayed when used in battle (optional)
    self.use_name = "SPAGHETTICODE"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Heals\nteam\n30HP"
    -- Shop description
    self.shop = "Spaghetti\nwoven by\nmaster coders\nParty +30HP"
    -- Menu description
    self.description = "Spaghetti woven by master coders, made\nof macarons and ribbons. +30HP to all."

    -- Amount healed (HealItem variable)
    self.heal_amount = 30

    -- Default shop price (sell price is halved)
    self.price = 180
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
        susie = "I'm NOT wearing it.",
        ralsei = "How sweet!",
        noelle = "Reminds me of one of my sweaters."
    }
end

return item