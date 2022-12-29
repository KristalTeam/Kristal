---@class HealItem : Item
---@overload fun(...) : HealItem
local HealItem, super = Class(Item)

function HealItem:init()
    super.init(self)

    -- Amount this item heals
    self.heal_amount = 0

    -- Amount this item heals for in the overworld (optional)
    self.world_heal_amount = nil
    -- Amount this item heals for in battle (optional)
    self.battle_heal_amount = nil

    -- Amount this item heals for specific characters
    self.heal_amounts = {}

    -- Amount this item heals for specific characters in the overworld (optional)
    self.world_heal_amounts = {}
    -- Amount this item heals for specific characters in battle (optional)
    self.battle_heal_amounts = {}
end

function HealItem:getHealAmount(id)
    return self.heal_amounts[id] or self.heal_amount
end

function HealItem:getWorldHealAmount(id)
    return self.world_heal_amounts[id] or self.world_heal_amount or self:getHealAmount(id)
end

function HealItem:getBattleHealAmount(id)
    return self.battle_heal_amounts[id] or self.battle_heal_amount or self:getHealAmount(id)
end

function HealItem:onWorldUse(target)
    if self.target == "ally" then
        -- Heal single party member
        local amount = self:getWorldHealAmount(target.id)
        Game.world:heal(target, amount)
        return true
    elseif self.target == "party" then
        -- Heal all party members
        for _,party_member in ipairs(target) do
            local amount = self:getWorldHealAmount(party_member.id)
            Game.world:heal(party_member, amount)
        end
        return true
    else
        -- No target or enemy target (?), do nothing
        return false
    end
end

function HealItem:onBattleUse(user, target)
    if self.target == "ally" then
        -- Heal single party member
        local amount = self:getBattleHealAmount(target.chara.id)
        target:heal(amount)
    elseif self.target == "party" then
        -- Heal all party members
        for _,battler in ipairs(target) do
            local amount = self:getBattleHealAmount(battler.chara.id)
            battler:heal(amount)
        end
    elseif self.target == "enemy" then
        -- Heal single enemy (why)
        local amount = self:getBattleHealAmount(target.id)
        target:heal(amount)
    elseif self.target == "enemies" then
        -- Heal all enemies (why????)
        for _,enemy in ipairs(target) do
            local amount = self:getBattleHealAmount(enemy.id)
            enemy:heal(amount)
        end
    else
        -- No target, do nothing
    end
end

return HealItem