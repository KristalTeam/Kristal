---@class SpareButton : ActionButton
---@overload fun(...) : SpareButton
local SpareButton, super = Class(ActionButton)

---@param battler PartyBattler
---@param x number
---@param y number
function SpareButton:init(battler, x, y)
    super.init(self, battler, x, y)
end

function SpareButton:getTexture()
    return Assets.getTexture("ui/battle/btn/spare")
end

function SpareButton:getHoveredTexture()
    return Assets.getTexture("ui/battle/btn/spare_h")
end

function SpareButton:getSpecialTexture()
    return Assets.getTexture("ui/battle/btn/spare_a")
end

function SpareButton:getDisabledTexture()
    return Assets.getTexture("ui/battle/btn/spare_d")
end

function SpareButton:hasSpecial()
    for _, enemy in ipairs(Game.battle:getActiveEnemies()) do
        if enemy.mercy >= 100 then
            return true
        end
    end

    return false
end

function SpareButton:select()
    Game.battle:setState("ENEMYSELECT", "SPARE")
end

return SpareButton
