local item, super = Class(HealItem, "flowery_soda")

function item:init()
    super.init(self)

    -- Display name
    self.name = "FlowerySoda"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Amount healed (HealItem variable)
    self.heal_amount = 200
    self.heal_amount_other = 50

    -- Battle description
    self.effect = "Raises TP 16%\n+" .. self.heal_amount_other .. "HP"
    -- Shop description
    self.shop = "Ralsei's obvious favorite\n+" .. self.heal_amount_other .. "HP? +16TP"
    -- Menu description
    self.description = "Embarrassingly white lactose flavor.\nSaid to be Ralsei's favorite on the bottle."

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
        susie = "Eww, Ralsei likes lactose?",
        ralsei = "I... I'm not thirsty.",
        noelle = "........ who the heck is Flowery?"
    }
end

function item:getHealAmount(id)
    if id == "ralsei" then
        return self.heal_amount
    else
        return self.heal_amount_other
    end
end

return item