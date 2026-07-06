local item, super = Class(HealItem, "phanta")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Phanta"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Amount healed (HealItem variable)
    self.heal_amount = 200
    self.heal_amount_other = 100
    self.tp_amount = 16

    -- Battle description
    self.effect = "Raises TP 16%\n+" .. self.heal_amount_other .. "HP"
    -- Shop description
    self.shop = "Purple soda in hidden flavor\n+" .. self.heal_amount_other .. "HP? +16TP"
    -- Menu description
    self.description = "Grape flavored phantasmagoria of a soda's dream.\n +Slight%TP, +" .. self.heal_amount_other .. "HP unless you like it more."

    -- Default shop price (sell price is halved)
    self.price = 222
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
        susie = "Bought. With money. Hell yeah.",
        ralsei = "But, it's Susie's favorite...",
        noelle = "Look, Kris! Susie's venom! (drinks it) (drinks it)"
    }
end

function item:getHealAmount(id)
    if id == "susie" then
        return self.heal_amount
    else
        return self.heal_amount_other
    end
end

return item