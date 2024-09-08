--- TensionItem is an extension of Item that provides additional functionality for items that restore TP in battle. \
--- This class can be extended from in an item file instead of `Item` to include this functionality in the item.
---  
---@class TensionItem : Item
---
---@field tp_amount     number  The amount of TP restored when using this item
---@field tension_given number  *(Used internally)* A record of the actual amount of TP this item added incase the tension hit maximum, so that it can be reverted correctly if the action is undone
---
---@overload fun(...) : TensionItem
local TensionItem, super = Class(Item)

function TensionItem:init()
    super.init(self)

    -- Amount of TP this item gives
    self.tp_amount = 0
end

--- Gets the amount of TP restored when using this item
---@return number
function TensionItem:getTensionAmount()
    return self.tp_amount
end

--- Modified to restore tension at the instant the item is selected and create a special effect
---@param user PartyBattler
---@param target Battler[]|PartyBattler|PartyBattler[]|EnemyBattler|EnemyBattler[]
function TensionItem:onBattleSelect(user, target)
    self.tension_given = Game:giveTension(self:getTensionAmount())

    user:flash()

    local sound = Assets.newSound("cardrive")
    sound:setPitch(1.4)
    sound:setVolume(0.8)
    sound:play()

    user:sparkle(1, 0.625, 0.25)
end

--- Modified to remove the tension gained if the player undoes this item's use
---@param user PartyBattler
---@param target Battler[]|PartyBattler|PartyBattler[]|EnemyBattler|EnemyBattler[]
function TensionItem:onBattleDeselect(user, target)
    Game:removeTension(self.tension_given or 0)
end

--- Modified to display a special message indicating the item is only usable in battle
---@param target PartyMember|PartyMember[]
---@return boolean
function TensionItem:onWorldUse(target)
    Game.world:showText({
        "* (You felt tense.)",
        "* (... try using it in battle.)"
    })
    return false
end

return TensionItem