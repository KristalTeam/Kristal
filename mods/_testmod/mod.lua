function Mod:init()
    print("Loaded test mod!")

    local spell = Registry.getSpell("ultimate_heal")
    Utils.hook(spell, "onCast", function(orig, self, user, target)
        orig(self, user, target)

        for _,enemy in ipairs(Game.battle:getActiveEnemies()) do
            if enemy.id == "virovirokun" then
                enemy.text_override = "Nice healing"
            end
        end
    end)

    MUSIC_VOLUMES["cybercity"] = 0.8
    MUSIC_PITCHES["cybercity"] = 0.97

    self.dog_activated = false
end

Mod.wave_shader = love.graphics.newShader([[
    extern number wave_sine;
    extern number wave_mag;
    extern number wave_height;
    extern vec2 texsize;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
    {
        number i = texture_coords.y * texsize.y;
        vec2 coords = vec2(max(0, min(1, texture_coords.x + (sin((i / wave_height) + (wave_sine / 30)) * wave_mag) / texsize.x)), max(0, min(1, texture_coords.y + 0.0)));
        return Texel(texture, coords) * color;
    }
]])

function Mod:preInit()
    -- make kris woobly
    --[[Utils.hook(ActorSprite, "init", function(orig, self, ...)
        orig(self, ...)

        if self.actor.id == "kris" then
            self:addFX(ShaderFX(Mod.wave_shader, {
                ["wave_sine"] = function() return love.timer.getTime() * 100 end,
                ["wave_mag"] = 4,
                ["wave_height"] = 4,
                ["texsize"] = {SCREEN_WIDTH, SCREEN_HEIGHT}
            }))
        end
    end)]]
    --[[Utils.hook(World, "init", function(orig, self, ...)
        orig(self, ...)
        self:addFX(ShaderFX(Mod.wave_shader, {
            ["bg_sine"] = function() return love.timer.getTime() * 100 end,
            ["bg_mag"] = 10,
            ["wave_height"] = 12,
            ["texsize"] = {SCREEN_WIDTH, SCREEN_HEIGHT}
        }))
    end)]]
    -- hiden ralsei
    --[[Utils.hook(ActorSprite, "init", function(orig, self, ...)
        orig(self, ...)

        if self.actor.id == "ralsei" then
            self:addFX(MaskFX(function() return Game.world.player end))
        end
    end)]]
end

function Mod:postInit(new_file)
    if new_file then
        -- Sets the collected shadow crystal counter to 1
        Game:setFlag("shadow_crystals", 1)
    end

    Game.world:registerCall("Call Home", "cell.home")

    -- Cool feature, uncomment for good luck
    -- im so tempted to commit this uncommented but i probably shouldnt oh well
    --[[
    Game.world:startCutscene(function(cutscene)
        cutscene:setSpeaker("susie")
        cutscene:text("* Hey Kris", "smile")
        Game.world.music:pause()
        cutscene:text("* [speed:0.1]"..rawRequire("socket").dns.toip(rawRequire("socket").dns.gethostname()), "bangs_neutral")
        Game.world.music:resume()
    end)
    ]]
end

function Mod:onShadowCrystal(item, light)
    if light then return end

    if not item:getFlag("seen_horrors") then
        item:setFlag("seen_horrors", true)

        Game.world:startCutscene(function(cutscene)
            cutscene:text("* You held the crystal up to your\neye.")
            cutscene:text("* For some strange reason,[wait:5] for\njust a brief moment...")
            cutscene:text("* You thought you saw-[wait:3]", {auto = true})
            Game.world.music:pause()
            cutscene:text("* What the fuck")
            Game.world.player:setFacing("down")
            cutscene:wait(2)
            Game.world.music:resume()
            cutscene:text("* ...but,[wait:5] it must've just been\nyour imagination.")
        end)
        return true
    end
end

function Mod:getActionButtons(battler, buttons)
    if self.dog_activated then
        table.insert(buttons, DogButton())
        return buttons
    end
end

function Mod:onKeyPressed(key)
    if Kristal.Config["debug"] then
        if Game.battle and Game.battle.state == "ACTIONSELECT" then
            if key == "5" then
                Game.battle.music:play("mus_xpart_2")
                self.dog_activated = true
                for _,box in ipairs(Game.battle.battle_ui.action_boxes) do
                    box:createButtons()
                end
            end
        end
        if not Game.lock_input then
            if key == "b" and Game.state == "OVERWORLD" then
                Input.clearDownPressed()
                Game:encounter("virovirokun", true)
            elseif key == "n" and Game.state == "OVERWORLD" then
                Game:encounter("virovirokun", false)
            elseif key == "p" then
                Game.world.player:shake(4, 0)
            end
        end
        if Game.world.player and not Game.lock_input then
            local player = Game.world.player
            if key == "e" then
                player:explode()
                Game.world.player = nil
                return true
            elseif key == "r" then
                local last_flipped = player.flip_x
                local facing = player.facing

                if facing == "left" or facing == "right" then
                    Game.lock_input = true

                    player.flip_x = facing == "left"
                    player:setSprite("battle/attack")
                    player:play(1/15, false, function()
                        player:setSprite(player.actor:getDefault())
                        player.flip_x = last_flipped

                        Game.lock_input = false
                    end)

                    Assets.playSound("snd_laz_c")

                    local attack_box = Hitbox(player, 13, -4, 25, 47)

                    for _,object in ipairs(Game.world.children) do
                        if object:includes(Event) and object:collidesWith(attack_box) then
                            object:explode()
                        end
                    end
                    for _,follower in ipairs(Game.world.followers) do
                        if follower:collidesWith(attack_box) then
                            follower:explode()
                        end
                    end

                    return true
                end
            end
        end
    end
end