---@class MagicButton : ActionButton
---@overload fun(...) : MagicButton
local MagicButton, super = Class(ActionButton)

---@param battler PartyBattler
---@param x number
---@param y number
function MagicButton:init(battler, x, y)
    super.init(self, battler, x, y)
end

function MagicButton:getTexture()
    return Assets.getTexture("ui/battle/btn/magic")
end

function MagicButton:getHoveredTexture()
    return Assets.getTexture("ui/battle/btn/magic_h")
end

function MagicButton:getSpecialTexture()
    return Assets.getTexture("ui/battle/btn/magic_a")
end

function MagicButton:getDisabledTexture()
    return Assets.getTexture("ui/battle/btn/magic_d")
end

function MagicButton:select()
    Game.battle:enterSpellMenu(self.battler)
end

function MagicButton:hasSpecial()
    if self.battler == nil then
        return
    end

    local has_tired = false
    for _, enemy in ipairs(Game.battle:getActiveEnemies()) do
        if enemy.tired then
            has_tired = true
            break
        end
    end

    if has_tired then
        local has_pacify = false
        for _, spell in ipairs(self.battler.chara:getSpells()) do
            if spell and spell:hasTag("spare_tired") then
                if spell:isUsable(self.battler.chara) and spell:getTPCost(self.battler.chara) <= Game:getTension() then
                    has_pacify = true
                    break
                end
            end
        end

        return has_pacify
    end

    return false
end

return MagicButton
