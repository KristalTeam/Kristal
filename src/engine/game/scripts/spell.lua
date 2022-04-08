local Spell = Class()

function Spell:init()
    -- Display name
    self.name = "Test Spell"

    -- Battle description
    self.effect = ""
    -- Menu description
    self.description = ""

    -- TP cost
    self.cost = 0

    -- Target mode (party, enemy, or none/nil)
    self.target = nil

    -- Tags that apply to this spell
    self.tags = {}
end

function Spell:getCastMessage(user, target)
    return "* "..user.chara.name.." cast "..self.name:upper().."!"
end

function Spell:hasTag(tag)
    return Utils.containsValue(self.tags, tag)
end

function Spell:onCast(user, target)
    -- Returning false here allows you to call 'Game.battle:finishActionBy(user)' yourself
end

function Spell:onStart(user, target)
    Game.battle:battleText(self:getCastMessage(user, target))
    user:setAnimation("battle/spell", function()
        local result = self:onCast(user, target)
        if result or result == nil then
            Game.battle:finishActionBy(user)
        end
    end)
end

return Spell