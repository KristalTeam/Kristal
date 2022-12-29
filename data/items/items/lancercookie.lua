local item, super = Class(HealItem, "lancercookie")

function item:init()
    super.init(self)

    -- Display name
    self.name = "LancerCookie"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Heals\n50HP"
    -- Shop description
    self.shop = ""
    -- Menu description
    if Game.chapter == 1 then
        self.description = "A cookie shaped like Lancer's face.\nMaybe not a cookie. Heals 5 HP?"
    else
        self.description = "A cookie shaped like Lancer's face.\nMaybe not a cookie. Heals 1 HP?"
    end

    -- Amount this item heals for in the overworld (optional)
    if Game.chapter == 1 then
        self.world_heal_amount = 4
    else
        self.world_heal_amount = 1
    end
    -- Amount this item heals for in battle (optional)
    self.battle_heal_amount = 50

    -- Default shop price (sell price is halved)
    self.price = 10
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
        susie = "Mmm... face",
        ralsei = "(uncomfortable)",
        noelle = "Umm, what is this? It's cute..."
    }
end

return item