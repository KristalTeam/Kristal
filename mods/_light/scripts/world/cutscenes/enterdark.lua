return function(cutscene)

    local kris = cutscene:getCharacter("kris_lw")
    local susie = cutscene:getCharacter("susie_lw")

    cutscene:detachCamera()
    cutscene:detachFollowers()

    cutscene:slideTo(kris,  620 - 30, 280, 0.25)
    cutscene:slideTo(susie, 620 + 30, 280, 0.25)
    cutscene:panTo(620, 245, 0.25)
    cutscene:wait(0.25)

    kris.visible = false
    susie.visible = false

    local transition = DarkTransition(280)
    transition.layer = 99999

    Game.world:addChild(transition)

    local waiting = true
    local endData = nil
    transition.end_callback = function(transition, data)
        waiting = false
        endData = data
    end

    cutscene:wait(function() return not waiting end)

    for _, character in ipairs(endData) do
        local char = Game.world:getPartyCharacter(character.party)
        local kx, ky = character.sprite_1:localToScreenPos(character.sprite_1.width / 2, 0)
        char:setScreenPos(kx, transition.final_y)
        char.visible = true
        char:setFacing("down")
    end

    cutscene:interpolateFollowers()

    cutscene:attachCamera()
    cutscene:attachFollowers()
end