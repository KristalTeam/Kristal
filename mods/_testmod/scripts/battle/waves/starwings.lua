local Starwings, super = Class(Wave)

function Starwings:init()
    super:init(self)
    self.time = -1
    self.starwalker = Game.battle.enemies[1]
end

function Starwings:update(dt)
    super:update(self, dt)
    local star = self:spawnBullet("bullets/star", self.starwalker.x - 20, self.starwalker.y - 40)
    star.physics.direction = math.atan2(Game.battle.soul.y - star.y, Game.battle.soul.x - star.x)
    star.physics.speed = 4
end

return Starwings
