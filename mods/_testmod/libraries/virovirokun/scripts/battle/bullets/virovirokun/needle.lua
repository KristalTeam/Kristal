local Needle, super = Class(Bullet)

function Needle:init(x, y, slow, right)
    super.init(self, x, y)

    self.collidable = false

    self:setSprite("bullets/virovirokun/needle", 1/15, false, function() self.collidable = true end)
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

function Needle:infect(other)
    if not other.parent or not self.parent then return end

    self.collidable = false
    self.infecting = true
    self.physics.speed = 0

    self:setLayer(math.max(self.layer, other.layer) + 0.01)

    local ox, oy = other:getRelativePosFor(self.parent)

    if other.id == self.id then
        self:setPosition(Utils.lerpPoint(self.x,self.y, ox,oy, 0.5))
    else
        self:setPosition(ox, oy)
    end

    local poison_sprite = Sprite("bullets/virovirokun/poison_big", ox, oy)
    poison_sprite:setOrigin(0.5, 0.5)
    poison_sprite:setScale(2, 2)
    poison_sprite:setLayer(self.layer + 0.01)
    poison_sprite:play(2/30, false, function(sprite)
        sprite:remove()
    end)
    self.parent:addChild(poison_sprite)

    self.sprite:setSprite("bullets/virovirokun/needle_pop")
    self.sprite:setAnimation(function(sprite, wait)
        for i = 1,3 do
            sprite:setFrame(i)
            wait(1/30)
        end
        local bullet = self.wave:spawnBullet("virovirokun/virus", self.x, self.y)
        bullet:setLayer(self.layer - 0.01)
        sprite:setFrame(4)
        wait(1/30)
        self:remove()
    end)

    other:remove()
end

function Needle:update()
    if (self.rotation == 0 and self.x > Game.battle.arena.right + 10) or (self.rotation == math.pi and self.x < Game.battle.arena.left - 10) then
        self.collidable = false
        self:fadeToSpeed(0, 0.1)
        if self.alpha == 0 then
            self:remove()
        end
    else
        self:fadeToSpeed(1, 0.1)
    end

    super.update(self)
end

function Needle:draw()
    super.draw(self)

    if DEBUG_RENDER then
        self.infect_collider:draw(1, 0, 1, 0.5)
    end
end

return Needle