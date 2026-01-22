--- HealItem is an extension of Item that provides additional functionality for items that perform healing when used. \
--- This class can be extended from in an item file instead of `Item` to include this functionality in the item.
--- 
---@class HealItem : Item
---
---@field heal_amount           integer
---
---@field world_heal_amount     integer
---@field battle_heal_amount    integer
---
---@field heal_amounts          table<string, integer>
---
---@field world_heal_amounts    table<string, integer>
---@field battle_heal_amounts   table<string, integer>
---
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

--- Gets the amount of HP this item should restore for a specific character
---@param id string The id of the character to get the HP amount for
---@return integer
function HealItem:getHealAmount(id)
    return self.heal_amounts[id] or self.heal_amount
end

--- Gets the amount of HP this item should restore for a specific character when used in the world
---@param id string The id of the character to get the HP amount for
---@return integer
function HealItem:getWorldHealAmount(id)
    return self.world_heal_amounts[id] or self.world_heal_amount or self:getHealAmount(id)
end

--- Gets the amount of HP this item should restore for a specific character when used in battle
---@param id string The id of the character to get the HP amount for
---@return integer
function HealItem:getBattleHealAmount(id)
    return self.battle_heal_amounts[id] or self.battle_heal_amount or self:getHealAmount(id)
end

--- Applies `Battle:applyHealBonuses()` to the battle heal amount. Can be overriden to disable or change behaviour.
---@param id string             The id of the character to get the HP amount for
---@param healer PartyMember    The party member performing the heal action
function HealItem:getBattleHealAmountModified(id, healer)
    local amount = self:getBattleHealAmount(id)
    return Game.battle:applyHealBonuses(amount, healer)
end

--- Modified to perform healing based on the set healing amounts
---@param target PartyMember|PartyMember[]
---@return boolean
function HealItem:onWorldUse(target)
    if self:getTarget() == "ally" then
        -- Heal single party member
        local amount = self:getWorldHealAmount(target.id)
        Game.world:heal(target, amount)
        return true
    elseif self:getTarget() == "party" then
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

--- Modified to perform healing based on the set healing amounts
---@param user PartyBattler
---@param target Battler[]|PartyBattler|PartyBattler[]|EnemyBattler|EnemyBattler[]
function HealItem:onBattleUse(user, target)
    if self:getTarget() == "ally" then
        -- Heal single party member
        local amount = self:getBattleHealAmountModified(target.chara.id, user.chara)
        target:heal(amount)
    elseif self:getTarget() == "party" then
        -- Heal all party members
        for _,battler in ipairs(target) do
            local amount = self:getBattleHealAmountModified(battler.chara.id, user.chara)
            battler:heal(amount)
        end
    elseif self:getTarget() == "enemy" then
        -- Heal single enemy (why)
        local amount = self:getBattleHealAmountModified(target.id, user.chara)
        target:heal(amount)
    elseif self:getTarget() == "enemies" then
        -- Heal all enemies (why????)
        for _,enemy in ipairs(target) do
            local amount = self:getBattleHealAmountModified(enemy.id, user.chara)
            enemy:heal(amount)
        end
    else
        -- No target, do nothing
    end
end

return HealItem