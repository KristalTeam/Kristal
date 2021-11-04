local Bullet, super = Class(Object)

function Bullet:init(x, y, texture)
    super:init(self, x, y)

    -- idk whatever we'll do this later or something
    self.layer = 100

    -- Add a sprite, if we provide one
    if texture then
        self:setSprite(texture, 0.25, true)
    end

    -- Default collider to half this object's size
    self.collider = Hitbox(self, -self.width/4, -self.height/4, self.width/2, self.height/2)

    -- Move direction (defaults to rotation)
    self.direction = nil
    -- Speed in the current move direction
    self.speed = 0

    -- TP added when you graze this bullet (Also given each frame after the first graze, 30x less at 30FPS)
    self.tp = 4
    -- Turn time reduced when you graze this bullet (Also applied each frame after the first graze, 30x less at 30FPS)
    self.time_bonus = 1

    -- Damage given to the player when hit by this bullet
    self.damage = 10
    -- Invulnerability timer to apply to the player when hit by this bullet
    self.inv_timer = (4/3)
    -- Whether this bullet gets removed on collision with the player
    self.destroy_on_hit = true

    -- Whether this bullet has already been grazed (reduces graze rewards)
    self.grazed = false

    -- Whether to remove this bullet when it goes offscreen
    self.remove_offscreen = true
end

function Bullet:onDamage(soul)
    if self.damage > 0 then
        local battler = Game.battle.party[love.math.random(#Game.battle.party)]
        battler:hurt(self.damage)

        soul.inv_timer = self.inv_timer
    end
end

function Bullet:onCollide(soul)
    if soul.inv_timer == 0 then
        self:onDamage(soul)
    end

    if self.destroy_on_hit then
        self:remove()
    end
end

function Bullet:setSprite(texture, speed, loop, on_finished)
    if self.sprite then
        self:removeChild(self.sprite)
    end
    if texture then
        self.sprite = Sprite(texture)
        self.sprite:setOrigin(0.5, 0.5)
        self.sprite:setScale(2)
        self.sprite.inherit_color = true
        self:addChild(self.sprite)

        if speed then
            self.sprite:play(speed, loop, on_finished)
        end

        self.width = self.sprite.width
        self.height = self.sprite.height

        return self.sprite
    end
end

function Bullet:getDirection()
    return self.direction or self.rotation
end

function Bullet:isBullet(id)
    return self:includes(Registry.getBullet(id))
end

function Bullet:update(dt)
    if self.speed ~= 0 then
        self.speed = Utils.approach(self.speed, 0, self.friction * DTMULT)

        local dir = self:getDirection()
        self:move(math.cos(dir), math.sin(dir), self.speed * DTMULT)
    end

    super:update(self, dt)

    if self.remove_offscreen then
        if self.x < -100 or self.y < -100 or self.x > SCREEN_WIDTH + 100 or self.y > SCREEN_HEIGHT + 100 then
            self:remove()
        end
    end
end

function Bullet:draw()
    super:draw(self)

    if DEBUG_RENDER and self.collider then
        self.collider:draw(1, 0, 0)
    end
end

return Bullet