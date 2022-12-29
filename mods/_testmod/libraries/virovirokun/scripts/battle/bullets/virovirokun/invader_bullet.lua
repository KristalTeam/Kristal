local InvaderBullet, super = Class(Bullet, "virovirokun/invader_bullet")

function InvaderBullet:init(x, y, buffed)
    super.init(self, x, y)

    self:setSprite("bullets/virovirokun/invader_bullet", 3/30, true)
    self:setHitbox(7, 10, 1, 4)

    self.physics.speed = buffed and 6 or 4
    self.physics.direction = math.rad(90)

    if buffed then
        self.scale_x = self.scale_x * 2
    end

    self.exploded = false
end

function InvaderBullet:update()
    super.update(self)

    if not self.exploded then
        local arena_x, arena_y = Game.battle.arena:getCenter()
        if self.y >= arena_y and Game.battle:checkSolidCollision(self) then
            self.collidable = false
            self.physics.speed = 0

            self:setSprite("bullets/virovirokun/invader_bullet_impact", 18/30, false, function()
                self:remove()
            end)

            self.y = Game.battle.arena:getBottom()
            self:setOrigin(0.5, 1)

            self.exploded = true
        end
    end
end

return InvaderBullet