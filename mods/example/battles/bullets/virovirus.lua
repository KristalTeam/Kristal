local Virovirus, super = Class(Bullet)

function Virovirus:init(x, y)
    super:init(self, x, y)

    self:setSprite("bullets/viro_virus", 3/30, true)
    self:setHitbox(10, 10, 12, 12)

    self.speed = 0.1
    self.friction = -0.1
    self.direction = Utils.angle(self.x, self.y, Game.battle.soul.x, Game.battle.soul.y)
end

return Virovirus