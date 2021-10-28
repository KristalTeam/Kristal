local Spell = Class()

function Spell:init(o)
    o = o or {}

    -- Load the table
    for k,v in pairs(o) do
        self[k] = v
    end
end

function Spell:getCastMessage(user, target)
    return "* "..user.chara.name.." cast "..self.name:upper().."!"
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