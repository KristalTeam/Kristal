return {
    image = function(cutscene)
        cutscene:text("* Kris check it out [image:party/susie/dark/t_pose]\n[wait:5]* I'm in the textbox", "surprise_smile", "susie")
        cutscene:text("* Get out of there!!!", "angrier", "ralsei")
        cutscene:text("* [wait:10][image:party/susie/dark/fell]", "smile", "susie")
        cutscene:text("* Susie if you don't get out of the textbox in 5 seconds,[wait:5] then I will be forced to come in there and get you.", "angry", "ralsei")
        cutscene:text("* Sorry can't hear you,[wait:5] you ran out of textbox space[image:party/susie/dark/away_hand]", "smile", "susie")
        cutscene:text("* I said I will come and get you out of there", "angry", "ralsei")
        cutscene:text("* Try it [image:party/susie/dark/walk_back_arm/left_1]", "smile", "susie")
        cutscene:text("* That's it!", "angry", "ralsei")
        cutscene:text("* hoooOOOOOOOOOOOOOOOOOOO\nOOAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", "angry", "ralsei", {auto=true})
        cutscene:text("[image:party/ralsei/dark/walk/down_1]", nil, "ralsei")
        cutscene:text("* You know what,[wait:5] this isn't that bad [image:party/ralsei/dark/walk/down_1]", "neutral", "ralsei")
        local susie_sprite = nil
        local ralsei_sprite = nil
        cutscene:text("* [image:party/susie/dark/walk/down_1, 0, 0, 2, 2][image:party/ralsei/dark/walk/down_1, 0, 0, 2, 2] Atta boy[func:grabloc]", "smile", "susie", {
            functions = {
                grabloc = function(text)
                    local sprites = text.sprites
                    susie_sprite = Sprite("party/susie/dark/walk/down_1", sprites[1]:getScreenPos())
                    susie_sprite:setOrigin(0, 0.5)
                    susie_sprite:setScale(2, 2)
                    ralsei_sprite = Sprite("party/ralsei/dark/walk/down_1", sprites[2]:getScreenPos())
                    ralsei_sprite:setOrigin(0, 0.5)
                    ralsei_sprite:setScale(2, 2)
                    susie_sprite.layer = WORLD_LAYERS["textbox"] + 100
                    ralsei_sprite.layer = WORLD_LAYERS["textbox"] + 100
                    susie_sprite:setParallax(0, 0)
                    ralsei_sprite:setParallax(0, 0)
                    susie_sprite.visible = false
                    ralsei_sprite.visible = false
                    Game.world:addChild(susie_sprite)
                    Game.world:addChild(ralsei_sprite)
                end
            }
        })
        susie_sprite.visible = true
        ralsei_sprite.visible = true
        local wait, textbox = cutscene:text("", nil, nil, {advance = false})
        susie_sprite.x = susie_sprite.x + susie_sprite.width
        susie_sprite:setSprite("party/susie/dark/playful_punch_1")
        susie_sprite.x = susie_sprite.x + susie_sprite.width
        susie_sprite:setScale(-2, 2)
        cutscene:wait(0.5)
        susie_sprite:setSprite("party/susie/dark/playful_punch_2")
        Assets.playSound("impact")
        ralsei_sprite:setSprite("party/ralsei/dark/splat")
        ralsei_sprite.physics.direction = math.rad(10)
        ralsei_sprite.physics.speed = 24
        ralsei_sprite.physics.friction = 1.5
        cutscene:wait(0.5)
        local explosion = ralsei_sprite:explode(0, 0, true)
        explosion:setScale(3, 3)
        cutscene:wait(0.2)
        ralsei_sprite:remove()
        cutscene:wait(3)
        textbox:setText("[voice:susie]* Whoops", nil, "susie")
        textbox:setAdvance(true)
        cutscene:wait(wait)
        susie_sprite:remove()
    end,
}