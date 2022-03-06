return {
    wall = function(cutscene, event)
        -- Open textbox and wait for completion
        cutscene:text("* The wall seems cracked.")

        -- If we have Susie, play a cutscene
        local susie = cutscene:getCharacter("susie")
        if susie then
            -- Detach camera and followers (since characters will be moved)
            cutscene:detachCamera()
            cutscene:detachFollowers()

            -- All text from now is spoken by Susie
            cutscene:setSpeaker(susie)
            cutscene:text("* Hey, think I can break\nthis wall?", "smile")

            -- Get the bottom-center of the broken wall
            local x = event.x + event.width/2
            local y = event.y + event.height/2

            -- Move Susie up to the wall
            cutscene:walkTo(susie, x, y + 40, 4, "up")
            -- Move other party members behind Susie
            cutscene:walkTo(Game.world.player, x, y + 100, 2, "up")
            if cutscene:getCharacter("ralsei") then
                cutscene:walkTo("ralsei", x + 60, y + 100, 3, "up")
            end
            if cutscene:getCharacter("noelle") then
                cutscene:walkTo("noelle", x - 60, y + 100, 3, "up")
            end

            -- Wait 1.5 seconds
            cutscene:wait(1.5)

            -- Walk back,
            cutscene:wait(cutscene:walkTo(susie, x, y + 60, 2, "up"))
            -- and run forward!
            cutscene:wait(cutscene:walkTo(susie, x, y + 20, 8))

            -- Slam!!
            Assets.playSound("snd_impact")
            susie:shake(4)
            susie:setSprite("shock_up")

            -- Slide back a bit
            cutscene:slideTo(susie, x, y + 40, 4)
            cutscene:wait(1.5)

            -- owie
            susie:setSprite("head_hand_left")
            susie:shake(4)
            Assets.playSound("snd_wing")

            cutscene:wait(1)
            cutscene:text("* Guess not.", "nervous")

            -- Return things to normal
            susie:resetSprite()
            cutscene:attachCamera()
            cutscene:attachFollowers()
        end
    end
}