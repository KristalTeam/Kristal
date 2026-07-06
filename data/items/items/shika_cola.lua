local item, super = Class(HealItem, "shika_cola")

function item:init()
    super.init(self)

    -- Display name
    self.name = "ShikaCola"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Amount healed (HealItem variable)
    self.heal_amount = 5
    self.heal_amount_other = 80

    -- Battle description
    self.effect = "Heals team\n" .. self.heal_amount_other .. "HP"
    -- Shop description
    self.shop = "Natural\nungulate\ntaste\n+" .. self.heal_amount_other .. "HP to all"
    -- Menu description
    self.description = "A natural drink infused with nutmeg and deer hair.\nHeals all party members.\n+80HPall"

    -- Default shop price (sell price is halved)
    self.price = 222
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
        susie = "Noelle... should try this.",
        ralsei = "Let's save some for her?",
        noelle = "WHY WOULD I LIKE THIS??? IT HAS SOMEONE'S HAIR IN IT???"
    }
end

function item:getHealAmount(id)
    if id == "noelle" then
        return self.heal_amount
    else
        return self.heal_amount_other
    end
end

return item