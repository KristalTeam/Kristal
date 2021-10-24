local Pacify = Class(Spell)

function Pacify:init()
    -- Spell ID (optional, defaults to path)
    self.id = "pacify"
    -- Display name
    self.name = "Pacify"

    -- Battle description
    self.effect = "Spare\nTIRED foe"
    -- Menu description
    self.description = "SPARE a tired enemy by putting them to sleep."

    -- TP cost (default tp max is 250)
    self.cost = 40

    -- Target mode (party, enemy, or none/nil)
    self.target = "enemy"

    -- How long it takes the spell to cast
    self.delay = 0.25

    -- (Optional) Suggests this spell when sparing a tired enemy
    self.pacify = true
end

function Pacify:onStart(user, target)
    user:setAnimation("battle/spell")
    if target.tired then
        Game.battle:BattleText("* "..user.chara.name.." cast PACIFY!")
    else
        Game.battle:BattleText("* "..user.chara.name.." cast PACIFY!\n[wait:0.25s]* But the enemy wasn't [color:blue]TIRED[color:reset]...")
    end
end

function Pacify:onCast(user, target)
    if target.tired then
        love.audio.newSource("assets/sounds/snd_spell_pacify.ogg", "static"):play()
    end
    Game.battle:finishSpell()
end

return Pacify