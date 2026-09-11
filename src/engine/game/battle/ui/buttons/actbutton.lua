---@class ActButton : ActionButton
---@overload fun(...) : ActButton
local ActButton, super = Class(ActionButton)

---@param battler PartyBattler
---@param x number
---@param y number
function ActButton:init(battler, x, y)
    super.init(self, battler, x, y)
end

function ActButton:getTexture()
    return Assets.getTexture("ui/battle/btn/act")
end

function ActButton:getHoveredTexture()
    return Assets.getTexture("ui/battle/btn/act_h")
end

function ActButton:getSpecialTexture()
    return Assets.getTexture("ui/battle/btn/act_a")
end

function ActButton:getDisabledTexture()
    return Assets.getTexture("ui/battle/btn/act_d")
end

function ActButton:select()
    Game.battle:setState("ENEMYSELECT", "ACT")
end

return ActButton
