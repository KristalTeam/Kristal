function Init()
    print("Loaded example mod!")
end

function KeyPressed(key)
    if Game.world.player and not Game.lock_input then
        local player = Game.world.player
        if key == "e" then
            player:explode(0, -40)
            player = nil
            return true
        elseif key == "r" then
            local last_flipped = player.flip_x
            local facing = player.facing

            if facing == "left" or facing == "right" then
                Game.lock_input = true

                player.flip_x = facing == "left"
                player:setSprite("battle/dark/attack")
                player:play(1/15, false, true, function()
                    player:setSprite("world/dark")
                    player.flip_x = last_flipped
    
                    Game.lock_input = false
                end)
    
                local src = love.audio.newSource("assets/sounds/snd_laz_c.wav", "static")
                src:play()

                local hitbox_x, hitbox_y = 13, -4
                local hitbox_w, hitbox_h = 25, 47

                local attack_box = Hitbox((-player.sprite.width / 2 + hitbox_x) * 2, (-player.sprite.height + hitbox_y) * 2, hitbox_w * 2, hitbox_h * 2, player)

                for _,object in ipairs(Game.world.children) do
                    if object:includes(Event) and object:collidesWith(attack_box) then
                        object:explode()
                    end
                end

                return true
            end
        elseif key == "b" then
            Game.lock_input = true

            local kris = PARTY["kris"]

            local tx, ty = Game.world:screenToLocalPos(102, 125)

            player.sprite:setSprite(kris.battle_intro[1])
            player.sprite:play(1/15, true)

            Timer.every(1/30, function()
                local afterimage = AfterImage(player, 0.5)
                Game.world:addChild(afterimage)
            end, 9)
            Timer.tween(1/3, player, {x = tx, y = ty}, "linear", function()
                local src = love.audio.newSource("assets/sounds/snd_impact.wav", "static")
                src:play()
                local src2 = love.audio.newSource("assets/sounds/snd_weaponpull_fast.wav", "static")
                src2:play()

                if kris.battle_intro[2] then
                    player.sprite:setSprite(kris.battle_intro[2])
                    player.sprite:play(1/15, false)
                end

                Timer.after(0.5, function()
                    local music = love.audio.newSource("assets/music/battle.ogg", "stream")
                    music:setLooping(true)
                    music:play()

                    player.sprite:setSprite("battle/dark/idle")
                    player.sprite:play(1/5, true)
                end)
            end)
        end
    end
end