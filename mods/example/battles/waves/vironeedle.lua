local Vironeedle, super = Class(Wave)

function Vironeedle:start()
    self.timer:every(1/3, function()
        local arena = Game.battle.arena

        local x, y = arena.right + 40 + Utils.random(140), Utils.random(arena.top, arena.bottom)
        self:spawnBullet("vironeedle", x, y)
    end)
end

return Vironeedle
