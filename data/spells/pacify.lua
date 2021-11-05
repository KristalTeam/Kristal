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

function spell:getCastMessage(user, target)
    if target.tired then
        return "* "..user.chara.name.." cast PACIFY!"
    else
        return "* "..user.chara.name.." cast PACIFY!\n[wait:0.25s]* But the enemy wasn't [color:blue]TIRED[color:reset]..."
    end
end

function spell:onCast(user, target)
    if target.tired then
        Assets.playSound("snd_spell_pacify")
    end
end

return spell