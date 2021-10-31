local Vironeedle, super = Class(Wave)

function Vironeedle:start()
    self.timer:every(1/3, function()
        local arena = Game.battle.arena
        local x, y = arena.x + arena.width/2 + 50, arena.y - arena.height/2 + (love.math.random() * arena.height)

        local bullet = self:spawnBullet("bullets/viro_needle", x, y, 14, 4)
        bullet.sprite:play(1/15, false)
        bullet.alpha = 0
        bullet.rotation = math.rad(180)
        self.timer:tween(0.25, bullet, {alpha = 1, speed = 5})
    end)
end

return Vironeedle