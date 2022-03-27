local spell = Spell{
    -- Spell ID (optional, defaults to path)
    id = "sleep_mist",
    -- Display name
    name = "Sleep Mist",

    -- Battle description
    effect = "Spare\nTIRED foes",
    -- Menu description
    description = "A cold mist sweeps through,\nsparing all TIRED enemies.",

    -- TP cost
    cost = 32,

    -- Target mode (party, enemy, or none/nil)
    target = "none",

    -- Tags that apply to this spell
    tags = {"spare_tired"},
}

function spell:onCast(user, target)
    local count = 0
    for _,enemy in ipairs(Game.battle:getActiveEnemies()) do
        local success = enemy.tired

        if success then
            enemy.done_state = "PACIFIED"
        end

        local parent = enemy.parent
        Game.battle.timer:after(10/30 * count, function()
            Assets.playSound("snd_ghostappear")
            if success then
                Assets.playSound("snd_spell_pacify")
            end

            local x, y = enemy:getRelativePos(enemy.width/2, enemy.height/2)

            local effect = SleepMistEffect(x, y, success)
            effect.layer = enemy.layer + 0.1
            parent:addChild(effect)

            if success then
                local w, h = 150, 100
                Game.battle.timer:every(3/30, function()
                    local snowflake = IceSpellEffect(x - (w/2) + Utils.random(w), y - (h/2) + Utils.random(h))
                    snowflake:setScale(0.5)
                    snowflake.rotation_speed = Utils.random(5)
                    snowflake.layer = enemy.layer + 0.02
                    parent:addChild(snowflake)
                end, 8)

                Game.battle.timer:after(12/30, function()
                    enemy:spare(true)
                end)
            end
        end)

        count = count + 1
    end
end

return spell