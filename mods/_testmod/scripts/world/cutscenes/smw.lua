return function(cutscene)
    local kris = cutscene:getCharacter("kris")
    local susie = cutscene:getCharacter("susie")
    local ralsei = cutscene:getCharacter("ralsei")

    cutscene:detachFollowers()

    cutscene:setSpeaker("susie")
    cutscene:text("* Hey, Kris...", "neutral_side")
    cutscene:wait(cutscene:walkTo(susie, kris.x + 40, susie.y, 1.5))

    susie:setSprite("playful_punch_1")
    local kris_flying = true
    cutscene:text("* Where the [wait:10][face:teeth][func:punch]FUCK[wait:10][face:smirk] are we-[wait:2]", "smirk", "susie", {
        functions = {
            punch = function()
                susie:setSprite("playful_punch_2")
                susie:shake(2,0)
                Assets.playSound("impact")

                kris.flip_x = true
                kris:setSprite("ball")
                kris:play(1/15, true)
                kris.noclip = true

                local tx, ty = kris.x - 128, kris.y - 128
                Game.world.timer:tween(1, kris, {x = tx}, "out-quad")
                Game.world.timer:tween(1, kris, {y = ty}, "out-cubic")
                Game.world.timer:after(1, function() kris_flying = false end)
            end,
        },
        auto = true,
    })
    susie:setSprite("shock_left")
    cutscene:text("* Wait shit", "shock")

    cutscene:wait(function() return not kris_flying end)
    cutscene:wait(0.5)

    kris.physics.gravity = 0.3
    cutscene:wait(function() return kris.y > 400 end)
    cutscene:during(function()
        kris.cutout_bottom = (kris.y - 400)/2
    end)
    Assets.playSound("splash", 1, 0.8)
    local shadow = Game.world:spawnObject(Ellipse(kris.x + 12, 400, 32, 0))
    shadow:setColor(0.8, 1, 1, 0.5)
    Game.world.timer:tween(0.2, shadow, {height = 16})
    local line = Game.world:spawnObject(Ellipse(kris.x + 12, 400, 0, 0), kris.layer + 10)
    Game.world.timer:tween(0.1, line, {width = 48, height = 4})
    cutscene:wait(0.1)
    Game.world.timer:tween(0.1, line, {height = 0}, "linear", function()
        line:remove()
    end)
    cutscene:wait(0.9)
    Game.world.timer:tween(1, shadow, {height = 0}, "linear", function()
        shadow:remove()
    end)
    cutscene:wait(1)

    cutscene:setTextboxTop(false)
    cutscene:text("* Uhh", "shock_down")
    cutscene:text("* Sorry Kris", "shock_nervous")

    Game:removePartyMember("kris")
    kris:convertToCharacter()
    susie:convertToPlayer()
    ralsei:updateIndex()
    cutscene:interpolateFollowers()
    cutscene:alignFollowers("left")
    cutscene:wait(cutscene:attachFollowers(3))
    susie:setSprite("walk")
end