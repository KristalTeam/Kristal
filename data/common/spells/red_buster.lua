local spell = Spell{
    -- Spell ID (optional, defaults to path)
    id = "red_buster",
    -- Display name
    name = "Red Buster",

    -- Battle description
    effect = "Red\nDamage",
    -- Menu description
    description = "Deals large Red-elemental damage to\none foe. Depends on Attack & Magic.",

    -- TP cost
    cost = 60,

    -- Target mode (party, enemy, or none/nil)
    target = "enemy",
}

function spell:getCastMessage(user, target)
    return "* "..user.chara.name.." used RED BUSTER!"
end

function spell:onCast(user, target)
    local buster_finished = false
    local anim_finished = false
    local function finishAnim()
        anim_finished = true
        if buster_finished then
            Game.battle:finishAction()
        end
    end
    if not user:setAnimation("battle/rude_buster", finishAnim) then
        anim_finished = false
        user:setAnimation("battle/attack", finishAnim)
    end
    Game.battle.timer:after(10/30, function()
        Assets.playSound("snd_rudebuster_swing")
        local x, y = user:getRelativePos(user.width, user.height/2, Game.battle)
        local tx, ty = target:getRelativePos(target.width/2, target.height/2, Game.battle)
        local blast = RudeBusterBeam(true, x, y, tx, ty, function(pressed)
            local damage = math.ceil((user.chara:getStat("magic") * 6) + (user.chara:getStat("attack") * 13) - (target.defense * 6)) + 90
            if pressed then
                damage = damage + 30
                Assets.playSound("snd_scytheburst")
            end
            local flash = target:flash()
            flash.color_mask = {1, 0, 0}
            target:hurt(damage, user)
            buster_finished = true
            if anim_finished then
                Game.battle:finishAction()
            end
        end)
        blast.layer = LAYERS["above_ui"]
        Game.battle:addChild(blast)
    end)
    return false
end

return spell