local Follower, super = Class(Character)

function Follower:init(chara, x, y, target)
    super:init(self, chara, x, y)

    self.index = 1
    self.target = target

    self.following = true
    self.returning = false
end

function Follower:onRemove(parent)
    self.index = nil
    self:updateIndex()
    if self.index then
        table.remove(self.world.followers, self.index)
    end

    super:onRemove(self, parent)
end

function Follower:updateIndex()
    for i,v in ipairs(self.world.followers) do
        if v == self then
            self.index = i
        end
    end
end

function Follower:getTarget()
    return self.target or self.world.player
end

function Follower:getTargetPosition()
    local target = self:getTarget()
    if target and target.history then
        local tx, ty, facing = self.x, self.y, self.facing
        for i,v in ipairs(target.history) do
            tx, ty, facing = v.x, v.y, v.facing
            local upper = target.history_time - v.time
            if upper > (FOLLOW_DELAY * self.index) then
                if i > 1 then
                    local prev = target.history[i - 1]
                    local lower = target.history_time - prev.time

                    local t = ((FOLLOW_DELAY * self.index) - lower) / (upper - lower)

                    tx = Utils.lerp(prev.x, v.x, t)
                    ty = Utils.lerp(prev.y, v.y, t)
                end
                break
            end
        end
        return tx, ty, facing
    else
        return self:getExactPosition(), self.facing
    end
end

function Follower:interprolate()
    if self:getTarget() and self:getTarget().history then
        local ex, ey = self:getExactPosition()
        local tx, ty, facing = self:getTargetPosition()

        local speed = 8 * DTMULT

        local dx = Utils.approach(ex, tx, speed) - ex
        local dy = Utils.approach(ey, ty, speed) - ey

        self:move(dx, dy)
        if facing then
            self:setFacing(facing)
        end

        return dx, dy
    else
        return 0, 0
    end
end

function Follower:update(dt)
    self:updateIndex()

    if self.returning then
        local dx, dy = self:interprolate()
        if dx == 0 and dy == 0 then
            self.returning = false
        end
    end

    super:update(self, dt)
end

return Follower