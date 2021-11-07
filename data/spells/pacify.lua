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
    else
        local old_color = Utils.copy(target.sprite.color)
        Game.battle.timer:during(8/30, function()
            target.sprite.color = Utils.lerp(target.sprite.color, {0, 0, 1}, 0.12 * DTMULT)
        end, function()
            Game.battle.timer:during(8/30, function()
                target.sprite.color = Utils.lerp(target.sprite.color, old_color, 0.16 * DTMULT)
            end, function()
                target.sprite.color = old_color
            end)
        end)
    end
end

return spell