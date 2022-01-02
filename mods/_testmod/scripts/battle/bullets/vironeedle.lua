local Vironeedle, super = Class(Bullet)

function Vironeedle:init(x, y, slow, right)
    super:init(self, x, y)

    self.collidable = false

    self:setSprite("bullets/viro_needle", 1/15, false, function() self.collidable = true end)
    self:setHitbox(4, 6.5, 7, 2)

    self.infect_collider = Hitbox(self, 1, 5, 14, 5)

    self.alpha = 0
    if not right then
        self.rotation = math.pi
    end
    self.physics.match_rotation = true
    self.physics.speed = 1
    self.physics.friction = -0.2
    if slow then
        self.physics.friction = -0.15
    end

    self.tp = 2

    self.infecting = false
end

function Vironeedle:infect(other)
    other:remove()
    self.collidable = false
    self.infecting = true
    self.physics.speed = 0
    self:setLayer(math.max(self.layer, other.layer) + 0.01)
    self:setPosition(Vector.lerp(self.x,self.y, other.x,other.y, 0.5))
    self.sprite:setSprite("bullets/viro_needle_pop")
    self.sprite:setAnimation(function(sprite, wait)
        for i = 1,3 do
            sprite:setFrame(i)
            wait(1/30)
        end
        local bullet = self.wave:spawnBullet("virovirus", self.x, self.y)
        bullet:setLayer(self.layer - 0.01)
        sprite:setFrame(4)
        wait(1/30)
        self:remove()
    end)
end

function Vironeedle:update(dt)
    if (self.rotation == 0 and self.x > Game.battle.arena.right + 10) or (self.rotation == math.pi and self.x < Game.battle.arena.left - 10) then
        self.collidable = false
        self:fadeTo(0, 0.1)
        if self.alpha == 0 then
            self:remove()
        end
    else
        self:fadeTo(1, 0.1)
    end

    super:update(self, dt)
end

function Vironeedle:draw()
    super:draw(self)

    if DEBUG_RENDER then
        self.infect_collider:draw(1, 0, 1, 0.5)
    end
end

return Vironeedle