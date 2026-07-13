-- Create a healing item and specify its ID (id is optional, defaults to file path)
---@class TemplateFoodItem : HealItem
local item, super = Class(HealItem, "test_food")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Test Food"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    self.icon = nil
    self.light = false

    -- Battle description
    self.effect = "Heals\n100HP"
    -- Shop description
    self.shop = "Example\nfood\nheals 100HP"
    -- Menu description
    self.description = "Example food. +100HP"
    self.check = "Heals 100HP"

    -- Amount healed (HealItem variable)
    self.heal_amount = 100
    self.world_heal_amount = nil
    self.battle_heal_amount = nil
    self.heal_amounts = {}
    self.world_heal_amounts = {}
    self.battle_heal_amounts = {}

    -- Default shop price (sell price is halved)
    self.price = 0
    -- Whether the item can be sold
    self.can_sell = true
    self.buy_price = nil
    self.sell_price = nil

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"
    -- Where this item can be used (world, battle, all, or none/nil)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Equip bonuses (available when using this as equipment)
    self.bonuses = {}
    self.bonus_name = nil
    self.bonus_icon = nil
    self.bonus_color = PALETTE["world_ability_icon"]
    self.can_equip = {}

    -- Character reactions (key = party member id)
    self.reactions = {}
end

-- Function overrides go here

return item
