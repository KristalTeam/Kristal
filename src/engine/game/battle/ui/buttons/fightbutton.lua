---@class FightButton : ActionButton
---@overload fun(...) : FightButton
local FightButton, super = Class(ActionButton)

---@param battler PartyBattler
---@param x number
---@param y number
function FightButton:init(battler, x, y)
    super.init(self, battler, x, y)
end

function FightButton:getTexture()
    return Assets.getTexture("ui/battle/btn/fight")
end

function FightButton:getHoveredTexture()
    return Assets.getTexture("ui/battle/btn/fight_h")
end

function FightButton:getSpecialTexture()
    return Assets.getTexture("ui/battle/btn/fight_a")
end

function FightButton:getDisabledTexture()
    return Assets.getTexture("ui/battle/btn/fight_d")
end

function FightButton:select()
    Game.battle:setState("ENEMYSELECT", "ATTACK")
end

return FightButton
