local Spell = Class()

function Spell:init()
    -- Spell ID (optional, defaults to path)
    self.id = "nothing"
    -- Display name
    self.name = "Nothing"

    -- Battle description
    self.effect = "Do\nNothing"
    -- Menu description
    self.description = "Empty spell; does nothing."

    -- TP cost (default tp max is 250)
    self.cost = 40

    -- Target mode (party, enemy, or none/nil)
    self.target = "none"

    -- How long it takes the spell to cast
    self.delay = 0.25

    -- (Optional) Suggests this spell when sparing a tired enemy
    self.pacify = false
end

function Spell:onStart(user, target)
    user:setAnimation("battle/spell")
    Game.battle:BattleText("* "..user.chara.name.." cast "..self.name:upper().."!")
end

function Spell:onCast(user, target)
    Game.battle:finishSpell()
end

function Spell:onFinish(user, target)
    --user:setAnimation("battle/idle")
    Game.battle:processCharacterActions()
end

return Spell