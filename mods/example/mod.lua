function Mod:init()
    print("Loaded example mod!")

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
end

function Mod:onKeyPressed(key)
    if not Game.lock_input then
        if key == "b" and Game.state == "OVERWORLD" then
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
                player:setSprite(player.actor.battle.attack)
                player:play(1/15, false, function()
                    player:setSprite(player.actor.default)
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