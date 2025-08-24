local StarBullet, super = Class(Bullet, "StarBullet")

function StarBullet:init(x, y)
    super.init(self, x, y, "bullets/star")

    self.grazed = true
    self.graphics.spin = math.rad(45 / 4)

    self.inv_timer = 1 / 30
    self.destroy_on_hit = false
end

function StarBullet:update()
    super.update(self)

    if self.parent then
        self.parent:addChild(AfterImage(self, 0.5, 0.1))
    end
end

return StarBullet
