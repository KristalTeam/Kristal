---@class RudeBusterBeam : Sprite
---@overload fun(...) : RudeBusterBeam
local RudeBusterBeam, super = Class(Sprite)

function RudeBusterBeam:init(red, x, y, tx, ty, after)
    super.init(self, red and "effects/rudebuster/beam_red" or "effects/rudebuster/beam", x, y)

    self:setOrigin(0.5, 0.5)
    self:setScale(2)

    self:play(1/30, true)

    self.target_x = tx
    self.target_y = ty
    self.red = red

    self.rotation = Utils.angle(x, y, tx, ty) + math.rad(20)
    self.physics.speed = 24
    self.physics.friction = -1.5
    self.physics.match_rotation = true

    self.alpha = 0

    self.pressed = false

    self.afterimg_timer = 0
    self.after_func = after
end

function RudeBusterBeam:update()
    self.alpha = Utils.approach(self.alpha, 1, 0.25 * DTMULT)

    local dir = Utils.angle(self.x, self.y, self.target_x, self.target_y)
    self.rotation = self.rotation + (Utils.angleDiff(dir, self.rotation) / 4) * DTMULT

    if Input.pressed("confirm") then
        self.pressed = true
    end

    if Utils.dist(self.x, self.y, self.target_x, self.target_y) <= 40 then
        if self.after_func then
            self.after_func(self.pressed)
        end
        Assets.playSound("rudebuster_hit")
        for i = 1, 8 do
            local burst = RudeBusterBurst(self.red, self.target_x, self.target_y, math.rad(45 + ((i - 1) * 90)), i > 4)
            burst.layer = self.layer + (0.01 * i)
            self.parent:addChild(burst)
        end
        self:remove()
        return
    end

    self.afterimg_timer = self.afterimg_timer + DTMULT
    if self.afterimg_timer >= 1 then
        self.afterimg_timer = 0

        local sprite = Sprite(self.red and "effects/rudebuster/beam_red" or "effects/rudebuster/beam", self.x, self.y)
        sprite:fadeOutSpeedAndRemove()
        sprite:setOrigin(0.5, 0.5)
        sprite:setScale(2, 1.8)
        sprite.rotation = self.rotation
        sprite.alpha = self.alpha - 0.2
        sprite.layer = self.layer - 0.01
        sprite.graphics.grow_y = -0.1
        sprite.graphics.remove_shrunk = true
        sprite:play(1/15, true)
        self.parent:addChild(sprite)
    end

    super.update(self)
end

return RudeBusterBeam