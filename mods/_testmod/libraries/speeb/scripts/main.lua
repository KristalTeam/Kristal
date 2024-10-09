local lib = {}

local msg_suffix = libRequire("speeb", "reqtest")

function lib:init()
    print("Loaded speeb library"..msg_suffix)

    Utils.hook(Player, "update", function(orig, self)

        if Input.down("superfast") then
            self.walk_speed = 16
            self.run_timer = 999
        end

        if self.run_timer > 60 then
            self.walk_speed = self.walk_speed + DT
        elseif self.walk_speed > 4 then
            self.walk_speed = 4
        end

        orig(self)

        if self.last_collided_x or self.last_collided_y then
            if self.walk_speed >= 16 then
                self:explode()
                Game.world.music:stop()

                Game.stage.timer:after(2, function()
                    local rect = Rectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
                    rect:setColor(0, 0, 0)
                    rect:setLayer(100000)
                    rect.alpha = 0
                    Game.stage:addChild(rect)

                    Game.stage.timer:tween(2, rect, {alpha = 1}, "linear", function()
                        rect:remove()
                        Game:gameOver(0, 0)
                        Game.gameover.soul:remove()
                        Game.gameover.soul = nil
                        Game.gameover.screenshot = nil
                        Game.gameover.timer = 150
                        Game.gameover.current_stage = 4
                    end)
                end)
            elseif self.walk_speed >= 10 then
                Game.world:hurtParty(20)
            end
        end
    end)
end

--[[function lib:onFootstep(chara, num)
    if chara:includes(Player) and love.math.random() < 0.01 then
        chara:explode()
        Game.world.music:stop()
    end
end]]

return lib