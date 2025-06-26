local item, super = Class(HealItem, "scarlixir")

function item:init()
    super.init(self)

    -- Display name
    self.name = "Scarlixir"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"

    -- Battle description
    self.effect = "Heals\n160HP"
    -- Shop description
    self.shop = "Sick\njuice that\nheals 160HP"
    -- Menu description
    self.description = "A red brew with a sickeningly fruity taste.\nRecovers 160 HP."

    -- Amount healed (HealItem variable)
    self.heal_amount = 160
    -- Amount taken and healed to Kris instead when used on Noelle
    self.heal_amount_last_drop = 5

    -- Default shop price (sell price is halved)
    self.price = 450
    -- Whether the item can be sold
    self.can_sell = true

    -- Consumable target mode (ally, party, enemy, enemies, or none)
    self.target = "ally"
    -- Where this item can be used (world, battle, all, or none/nil)
    self.usable_in = "all"
    -- Item this item will get turned into when consumed
    self.result_item = nil
    -- Will this item be instantly consumed in battles?
    self.instant = false

    -- Character reactions (key = party member id)
    self.reactions = {
        susie = "Hell yeah! Cheers!",
        ralsei = "Y-yuck! Er, mmm, medicine?",
        noelle = "... fine, you can have the LAST DROP."
    }
end

function item:getHealAmount(id)
    if id == "noelle" and Game:hasPartyMember("kris") then
        return self.heal_amount - self.heal_amount_last_drop
    else
        return self.heal_amount
    end
end

function item:onWorldUse(target)
    local consumed = super.onWorldUse(self, target)

    -- Heal Kris too when used on Noelle
    if target.id == "noelle" and Game:hasPartyMember("kris") then
        Game.world:heal("kris", self.heal_amount_last_drop)
    end

    return consumed
end

function item:onBattleUse(user, target)
    super.onBattleUse(self, user, target)

    -- Heal Kris too when used on Noelle
    if target.chara.id == "noelle" and Game:hasPartyMember("kris") then
        local kris_battler = Game.battle:getPartyBattler("kris")

        if kris_battler then
            kris_battler:heal(self.heal_amount_last_drop)
        end
    end
end

return item