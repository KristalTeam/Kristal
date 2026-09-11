---@class DefendButton : ActionButton
---@overload fun(...) : DefendButton
local DefendButton, super = Class(ActionButton)

---@param battler PartyBattler
---@param x number
---@param y number
function DefendButton:init(battler, x, y)
    super.init(self, battler, x, y)
end

function DefendButton:getTexture()
    return Assets.getTexture("ui/battle/btn/defend")
end

function DefendButton:getHoveredTexture()
    return Assets.getTexture("ui/battle/btn/defend_h")
end

function DefendButton:getSpecialTexture()
    return Assets.getTexture("ui/battle/btn/defend_a")
end

function DefendButton:getDisabledTexture()
    return Assets.getTexture("ui/battle/btn/defend_d")
end

function DefendButton:select()
    Game.battle:pushAction("DEFEND", nil, { tp = -Game.battle:getDefendTension(self.battler) })
end

return DefendButton
