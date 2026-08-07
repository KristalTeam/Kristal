---@class CherubFeather : Sprite
---@overload fun(...) : CherubFeather
local CherubFeather, super = Class(Sprite)

---@param x number
---@param y number
function CherubFeather:init(x, y, starting_dir)
    super.init(self, "effects/cherub_feathers", x, y, 24, 18)

    self:setOrigin(0.5, 11 / 18)

    self:setPhysics({
        direction = starting_dir,
        speed = MathUtils.random(5, 15),
        friction = 2
    })

    self:setFrame(MathUtils.randomInt(1, 4))

    self.fallspeed = 0
    self.siner = MathUtils.random(math.pi * 30)

    self.spinner = 0
    self.spin_start = MathUtils.randomInt(-90, 90 + 1)
    self.spin_offset = self.spin_start
    self:setScale(2)

    self.lifetime = 30
end

function CherubFeather:update()
    if self.physics.speed < 5 then
        self.physics.friction = 0.2
    end

    if self.physics.speed < 2 then
        self.fallspeed = MathUtils.approach(self.fallspeed, 1, 0.05 * DTMULT)
    end

    self.y = self.y + self.fallspeed * DTMULT
    self.x = self.x + (math.sin(self.siner / 15) * (self.fallspeed / 2)) * DTMULT

    self.siner = self.siner + DTMULT

    self.rotation = -math.rad((-math.cos(self.siner / 15) * 30) + self.spin_offset)

    if self.spinner < 1 then
        local spinease = Ease.outQuad(self.spinner, 0, 1, 1)
        self.spinner = math.min(self.spinner + 0.1 * DTMULT, 1)
        self.spin_offset = MathUtils.lerp(self.spin_start, 0, spinease)
    end

    if self.fallspeed == 1 then
        self.lifetime = self.lifetime - DTMULT
    end

    if self.lifetime <= 0 then
        self.alpha = self.alpha - 0.1 * DTMULT

        if self.alpha <= 0 then
            self:remove()
        end
    end

    super.update(self)
end

return CherubFeather
