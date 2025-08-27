local Player, super = HookSystem.hookScript(Player)

function Player:init(...)
    super.init(self, ...)
end

function Player:getCurrentSpeed(running)
    local speed = super.getCurrentSpeed(self, running)

    if Input.down("superfast") then
        self.run_timer = 999
        return 32
    end

    if self.run_timer > 60 then
        return speed + (self.run_timer - 60) / 10
    end
    return speed
end

function Player:update()
    local speed = self:getCurrentSpeed(true)

    super.update(self)

    if self.last_collided_x or self.last_collided_y then
        if speed >= 20 then
            self:explode()
            Game.world.music:stop()

            Game.stage.timer:after(2, function()
                Game.fader:transition(
                    function()
                        Game:gameOver(0, 0)
                        Game.gameover.soul:remove()
                        Game.gameover.soul = nil
                        Game.gameover.screenshot = nil
                        Game.gameover.timer = 150
                        Game.gameover.current_stage = 4
                    end, nil, {
                        speed = 2
                    }
                )
            end)
        elseif speed >= 14 then
            Game.world:hurtParty(20)
        end
    end
end

return Player
