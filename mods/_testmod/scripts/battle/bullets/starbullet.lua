local StarBullet, super = Class(Bullet, "StarBullet")

function StarBullet:init(x, y)
    super.init(self, x, y, "bullets/star")

    self.grazed = true
    self.graphics.spin = math.rad(45 / 4)

    self.inv_timer = 1 / 30
    self.destroy_on_hit = false

    self.timer = 0
end

function StarBullet:shouldSwoon(damage, target, soul)
    return true
end

function StarBullet:update()
    super.update(self)

    self.timer = self.timer + DTMULT
    if self.parent then
        while self.timer >= 1 do
            self.parent:addChild(AfterImage(self, 0.5, 0.1))
            self.timer = self.timer - 1
        end
    end
end

return StarBullet
