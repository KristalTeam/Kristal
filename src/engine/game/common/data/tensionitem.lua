---@class TensionItem : Item
---@overload fun(...) : TensionItem
local TensionItem, super = Class(Item)

function TensionItem:init()
    super.init(self)

    -- Amount of TP this item gives
    self.tp_amount = 0
end

function TensionItem:getTensionAmount()
    return self.tp_amount
end

function TensionItem:onBattleSelect(user, target)
    self.tension_given = Game:giveTension(self:getTensionAmount())

    user:flash()

    local sound = Assets.newSound("cardrive")
    sound:setPitch(1.4)
    sound:setVolume(0.8)
    sound:play()

    user:sparkle(1, 0.625, 0.25)
end

function TensionItem:onBattleDeselect(user, target)
    Game:removeTension(self.tension_given or 0)
end

function TensionItem:onWorldUse(target)
    Game.world:showText({
        "* (You felt tense.)",
        "* (... try using it in battle.)"
    })
    return false
end

return TensionItem