return function(cutscene, event, player, facing)
    --event.interacted = true

    local kris = cutscene:getCharacter("kris")
    local susie = cutscene:getCharacter("susie")
    local ralsei = cutscene:getCharacter("ralsei")

    if not event.interacted then
        event.interacted = true
        cutscene:text("* These [color:yellow]bananas[color:reset] are [color:yellow]Pissing[color:reset] me\noff...")
        cutscene:text("* I'm the original   [color:yellow]Starwalker[color:reset][react:1][wait:5][react:2][wait:5][react:3][wait:5][react:sussy]", {reactions={
            {"susie", "surprise", "left", "bottom", "BottomLeft"},
            {"ralsei", "blush", "right", "top", "RightTop"},
            {"noelle", "smile", "mid", "mid", "MidMid"},
            sussy = {"susie", "surprise", "right", "bottommid", "Right BottomMid"},
        }})
        cutscene:wait(0.25)
        Assets.playSound("snd_save")
        cutscene:wait(0.5)
        Game:saveQuick(Game.world.player:getPosition())
        cutscene:text("* (The original   [color:yellow]Starwalker[color:reset]      \n   somehow saved your game...)")
    else
        Game.world.music:stop()
        cutscene:text("* [color:yellow]You[color:reset] are [color:yellow]Pissing[color:reset] me off...")
        cutscene:text("* I,[wait:5] uh,[wait:5] what?", "sus_nervous", "susie")
        cutscene:text("* Well,[wait:5] hey,[wait:5] you know\nwhat?", "annoyed", "susie")
        cutscene:text("* You piss us off too.", "smirk", "susie")
        local cutscene_music = Music()
        cutscene_music:play("s_neo")
        cutscene:detachFollowers()
        cutscene:walkTo(kris, kris.x, kris.y - 40, 1, "down", true)
        cutscene:wait(cutscene:walkTo(susie, kris.x, kris.y, 2, facing))
        cutscene:text("* If you have a problem\nwith us,[wait:5] then we have\na problem with you.", "smirk", "susie")
        cutscene:text("* Do you know what we do\nwith problems?", "smirk", "susie")
        cutscene:text("* We stomp.[wait:10] Them.[wait:10] Into.[wait:10]\nThe.[wait:10] Ground.", "smile", "susie")
        cutscene_music:stop()
        Assets.playSound("snd_boost")

        event.sprite:set("wings")

        local offset = event.sprite:getOffset()

        local flash_x = event.x - (event.actor.width / 2 + offset[1]) * 2
        local flash_y = event.y - (event.actor.height + offset[2]) * 2

        local flash = FlashFade("npcs/starwalker/starwalker_wings", flash_x, flash_y)
        flash.flash_speed = 0.5
        flash:setScale(2, 2)
        flash.layer = event.layer + 1
        event.parent:addChild(flash)

        cutscene:wait(1)
        cutscene:text("* Uh,[wait:5] what-", "surprise_frown", "susie", {auto=true})

        cutscene:startEncounter("starwalker", true, {{"starwalker", event}})

        event.sprite:resetSprite()

        cutscene:keepFollowerPositions()
        cutscene:attachFollowers()
    end
end