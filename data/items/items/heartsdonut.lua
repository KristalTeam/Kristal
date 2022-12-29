local item, super = Class(HealItem, "heartsdonut")

function item:init()
    super.init(self)

    -- Display name
    self.name = "HeartsDonut"
    -- Name displayed when used in battle (optional)
    self.use_name = "HEARTS DONUT"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Healing\nvaries"
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "Hearts, don't it!? It's filled with\ndivisive, clotty red jam. +??HP"

    -- Amount healed (HealItem variable)
    self.heal_amount = 50
    -- Amount this item heals for specific characters
    self.heal_amounts = {
        ["kris"] = 20,
        ["susie"] = 80,
        ["ralsei"] = 50,
        ["noelle"] = 30
    }

    -- ?????
    if Game.chapter == 1 then
        self.battle_heal_amounts = {
            ["kris"] = 10,
            ["susie"] = 90,
            ["ralsie"] = 60
        }
    end

    -- Default shop price (sell price is halved)
    self.price = 40
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
        susie = "Mmm, blood!",
        ralsei = "Aah, sticky...",
        noelle = "Mmm... what!? It's blood!?"
    }
end

return item