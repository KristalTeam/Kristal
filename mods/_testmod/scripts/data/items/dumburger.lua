local item, super = Class(HealItem, "dumburger")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Dumburger"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Really\nstupid"
    -- Shop description
    self.shop = "Radiates\nstupidity\nheals 1000HP"
    -- Menu description
    self.description = "Completely worthless"

    -- Amount healed (HealItem variable)
    self.heal_amount = 1000

    -- Shop buy price
    self.buy_price = 0
    -- Shop sell price (usually half of buy price)
    self.sell_price = 0

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "enemy"
    -- Where this item can be used (world, battle, all, or none)
    self.usable_in = "battle"
    -- Item this item will get turned into when consumed
    self.result_item = nil

    -- Equip bonuses (for weapons and armor)
    self.bonuses = {}
    -- Bonus name and icon (displayed in equip menu)
    self.bonus_name = nil
    self.bonus_icon = nil

    -- Equippable characters (default true for armors, false for weapons)
    self.can_equip = {}

    -- Character reactions (key = party member id)
    self.reactions = {}
end

function item:onBattleSelect(user, target)
    -- Do not consume
    return false
end

return item