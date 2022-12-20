---@class Solid : Object
---@overload fun(...) : Solid
local Solid, super = Class(Object)

function Solid:init(filled, x, y, width, height)
    super:init(self, x, y, width, height)

    self.layer = BATTLE_LAYERS["above_arena"]

    if width and height then
        self:setHitbox(0, 0, width, height)
    end

    -- Damage applied to the soul when its squished against another solid by this one
    self.squish_damage = 80


    if filled then
        -- Default to arena green
        self.color = {0, 0.75, 0}

        -- Draw the filled collider
        self.draw_collider = true
    else
        self.draw_collider = false
    end
end

function Solid:move(x, y, speed)
    local movex, movey = x * (speed or 1), y * (speed or 1)

    Object.startCache()
    local collided_x = self:doMoveAmount(movex, 1, 0)
    local collided_y = self:doMoveAmount(movey, 0, 1)
    Object.endCache()

    return collided_x or collided_y
end

function Solid:moveTo(x, y)
    return self:move(x - self.x, y - self.y)
end

function Solid:doMoveAmount(amount, x_mult, y_mult)
    local sign = Utils.sign(amount)

    local soul_collided = false

    Object.startCache()
    for i = 1, math.ceil(math.abs(amount)) do
        local moved = sign
        if (i > math.abs(amount)) then
            moved = (math.abs(amount) % 1) * sign
        end

        self.x = self.x + (moved * x_mult)
        self.y = self.y + (moved * y_mult)
        Object.uncache(self)

        for _,soul in ipairs(self.stage:getObjects(Soul)) do
            if self:collidesWith(soul) then
                soul_collided = true

                self.collidable = false
                local _,collided = soul:move(sign * x_mult, sign * y_mult)
                Object.uncache(soul)
                if collided then
                    soul:onSquished(self)
                end
                self.collidable = true
            end
        end
    end
    Object.endCache()

    return soul_collided
end

function Solid:onSquished(soul)
    --[[if soul.inv_timer == 0 and self.squish_damage and self.squish_damage ~= 0 then
        local battler = Utils.pick(Game.battle:getActiveParty())
        if battler then
            battler:hurt(self.squish_damage)
        end

        soul.inv_timer = (4/3)
    end]]

    if self.squish_damage and self.squish_damage ~= 0 then
        local battler = Utils.pick(Game.battle:getActiveParty())
        if battler then
            battler:hurt(self.squish_damage)
        end
    end

    soul:explode()

    Game.battle.encounter:onWavesDone()
end

function Solid:draw()
    if self.draw_collider and self.collider then
        self.collider:drawFill(self:getColor())
    end

    super:draw(self)
end

return Solid