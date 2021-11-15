return function(cutscene)

    local kris = cutscene:getCharacter("kris")
    local susie = cutscene:getCharacter("susie")
    local ralsei = cutscene:getCharacter("ralsei")

    if ralsei then
        cutscene:text("* The power of [color:pink]test\ndialogue[color:reset] shines within\nyou.", "starwalker")
        cutscene:wait(0.5)
        cutscene:text("* Oh    [color:red]Fuck[color:reset]   it's a  bomb")

        cutscene:detachCamera()
        cutscene:detachFollowers()

        cutscene:setSprite(ralsei, "up", 1/15)
        cutscene:setSpeaker("ralsei")
        cutscene:text("* Kris, Susie, look out!!!", "face_23")

        susie.sprite:set("shock_r")
        --Cutscene.setSprite(susie, "world/dark/shock_r")
        cutscene:wait(cutscene:slideTo(ralsei, susie.x, susie.y, 12))
        cutscene:slideTo(susie, susie.x - 40, susie.y, 8)
        cutscene:wait(cutscene:slideTo(ralsei, kris.x, kris.y, 12))
        cutscene:look(kris, "right")
        cutscene:wait(cutscene:slideTo(kris, kris.x - 40, kris.y, 8))
        ralsei:explode()
        cutscene:shakeCamera(8)

        cutscene:wait(2)
        cutscene:text("* Yo what the fuck", "face_15", "susie")

        cutscene:wait(2)
        cutscene:setSprite(susie, "")
        cutscene:look(susie, "right")
        cutscene:text("* Did Ralsei just, uh...", "face_15", "susie")
        cutscene:look(susie, "up")
        cutscene:text("* Explode...?", "face_16", "susie")

        local choice = 1
        local wait = cutscene:choicer({"Yes", "No"}, {wait = false})
        local timer = 0
        while timer < 0.75 do
            local chosen, chosen_n = wait(cutscene)
            if chosen then
                choice = chosen_n
                break
            end
            timer = timer + DT
            cutscene:wait()
        end

        cutscene:text("* THAT WAS A RHETORICAL\nQUESTION!", "face_17", "susie")

        cutscene:alignFollowers("up")

        if choice == 2 then
            ralsei = Game.world:spawnFollower("ralsei", 680, 300)
            ralsei.following = false

            local walk_wait = cutscene:walkTo(ralsei, 160, 300, 12)
            cutscene:wait(0.5)
            cutscene:look(susie, "right")

            cutscene:wait(walk_wait)
            cutscene:text("* bY9BasRADAS/0i8wS14RApt\nLXqBoZI/AI5kZZcG/X9m++J\nBr06pSP6mrQwcIs3KoG63gS\np04pIO7UEjB744v2shkCF5axLFQExQZulj2fqou0v/w1J2ah0/4lIMaVRAaq9yYPp/xZb7B5k7GVdNAVs5Ko8Eex8F/cvaW4Y5vtRAr6byQlXLNtgn1fFwN/krpx+Nxux0YaixI2zUxd09v", "face_30", "ralsei", {auto = true})

            local x, y = ralsei:getTargetPosition()
            cutscene:wait(cutscene:walkTo(ralsei, x, y, 12, "up"))
            cutscene:wait(1)

            cutscene:text("* Okay", "face_7", "susie")
        end

        cutscene:attachFollowers()
        cutscene:attachCamera()
    else
        cutscene:text("", "face_15", "susie")
    end

end