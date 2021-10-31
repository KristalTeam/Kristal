local Bullet, super = Class(Object)

function Bullet:init(texture, x, y, width, height)
    super:init(self, x, y)

    -- idk whatever we'll do this later or something
    self.layer = 100

    -- Add a sprite, if we provide one
    if texture then
        self.sprite = Sprite(texture)
        self.sprite.inherit_color = true
        self.sprite:play(0.25, true)

        -- Default to centered and 2x scaled
        self.sprite:setOrigin(0.5, 0.5)
        self.sprite:setSize(2)

        self:addChild(self.sprite)

        -- Default object's size to sprite size, if we don't provide it
        self.width = self.sprite.width
        self.height = self.sprite.height
    end

    local hw, hh = width or self.width/2, height or self.height/2

    -- Default collider to half this object's size
    self.collider = Hitbox(-hw/2, -hh/2, hw, hh, self)

    -- Speed in the current rotation direction
    self.speed = 0

    -- TP added when you graze this bullet (Also given each frame after the first graze, 30x less at 30FPS)
    self.graze_points = 5
    -- Turn time reduced when you graze this bullet (Also applied each frame after the first graze, 30x less at 30FPS)
    self.time_points = 1

    -- Damage given to the player when hit by this bullet
    self.damage = 10
    -- Invulnerability timer to apply to the player when hit by this bullet
    self.inv_timer = 2
    -- Whether this bullet gets removed on collision with the player
    self.destroy_on_hit = true

    -- Whether this bullet has already been grazed (reduces graze rewards)
    self.grazed = false

    -- Whether to remove this bullet when it goes offscreen
    self.remove_offscreen = true
end

function Bullet:update(dt)
    if self.speed > 0 then
        self.speed = Utils.approach(self.speed, 0, self.friction)

        self:move(math.cos(self.rotation), math.sin(self.rotation), self.speed * DTMULT)
    end

    super:update(self, dt)

    if self.remove_offscreen then
        if self.x < -100 or self.y < -100 or self.x > SCREEN_WIDTH + 100 or self.y > SCREEN_HEIGHT + 100 then
            self:remove()
        end
    end
end

return Bullet