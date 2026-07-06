local item, super = Class(HealItem, "s_potion")

function item:init()
    super.init(self)

    -- Display name
    self.name = "S. POTION"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Amount healed (HealItem variable)
    self.heal_amount = 200

    -- Battle description
    self.effect = "Heals\nparty\nmember"
    -- Menu description
    self.description = "An energy drink collaborating with a certain car brand.\nRecovers " .. self.heal_amount .. "HP"

    -- Default shop price (sell price is halved)
    self.price = 500
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
        susie = "Still kinda burns.",
        ralsei = "Um, is it caffeinated?",
        noelle = "This... is expired!"
    }
end

return item