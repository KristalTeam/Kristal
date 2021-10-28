local Spell = Class()

function Spell:init(o)
    o = o or {}

    -- Load the table
    for k,v in pairs(o) do
        self[k] = v
    end
end

function Spell:onStart(user, target)
    user:setAnimation("battle/spell")
    Game.battle:battleText("* "..user.chara.name.." cast "..self.name:upper().."!")
end

function Spell:onCast(user, target)
    Game.battle:finishSpell()
end

function Spell:onFinish(user, target)
    --user:setAnimation("battle/idle")
    Game.battle:processCharacterActions()
end

return Spell