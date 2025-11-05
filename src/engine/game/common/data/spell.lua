--- Spells are data files that extend this `Spell` class to define a castable spell. \
--- Spells are stored in `scripts/data/spells`, and their filepath starting at this location becomes their id, unless an id for them is specified as the second argument to `Class()`.
--- Spells are learned by [`PartyMember`](lua://PartyMember.init)s, and they can be given a spell by calling [`PartyMember:addSpell()`](lua://PartyMember.addSpell) (likewise, [`PartyMember:removeSpell()`](lua://PartyMember.removeSpell) removes a spell).
---
---@class Spell : Class
---
---@field name string           The display name of the spell
---@field cast_name string?     The display name of the spell when cast (optional)
---
---@field effect string         The battle description of the spell
---@field description string    The overworld menu description of the spell
---
---@field cost number           The TP cost of the spell
---@field usable boolean        Whether the spell can be cast
---
---@field target string         The target mode of the spell - valid options are `"ally"`, `"party"`, `"enemy"`, `"enemies"`, and `"none"`
---
--- Tags that apply to this spell \
--- Tags are used to identify properties of the spell that can be checked by other pieces of code for certain effects, For example: \
--- The built in tag `spare_tired` will cause the spell to be highlighted if an enemy is TIRED
---@field tags string[]
---
---@field cast_anim string      The name of the animation set when the spell is cast - defaults to "battle/spell"
---@field select_anim string    The name of the animation set when the spell is selected - defaults to "battle/spell_ready"
---
---@overload fun(...) : Spell
local Spell = Class()

function Spell:init()
    self.name = "Test Spell"
    self.cast_name = nil

    self.effect = ""
    self.description = ""

    self.cost = 0
    self.usable = true

    self.target = "none"

    self.tags = {}
end

---@return string
function Spell:getName() return self.name end
---@return string
function Spell:getCastName() return self.cast_name or self:getName():upper() end

---@return string
function Spell:getDescription() return self.description end
---@return string
function Spell:getBattleDescription() return self.effect end

--- Gets the TP required to cast this spell
---@param chara PartyMember The `PartyMember` that is casting the spell
---@return number
function Spell:getTPCost(chara) return self.cost end
--- *(Override)* Gets whether the spell is currently castable
---@param chara PartyMember The `PartyMember` the check is being run for
---@return boolean
function Spell:isUsable(chara) return self.usable end

--- *(Override)* Gets whether the spell can be cast in the world \
--- *(Always false by default)*
---@param chara PartyMember The `PartyMember` the check is being run for
---@return boolean
function Spell:hasWorldUsage(chara) return false end

--- *(Override)* Called whenever the spell is cast in the overworld \
--- Code that controls the effect of the spell when cast in the overworld goes here
---@param chara PartyMember
function Spell:onWorldCast(chara) end

--- Checks whether the spell has a specific tag attached to it
---@param tag string
---@return boolean
function Spell:hasTag(tag)
    return TableUtils.contains(self.tags, tag)
end

--- *(Override)* Gets the message that appears when this spell is cast in battle
---@param user PartyBattler
---@param target Battler[]|EnemyBattler|PartyBattler|EnemyBattler[]|PartyBattler[]
---@return string
function Spell:getCastMessage(user, target)
    return "* "..user.chara:getName().." cast "..self:getCastName().."!"
end

--- *(Override)* Gets the animation that is set when this spell is cast in battle
--- @return string
function Spell:getCastAnimation()
    return self.cast_anim or "battle/spell"
end

--- *(Override)* Gets the animation that is set when this spell is selected in battle
--- @return string
function Spell:getSelectAnimation()
    return self.select_anim or "battle/spell_ready"
end

--- *(Override)* Called when the spell is cast \
--- The code for the effects of the spell (such as damage or healing) should go into this function
---@param user PartyBattler
---@param target Battler[]|EnemyBattler|PartyBattler|EnemyBattler[]|PartyBattler[]
---@return boolean? finish_action   Whether the spell action finishes automatically, when `false` the action can be manually ended with `Game.battle:finishActionBy(user)` (defaults to `true`) 
function Spell:onCast(user, target)
    -- Returning false here allows you to call 'Game.battle:finishActionBy(user)' yourself
end

--- Called at the start of a spell cast, manages internal functionality \
--- Don't use this function for spell effects - see [`Spell:onCast()`](lua://Spell.onCast) instead
---@param user PartyBattler
---@param target Battler[]|EnemyBattler|PartyBattler|EnemyBattler[]|PartyBattler[]
function Spell:onStart(user, target)
    Game.battle:battleText(self:getCastMessage(user, target))
    user:setAnimation(self:getCastAnimation(), function()
        Game.battle:clearActionIcon(user)
        local result = self:onCast(user, target)
        if result or result == nil then
            Game.battle:finishActionBy(user)
        end
    end)
end

--- *(Override)* Called whenever the spell is selected for use in battle
---@param user PartyBattler
---@param target Battler[]|EnemyBattler|PartyBattler|EnemyBattler[]|PartyBattler[]
function Spell:onSelect(user, target) end
--- *(Override)* Called whenever the spell use is undone in battle
---@param user PartyBattler
---@param target Battler[]|EnemyBattler|PartyBattler|EnemyBattler[]|PartyBattler[]
function Spell:onDeselect(user, target) end

return Spell
