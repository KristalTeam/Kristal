local item, super = Class(HealItem, "darkburger")

function item:init()
    super:init(self)

    -- Display name
    self.name = "Darkburger"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Heals\n70HP"
    -- Shop description
    self.shop = "Mysterious\nhamburger\nheals 70HP"
    -- Menu description
    self.description = "A mysterious black burger made of...\nHey, this is just burnt! +70HP"

    -- Amount healed (HealItem variable)
    self.heal_amount = 70

    -- Shop buy price
    self.buy_price = 70
    -- Shop sell price (usually half of buy price)
    self.sell_price = 35

    -- Consumable target mode (party, enemy, noselect, or none/nil)
    self.target = "party"
    -- Where this item can be used (world, battle, all, or none/nil)
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
        susie = "Cooked to perfection!",
        ralsei = "A bit burnt...?",
        noelle = "I-is this real meat...?"
    }
end

return item