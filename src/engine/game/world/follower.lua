local Follower, super = Class(Character)

function Follower:init(chara, x, y, target)
    super:init(self, chara, x, y)

    self.index = 1
    self.target = target

    self.state_manager = StateManager("WALK", self, true)
    self.state_manager:addState("WALK")
    self.state_manager:addState("SLIDE", {enter = self.beginSlide, leave = self.endSlide})

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
        local target_time = math.max(target.history_time, self.state == "SLIDE" and target.slide_after_time or 0)
        local tx, ty, facing, state = self.x, self.y, self.facing, nil
        for i,v in ipairs(target.history) do
            tx, ty, facing, state = v.x, v.y, v.facing, v.state
            local upper = target_time - v.time
            if upper > (FOLLOW_DELAY * self.index) then
                if i > 1 then
                    local prev = target.history[i - 1]
                    local lower = target_time - prev.time

                    local t = ((FOLLOW_DELAY * self.index) - lower) / (upper - lower)

                    tx = Utils.lerp(prev.x, v.x, t)
                    ty = Utils.lerp(prev.y, v.y, t)
                end
                break
            end
        end
        return tx, ty, facing, state
    else
        return self:getExactPosition(), self.facing
    end
end

function Follower:interprolate(slow)
    if self:getTarget() and self:getTarget().history then
        local ex, ey = self:getExactPosition()
        local tx, ty, facing, state = self:getTargetPosition()

        local dx, dy = tx - ex, ty - ey

        if slow then
            local speed = 9 * DTMULT

            dx = Utils.approach(ex, tx, speed) - ex
            dy = Utils.approach(ey, ty, speed) - ey
        end

        self:move(dx, dy)

        if facing then
            self:setFacing(facing)
        end

        if state and self.state_manager:hasState(state) then
            self.state_manager:setState(state)
        end

        return dx, dy
    else
        return 0, 0
    end
end

function Follower:beginSlide()
    self.sprite:setAnimation("slide")
end
function Follower:endSlide()
    self.sprite:resetSprite()
end

function Follower:update(dt)
    self:updateIndex()

    if self.returning then
        local dx, dy = self:interprolate(true)
        if dx == 0 and dy == 0 then
            self.returning = false
        end
    end

    super:update(self, dt)
end

return Follower