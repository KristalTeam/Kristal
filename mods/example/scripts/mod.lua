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
        end
    end
end