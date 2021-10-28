local spell = Spell{
    -- Spell ID (optional, defaults to path)
    id = "pacify",
    -- Display name
    name = "Pacify",

    -- Battle description
    effect = "Spare\nTIRED foe",
    -- Menu description
    description = "SPARE a tired enemy by putting them to sleep.",

    -- TP cost (default tp max is 250)
    cost = 40,

    -- Target mode (party, enemy, or none/nil)
    target = "enemy",

    -- (Optional) Suggests this spell when sparing a tired enemy
    pacify = true,
}

function spell:onStart(user, target)
    user:setAnimation("battle/spell")
    if target.tired then
        Game.battle:battleText("* "..user.chara.name.." cast PACIFY!")
    else
        Game.battle:battleText("* "..user.chara.name.." cast PACIFY!\n[wait:0.25s]* But the enemy wasn't [color:blue]TIRED[color:reset]...")
    end
end

function spell:onCast(user, target)
    if target.tired then
        love.audio.newSource("assets/sounds/snd_spell_pacify.ogg", "static"):play()
    end
    Game.battle:finishSpell()
end

return spell