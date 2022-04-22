return function(cutscene)

    local kris = cutscene:getCharacter("kris_lw")
    local susie = cutscene:getCharacter("susie_lw")

    cutscene:detachCamera()
    cutscene:detachFollowers()

    cutscene:slideTo(kris,  620 - 30, 280, 8)
    cutscene:slideTo(susie, 620 + 30, 280, 8)
    cutscene:panTo(620, 245, 0.4)
    cutscene:wait(5/30)

    kris.visible = false
    susie.visible = false

    local kris_x,  kris_y  = kris :localToScreenPos(0, 0)
    local susie_x, susie_y = susie:localToScreenPos(0, 0)

    local transition = DarkTransition(280, {skiprunback = false})
    transition.layer = 99999

    transition.kris_x = kris_x / 2
    transition.kris_y = kris_y / 2
    transition.susie_x = susie_x / 2
    transition.susie_y = susie_y / 2

    Game.world:addChild(transition)

    local waiting = true
    transition.end_callback = function()
        waiting = false
    end

    local wait_func = function() return not waiting end
    cutscene:wait(wait_func)

    local kx, ky = transition.kris_sprite:localToScreenPos(transition.kris_width / 2, 0)
    -- Hardcoded offsets for now...
    Game.world.player:setScreenPos(kx - 2, transition.final_y - 2)
    Game.world.player.visible = true
    Game.world.player:setFacing("down")

    if not transition.kris_only and Game.world.followers[1] then
        local sx, sy = transition.susie_sprite:localToScreenPos(transition.susie_width / 2, 0)
        Game.world.followers[1]:setScreenPos(sx - 2, transition.final_y - 2)
        Game.world.followers[1].visible = true
        Game.world.followers[1]:interpolateHistory()
        Game.world.followers[1]:setFacing("down")
    end
    cutscene:attachCamera()
    cutscene:attachFollowers()
    Game.world.followers[1]:setFacing("down")

    --Gamestate.switch(Kristal.States["DarkTransition"], "map", {
    --    kris_x  = kris_x/2,
    --    kris_y  = kris_y/2,
    --    susie_x = susie_x/2,
    --    susie_y = susie_y/2
    --})
end