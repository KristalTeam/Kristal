local item, super = Class(Item, "revivedust")

function item:init()
    super.init(self)

    -- Display name
    self.name = "ReviveDust"
    -- Name displayed when used in battle (optional)
    self.use_name = nil

    -- Item type (item, key, weapon, armor)
    self.type = "item"
    -- Item icon (for equipment)
    self.icon = nil

    -- Battle description
    self.effect = "Revives\nteam\n25%"
    -- Shop description
    self.shop = ""
    -- Menu description
    self.description = "A minty powder that revives all\nfallen party members to 25% HP."

    -- Default shop price (sell price is halved)
    self.price = 100
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

    -- Character reactions
    self.reactions = {
        susie = "Don't throw dust at me!",
        ralsei = "It's minty!",
        noelle = "What are you sprinkling?"
    }
end

function item:onWorldUse(target)
    for _,party_member in ipairs(Game.party) do
        Game.world:heal(party_member, 10)
    end
    return true
end

function item:onBattleUse(user, target)
    for _,battler in ipairs(Game.battle.party) do
        if battler.chara:getHealth() <= 0 then
            battler:heal(math.abs(battler.chara:getHealth()) + math.ceil(battler.chara:getStat("health") / 4))
        else
            battler:heal(10)
        end
    end
end

return item