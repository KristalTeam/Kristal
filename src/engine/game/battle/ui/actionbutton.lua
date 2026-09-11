--- An ActionButton is a button you can select in battles.
---
--- If you make a subclass of this, consider registering it through `Game.battle:registerActionButton`.
---@class ActionButton : Object
---
---@field battler PartyBattler # The party member this button belongs to.
---@field disabled boolean # Whether or not this button is disabled (gray and unselectable).
---@field hovered boolean # Whether or not this button is currently being hovered
---
---@overload fun(...) : ActionButton
local ActionButton, super = Class(Object)

---@param battler PartyBattler
---@param x number
---@param y number
function ActionButton:init(battler, x, y)
    super.init(self, x, y, 31, 32)

    self.battler = battler

    self:setOrigin(0.5, 13 / 32)

    self.hovered = false
    self.disabled = false
end

--- Sets the PartyBattler this button belongs to.
---
---@param battler PartyBattler
function ActionButton:setPartyBattler(battler)
    self.battler = battler
end

--- *(Override)* The button's normal texture.
---@return love.Image
function ActionButton:getTexture()
    return Assets.getTexture("ui/battle/btn/fight")
end

--- *(Override)* The texture to use when the button is currently "hovered" (the player is over it, but hasn't selected it yet)
---@return love.Image
function ActionButton:getHoveredTexture()
    return Assets.getTexture("ui/battle/btn/fight_h")
end

--- *(Override)* The texture to use when the button is glowing.
---@return love.Image
function ActionButton:getSpecialTexture()
    return Assets.getTexture("ui/battle/btn/fight_a")
end

--- *(Override)* The texture to use when the button is disabled.
---@return love.Image
function ActionButton:getDisabledTexture()
    return Assets.getTexture("ui/battle/btn/fight_d")
end

--- *(Override)* Called when this button is selected.
function ActionButton:select()
    Logging.warnNotify("Unhandled button select!")
end

--- *(Override)* Called when this button is unselected. Most of the time, this isn't needed.
function ActionButton:unselect()
end

--- *(Override)* Whether or not this button should be glowing.
---
--- In DR, Ralsei's magic button glows when an enemy is TIRED, and the spare button glows when an enemy's mercy is 100%.
---
---@return boolean
function ActionButton:hasSpecial()
    return false
end

--- Whether or not the button belongs to the current active party member.
---@protected
---@return boolean
function ActionButton:isActive()
    return self.battler == Game.battle.party[Game.battle.current_selecting]
end

function ActionButton:draw()
    if self.disabled then
        Draw.draw(self:getDisabledTexture())
    elseif self:isActive() and self.hovered then
        Draw.draw(self:getHoveredTexture())
    else
        Draw.draw(self:getTexture())
        if self:isActive() and self:hasSpecial() then
            local r, g, b, a = self:getDrawColor()
            Draw.setColor(r, g, b, a * (0.4 + math.sin((Kristal.getTime() * 30) / 6) * 0.4))
            Draw.draw(self:getSpecialTexture())
        end
    end

    super.draw(self)
end

return ActionButton
