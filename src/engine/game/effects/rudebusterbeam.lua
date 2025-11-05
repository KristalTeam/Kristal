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

    if red then self:setScale(2.5) end

    self.rotation = Utils.angle(x, y, tx, ty) + math.rad(20)
    self.physics.speed = 24
    self.physics.friction = -1.5
    self.physics.match_rotation = true

    self.alpha = 0

    self.pressed = false

    self.afterimg_timer = 0
    self.after_func = after

    self.bolt_timer = 0
    self.final_bolt = 0
    self.final_bolt_set = false
    self.chosen_bolt = 0
    self.bonus_anim = false
end

function RudeBusterBeam:update()
    self.alpha = MathUtils.approach(self.alpha, 1, 0.25 * DTMULT)

    local dir = Utils.angle(self.x, self.y, self.target_x, self.target_y)
    self.rotation = self.rotation + (Utils.angleDiff(dir, self.rotation) / 4) * DTMULT

    self.bolt_timer = self.bolt_timer + DTMULT
    if Input.pressed("confirm") and not self.pressed then
        self.pressed = true
        self.chosen_bolt = self.bolt_timer
    end

    if Utils.dist(self.x, self.y, self.target_x, self.target_y) <= 40 then
        if not self.final_bolt_set then
            self.final_bolt_set = true
            self.final_bolt = self.bolt_timer
        end
        if self.after_func then
            local damage_bonus, play_sound = 0, false
            if not Game:getConfig("oldRudeBuster") then
                -- Values are rounded since we have to account for different framerates
                -- Don't use floor or ceil since frame rate occasionally drops on low end devices
                -- Which will throw off the values
                self.chosen_bolt = Utils.round(self.chosen_bolt)
                self.final_bolt = Utils.round(self.final_bolt)
                if self.chosen_bolt > 0 then
                    if self.chosen_bolt == self.final_bolt then
                        damage_bonus = 30
                    elseif self.chosen_bolt == self.final_bolt - 1 then
                        damage_bonus = 28
                    elseif self.chosen_bolt == self.final_bolt - 2 then
                        damage_bonus = 22
                    elseif self.chosen_bolt == self.final_bolt - 3 then
                        damage_bonus = 20
                    elseif self.chosen_bolt == self.final_bolt - 4 then
                        damage_bonus = 13
                    elseif self.chosen_bolt == self.final_bolt - 5 then
                        damage_bonus = 11
                    elseif self.chosen_bolt == self.final_bolt - 6 then
                        damage_bonus = 10
                    end

                    if math.abs(self.chosen_bolt - self.final_bolt) <= 2 then
                        self.bonus_anim = true
                        play_sound = true
                    end
                end
            else
                if self.pressed then
                    damage_bonus = 30
                    play_sound = true
                end
            end
            self.after_func(damage_bonus, play_sound)
        end
        Assets.playSound("rudebuster_hit")
        for i = 1, 8 do
            local burst = RudeBusterBurst(self.red, self.target_x, self.target_y, math.rad(45 + ((i - 1) * 90)), i > 4, self.bonus_anim and 40 or 25)
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
        if self.red then sprite:setScale(2.5) end
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