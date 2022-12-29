local item, super = Class(HealItem, "rouxlsroux")

function item:init()
    super.init(self)

    -- Display name
    self.name = "RouxlsRoux"
    -- Name displayed when used in battle (optional)
    self.use_name = "ROUXLS ROUX"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Heals\n50 HP"
    -- Shop description
    self.shop = "Fragrant\nsauce\nheals 50HP"
    -- Menu description
    self.description = "A dark roux with a delicate aroma.\nAlso... has worms in it. +50HP"

    -- Amount healed (HealItem variable)
    self.heal_amount = 50

    -- ok ????
    if Game.chapter == 1 then
        self.battle_heal_amount = 60
    end

    -- Default shop price (sell price is halved)
    self.price = 50
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
        susie = "Cool, it's wriggling.",
        ralsei = "Yum, is this spaghetti?",
        noelle = "Tastes like... jumprope?"
    }
end

return item