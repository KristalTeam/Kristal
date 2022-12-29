local Invader, super = Class(Bullet, "virovirokun/invader")

function Invader:init(x, y)
    super.init(self, x, y)

    self:setSprite("bullets/virovirokun/invader")
    self:setHitbox(0, 1, 16, 14)

    self.destroy_on_hit = false

    self.shot_ready = false
    self.buffed = false

    self.flash_timer = 0

    self.flash_fx = self:addFX(ColorMaskFX())
    self.flash_fx:setColor(1, 1, 1)
    self.flash_fx.amount = 0
end

function Invader:nextFrame()
    self.sprite:setFrame((self.sprite.frame % #self.sprite.frames) + 1)
end

function Invader:update()
    super.update(self)
    --local relative_x = self:
    if self.shot_ready then
        if self.flash_timer < 8 then
            self.flash_timer = self.flash_timer + DTMULT
        else
            self.shot_ready = false
            local x, y = self:getRelativePos(self.width/2, self.height/2, Game.battle)
            local bullet = self.wave:spawnBullet("virovirokun/invader_bullet", x, y, self.buffed)
            bullet.tp = self.tp
            self.flash_timer = 0
        end
    end

    if self.buffed and self.shot_ready and math.floor(self.flash_timer) % 4 < 2 then
        self.flash_fx.amount = 1
    else
        self.flash_fx.amount = 0
    end
end

return Invader