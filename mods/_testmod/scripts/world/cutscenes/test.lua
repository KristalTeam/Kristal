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

        cutscene:setSprite(ralsei, "walk/up", 1/15)
        cutscene:setSpeaker("ralsei")
        if kris then
            cutscene:text("* Kris,[wait:5] Susie,[wait:5] look out!!!", "owo")
        else
            cutscene:text("* Susie,[wait:5] look out!!!", "owo")
        end

        susie.sprite:set("shock_right")
        --Cutscene.setSprite(susie, "world/dark/shock_r")
        if kris then
            cutscene:wait(cutscene:slideTo(ralsei, susie.x, susie.y, 0.1))
            cutscene:slideTo(susie, susie.x - 40, susie.y, 0.1)
            cutscene:wait(cutscene:slideTo(ralsei, kris.x, kris.y, 0.1))
            cutscene:look(kris, "right")
            cutscene:wait(cutscene:slideTo(kris, kris.x - 40, kris.y, 0.1))
        else
            cutscene:wait(cutscene:slideTo(ralsei, susie.x, susie.y, 0.1))
            cutscene:slideTo(susie, susie.x - 40, susie.y, 0.1)
        end
        ralsei:explode()
        cutscene:shakeCamera(8)

        cutscene:wait(2)
        cutscene:text("* Yo what the fuck", "shock", "susie")

        cutscene:wait(2)
        cutscene:setSprite(susie, "walk")

        local choice = 1
        if kris then
            cutscene:look(susie, "right")
            cutscene:text("* Did Ralsei just,[wait:5] uh...", "shock", "susie")
            cutscene:look(susie, "up")
            cutscene:text("* Explode...?", "shock_nervous", "susie")
            
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

            cutscene:text("* THAT WAS A RHETORICAL\nQUESTION!", "teeth_b", "susie")
        end

        if choice == 2 then
            ralsei = cutscene:spawnNPC("ralsei", 680, 300)
            ralsei.following = false

            local walk_wait = cutscene:walkTo(ralsei, 160, 300, 1)
            cutscene:wait(0.5)
            cutscene:look(susie, "right")

            cutscene:wait(walk_wait)
            cutscene:text("* bY9BasRADAS/0i8wS14RApt\nLXqBoZI/AI5kZZcG/X9m++J\nBr06pSP6mrQwcIs3KoG63gS\np04pIO7UEjB744v2shkCF5axLFQExQZulj2fqou0v/w1J2ah0/4lIMaVRAaq9yYPp/xZb7B5k7GVdNAVs5Ko8Eex8F/cvaW4Y5vtRAr6byQlXLNtgn1fFwN/krpx+Nxux0YaixI2zUxd09v", "shock_smile", "ralsei", {auto = true})

            cutscene:wait(1)
            cutscene:text("* Okay", "surprise_smile", "susie")

            ralsei = ralsei:convertToPlayer()
            kris = kris:convertToFollower(1)

            Game:movePartyMember("ralsei", 1)

            cutscene:alignFollowers("left")
        else
            Game:removePartyMember("ralsei")
            cutscene:alignFollowers("up")
        end

        local chasers = Game.stage:getObjects(ChaserEnemy)
        if #chasers > 0 then
            cutscene:startEncounter(chasers[1].encounter, true, chasers[1])
            cutscene:text("That sucked", "sincere_smile", "susie")
        end

        cutscene:attachFollowers()
        cutscene:attachCamera()
    else
        cutscene:text("", "shock", "susie")
    end

end