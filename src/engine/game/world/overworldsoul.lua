local OverworldSoul, super = Class(Object)

function OverworldSoul:init(x, y)
    super:init(self, x, y)

    self:setColor(1, 0, 0)

    --self.layer = LAYERS["soul"]

    self.sprite = Sprite("player/heart_dodge")
    self.sprite:setOrigin(0.5, 0.5)
    self.sprite.inherit_color = true
    self:addChild(self.sprite)

    self.collider = CircleCollider(self, 0, 0, 8)

    self.inv_timer = 0
    self.inv_flash_timer = 0

    self.moving_x = 0
    self.moving_y = 0

    self.noclip = false
end

function OverworldSoul:transitionTo(x, y)
    self.transitioning = true
    self.target_x = x
    self.target_y = y
    self.timer = 0
end

function OverworldSoul:onCollide(bullet)
    -- Handles damage
    bullet:onCollide(self)
end

function OverworldSoul:update(dt)
    -- Bullet collision !!! Yay
    if self.inv_timer > 0 then
        self.inv_timer = Utils.approach(self.inv_timer, 0, dt)
    end

    Object.startCache()
    for _,bullet in ipairs(Game.stage:getObjects(WorldBullet)) do
        if bullet:collidesWith(self.collider) then
            self:onCollide(bullet)
        end
    end
    Object.endCache()

    if self.inv_timer > 0 then
        self.inv_flash_timer = self.inv_flash_timer + dt
        local amt = math.floor(self.inv_flash_timer / (4/30))
        if (amt % 2) == 1 then
            self.sprite:setColor(0.5, 0.5, 0.5)
        else
            self.sprite:setColor(1, 1, 1)
        end
    else
        self.inv_flash_timer = 0
        self.sprite:setColor(1, 1, 1)
    end

    super:update(self, dt)
end

function OverworldSoul:draw()
    super:draw(self)

    if DEBUG_RENDER then
        self.collider:draw(0, 1, 0)
    end
end

return OverworldSoul