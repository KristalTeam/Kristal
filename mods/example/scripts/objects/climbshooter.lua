--- The "ClimbShooter" object. Every so often, it will shoot a bullet.
---@class ClimbShooter : Event
local ClimbShooter, super = Class(Event, "ClimbShooter")

---@param x number
---@param y number
---@param shape EventShape?
---@param timer_offset number?
---@param shoot_speed number?
function ClimbShooter:init(x, y, shape, timer_offset, shoot_speed)
    super.init(self, x, y, shape)

    self.timer = timer_offset or 0
    self.shoot_speed = shoot_speed or 45
end

function ClimbShooter:update()
    -- Update happens every frame!

    -- Increasing a variable either frame must use either DT or DTMULT, since Kristal can be any FPS.
    self.timer = self.timer + DTMULT
    -- This is the same as increasing "timer" by 1 every frame at 30 FPS.

    if self.timer >= self.shoot_speed then
        -- Reset the timer (keeping any overshoot!)
        self.timer = self.timer - self.shoot_speed

        -- Create a new bullet (at our center)
        local bullet = WorldBullet(self.x + (self.width / 2), self.y + (self.height + 2), "bullets/smallbullet")

        -- This is for climbing, so it should always be visible.
        bullet.battle_fade = false

        -- Double sized...
        bullet:setScale(3)

        -- With gravity...
        bullet.physics.gravity = 0.4

        -- And an initial speed upwards.
        bullet:setSpeed(0, -4)

        -- Spawn it invisible,
        bullet.alpha = 0

        -- And fade it to fully visible over 0.25 seconds.
        bullet:fadeTo(1, 0.25)

        -- Set its layer properly (so it appears above the player)
        bullet:setLayer(WORLD_LAYERS["bullets"])

        -- And spawn it in the world.
        Game.world:addChild(bullet)

        Game.world.timer:after(35 / 30, function()
            bullet:fadeOutAndRemove(0.25)
        end)
    end
end

return ClimbShooter
