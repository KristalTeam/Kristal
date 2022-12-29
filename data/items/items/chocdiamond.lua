local item, super = Class(HealItem, "chocdiamond")

function item:init()
    super.init(self)

    -- Display name
    self.name = "ChocDiamond"
    -- Name displayed when used in battle (optional)
    self.use_name = "CHOCO DIAMOND"

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Healing\nvaries"
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "It's quite small, but some\npeople REALLY like it. +??HP"

    -- Amount healed (HealItem variable)
    self.heal_amount = 50
    -- Amount this item heals for specific characters
    self.heal_amounts = {
        ["kris"] = 80,
        ["susie"] = 20,
        ["ralsei"] = 50,
        ["noelle"] = 70
    }

    -- nice
    if Game.chapter == 1 then
        self.battle_heal_amounts = {
            ["susie"] = 30,
            ["ralsei"] = 30
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
        susie = "THAT'S it?",
        ralsei = "Aww, thanks, Kris!",
        noelle = "Umm, it's ok, Kris, I'll share..."
    }
end

function item:onWorldUse(target)
    -- Noelle shares with Kris if they're in the party
    if target.id == "noelle" and Game:hasPartyMember("kris") then
        local heal_amount = self:getWorldHealAmount(target.id)
        Game.world:heal("kris", heal_amount/2)
        Game.world:heal("noelle", heal_amount/2)
        return true
    else
        return super.onWorldUse(self, target)
    end
end

return item