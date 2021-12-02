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
            cutscene:text("* Hey, think I can break\nthis wall?", "face_2")

            -- Move Susie up to the wall
            cutscene:walkTo(susie, event.x, event.y + 40, 4, "up")
            -- Move other party members behind Susie
            cutscene:walkTo(Game.world.player, event.x, event.y + 100, 2, "up")
            if cutscene:getCharacter("ralsei") then
                cutscene:walkTo("ralsei", event.x + 60, event.y + 100, 3, "up")
            end
            if cutscene:getCharacter("noelle") then
                cutscene:walkTo("noelle", event.x - 60, event.y + 100, 3, "up")
            end

            -- Wait 1.5 seconds
            cutscene:wait(1.5)

            -- Walk back,
            cutscene:wait(cutscene:walkTo(susie, event.x, event.y + 60, 2, "up"))
            -- and run forward!
            cutscene:wait(cutscene:walkTo(susie, event.x, event.y + 20, 8))

            -- Slam!!
            Assets.playSound("snd_impact")
            susie:shake(4)
            susie:setSprite("shock_up")

            -- Slide back a bit
            cutscene:slideTo(susie, event.x, event.y + 40, 4)
            cutscene:wait(1.5)

            -- owie
            susie:setSprite("head_hand_left")
            susie:shake(4)
            Assets.playSound("snd_wing")

            cutscene:wait(1)
            cutscene:text("* Guess not.", "face_3")

            -- Return things to normal
            susie:resetSprite()
            cutscene:attachCamera()
            cutscene:attachFollowers()
        end
    end
}