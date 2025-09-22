return {
    image = function (cutscene)
        cutscene:text("* Kris check it out [image:party/susie/dark/t_pose]\n[wait:5]* I'm in the textbox",
                      "surprise_smile", "susie")
        cutscene:text("* Get out of there!!!", "angrier", "ralsei")
        cutscene:text("* [wait:10][image:party/susie/dark/fell]", "smile", "susie")
        cutscene:text(
            "* Susie if you don't get out of the textbox in 5 seconds,[wait:5] then I will be forced to come in there and get you.",
            "angry", "ralsei")
        cutscene:text("* Sorry can't hear you,[wait:5] you ran out of textbox space[image:party/susie/dark/away_hand]",
                      "smile", "susie")
        cutscene:text("* I said I will come and get you out of there", "angry", "ralsei")
        cutscene:text("* Try it [image:party/susie/dark/walk_back_arm/left_1]", "smile", "susie")
        cutscene:text("* That's it!", "angry", "ralsei")
        cutscene:text("* hoooOOOOOOOOOOOOOOOOOOO\nOOAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", "angry", "ralsei", { auto = true })
        cutscene:text("[image:party/ralsei/dark/walk/down_1]", nil, "ralsei")
        cutscene:text("* You know what,[wait:5] this isn't that bad [image:party/ralsei/dark/walk/down_1]", "neutral",
                      "ralsei")
        local susie_sprite = nil
        local ralsei_sprite = nil
        cutscene:text(
            "* [image:party/susie/dark/walk/down_1, 0, 0, 2, 2][image:party/ralsei/dark/walk/down_1, 0, 0, 2, 2] Atta boy[func:grabloc]",
            "smile", "susie", {
                functions = {
                    grabloc = function (text)
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
        local wait, textbox = cutscene:text("", nil, nil, { advance = false })
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
    goner = function (cutscene)
        local text

        -- Please don't copy the goner text functions below, they're not accurate whatsoever
        local function gonerTextFade(wait)
            local this_text = text
            Game.world.timer:tween(1, this_text, { alpha = 0 }, "linear", function ()
                this_text:remove()
            end)
            if wait ~= false then
                cutscene:wait(1)
            end
        end

        -- (This one, too.)
        local function gonerText(str, advance)
            text = DialogueText("[speed:0.5][spacing:6][style:GONER][voice:none]" .. str, 160, 100, 640, 480,
                                { auto_size = true })
            text.layer = WORLD_LAYERS["top"] + 100
            text.skip_speed = true
            text.parallax_x = 0
            text.parallax_y = 0
            Game.world:addChild(text)

            if advance ~= false then
                cutscene:wait(function () return not text:isTyping() end)
                gonerTextFade(true)
            end
        end

        cutscene:fadeOut(0.5, { music = true })

        local background = GonerBackground()
        background.layer = WORLD_LAYERS["top"]
        Game.world:addChild(background)

        gonerText("FIRST.[wait:20]")

        local soul = SoulAppearance(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
        soul:setParallax(0, 0)
        soul.layer = WORLD_LAYERS["top"] + 100
        Game.world:addChild(soul)

        local soul_timer = 0
        local soul_should_move = false

        cutscene:during(function ()
            if soul_should_move then
                soul_timer = soul_timer + DTMULT
                soul.y = soul.init_y + math.sin(soul_timer / 16) * 2 * 2
            end
        end)

        cutscene:wait(20/30)
        soul_should_move = true

        cutscene:wait(4)

        gonerText("YOU MUST CREATE[wait:40]\nA VESSEL.[wait:20]")

        soul:hide()
        soul_should_move = false
        cutscene:wait(4)

        local ralsei_sprite = Sprite("party/ralsei/dark/blunt")
        ralsei_sprite.x = 320
        ralsei_sprite.y = 240
        ralsei_sprite.parallax_x = 0
        ralsei_sprite.parallax_y = 0
        ralsei_sprite:setOrigin(0.5, 0.5)
        ralsei_sprite:setScale(2)
        ralsei_sprite.layer = WORLD_LAYERS["top"] + 100
        ralsei_sprite.alpha = 0
        ralsei_sprite.graphics.fade = 0.01
        ralsei_sprite.graphics.fade_to = 1
        Game.world:addChild(ralsei_sprite)

        local ralsei_y = { 240 }
        local ralsei_mult = { 6 }

        cutscene:during(function ()
            if ralsei_sprite ~= nil then
                ralsei_sprite.y = ralsei_y[1] + math.sin(Kristal.getTime() * 2) * ralsei_mult[1]
            end
        end)

        gonerText("THIS SHOULD BE[wait:40]\nGOOD ENOUGH.[wait:20]", false)

        cutscene:wait(4)

        local chosen = nil
        local choicer = GonerChoice(220, 360, {
                                        { { "YES", 0, 0 }, { "<<" }, { ">>" }, { "NO", 160, 0 } }
                                    }, function (choice)
                                        chosen = choice
                                    end)
        choicer:setSelectedOption(2, 1)
        choicer:setSoulPosition(80, 0)
        Game.stage:addChild(choicer)

        cutscene:wait(function () return chosen ~= nil end)

        gonerTextFade()

        if chosen == "YES" then
            gonerText("EXCELLENT.[wait:20]")
            gonerText("TRULY[wait:40]\nEXCELLENT.[wait:20]")
        else
            gonerText("WHY?[wait:20]")
        end

        Game.world.timer:tween(1, ralsei_y, { 360 })

        cutscene:wait(0.75)

        gonerText("WHAT IS ITS NAME?", false)
        text.x = 136
        text.y = 40

        local ralsei_name
        local namer = GonerKeyboard(-1, "default", function (name)
                                        ralsei_name = name
                                    end, function (key, x, y, namer)
                                        if namer.text == "GASTE" and key == "R" then
                                            Game.stage.timescale = 0
                                            Game.stage.active = false
                                            Kristal.Stage.timer:after(0.1, function ()
                                                Kristal.returnToMenu()
                                            end)
                                        end
                                    end)
        Game.stage:addChild(namer)

        cutscene:wait(function () return ralsei_name ~= nil end)

        Game.world.timer:tween(1, ralsei_y, { 240 })

        gonerTextFade()

        if ralsei_name ~= "RALSEI" then
            gonerText("WRONG.[wait:40]\nYOU ARE SO[wait:40] STUPID.[wait:20]")
            gonerText(ralsei_name .. "?[wait:20]")
        else
            gonerText("BING BONG.[wait:40]\nCORRECT-O.[wait:20]")
        end
        gonerText("ITS NAME[wait:40]\nIS RALSEI.[wait:20]")

        Game.world.timer:tween(1, ralsei_y, { 240 })
        Game.world.timer:tween(1, ralsei_mult, { 0 })
        cutscene:wait(1)
        ralsei_sprite:remove()
        ralsei_sprite = nil

        local ralsoul = SoulAppearance(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
        ralsoul:setParallax(0, 0)
        ralsoul.layer = WORLD_LAYERS["top"] + 100
        ralsoul:setSprite("party/ralsei/dark/blunt")
        ralsoul.t = ralsoul.tmax
        ralsoul:setColor(1, 1, 1, 1)
        ralsoul:hide()
        Game.world:addChild(ralsoul)
    end,
    goner_choice = function (cutscene)
        cutscene:fadeOut(0.5, { music = true })
        cutscene:wait(1)

        local done = false
        local choicer = GonerChoice(220, 360, {
                                        { { "YES", 0, 0 }, { "<<" }, { ">>" }, { "NO", 160, 0 } }
                                    }, function (choice)
                                        print("Picked " .. choice)
                                        done = true
                                    end)
        choicer:setSelectedOption(2, 1)
        choicer:setSoulPosition(80, 0)
        Game.stage:addChild(choicer)

        cutscene:wait(function () return done end)

        local chosen_name
        local namer = GonerKeyboard(12, "default", function (name)
                                        print("Entered name: " .. name)
                                        chosen_name = name
                                    end, function (key, x, y, namer)
                                        if namer.text == "GASTE" and key == "R" then
                                            Game.stage.timescale = 0
                                            Game.stage.active = false
                                            Kristal.Stage.timer:after(0.1, function ()
                                                Kristal.returnToMenu()
                                            end)
                                        end
                                    end)
        Game.stage:addChild(namer)

        cutscene:wait(function () return chosen_name ~= nil end)

        cutscene:fadeIn(0.5, { music = true })
    end,
    japanese = function (cutscene)
        cutscene:text("＊ 本当にいいんですか？", "surprise_smile", "susie")
        cutscene:text("* Susie what the fuck are you talking about", "smile", "ralsei")
        cutscene:text("＊ 誰かが設定を少し変えてしまい、元に戻せません。", "surprise_smile",
                      "susie")
    end,
    ut_choicer = function (cutscene)
        local choice = cutscene:textChoicer("* Do you wanna be partners?", { "Not yet", "Yes" }, "smile", "noelle")
        if choice == 1 then
            cutscene:text("* Umm,[wait:5] OK.[wait:5]\n* You just keep doing your thing,[wait:5] Kris.", "smile_closed",
                          "noelle")
        else
            cutscene:text("* Wait,[wait:5] what're we talking about again?", "smile_closed", "noelle")
        end
    end,
    crash = function (cutscene)
        cutscene:text("What kind of cutscene crash do you want?")
        local choice = cutscene:choicer({"Deep", "Shallow"})
        if choice == 1 then
            cutscene:text(4)
        else
            assert(false)
        end
    end,
    this_is_a_test_mod = function (cutscene)
        local function centerText(str)
            local text = DialogueText(str, 0, 16, 640, 480,
                                      { align = "center" })
            text.layer = WORLD_LAYERS["top"] + 100
            text.parallax_x = 0
            text.parallax_y = 0
            Game.world:addChild(text)

            text.advance_callback = function ()
                Game.world.timer:tween(1, text, { alpha = 0 }, "linear", function ()
                    text:remove()
                end)
            end

            cutscene:wait(function () return text:isRemoved() end)
        end

        cutscene:fadeOut(0, { music = true })

        centerText(
            "Hello.[wait:10]\n\n" ..
            "This mod is the Kristal team's testing mod,[wait:5] and is not meant to be an example,[wait:5] or something to learn from.[wait:10]\n" ..
            "This is just a place for us to test things out.[wait:10]\n" ..
            "We cannot promise support for this mod,[wait:5] and we cannot promise that it will be updated.[wait:10]\n\nYou have been warned.")

        cutscene:fadeIn(1, { music = true })
    end
}
