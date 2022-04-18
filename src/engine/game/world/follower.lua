local Follower, super = Class(Character)

function Follower:init(chara, x, y, target)
    super:init(self, chara, x, y)

    self.index = 1
    self.target = target

    self.state_manager = StateManager("WALK", self, true)
    self.state_manager:addState("WALK")
    self.state_manager:addState("SLIDE", {enter = self.beginSlide, leave = self.endSlide})

    self.history_time = 0
    self.history = {}

    self.needs_slide = false

    self.following = true
    self.returning = false
    self.return_speed = 6
end

function Follower:onRemove(parent)
    self.index = nil
    self:updateIndex()
    if self.index then
        table.remove(self.world.followers, self.index)
    end

    super:onRemove(self, parent)
end

function Follower:onAdd(parent)
    super:onAdd(self, parent)

    local target = self:getTarget()
    if target then
        self:copyHistoryFrom(target)
    end
end

function Follower:updateIndex()
    for i,v in ipairs(self.world.followers) do
        if v == self then
            self.index = i
        end
    end
end

function Follower:returnToFollowing(speed)
    local tx, ty = self:getTargetPosition()
    if Utils.roughEqual(self.x, tx) and Utils.roughEqual(self.y, ty) then
        self.following = true
    else
        self.returning = true
        self.return_speed = speed or 6
    end
end

function Follower:getTarget()
    return self.target or self.world.player
end

function Follower:getTargetPosition()
    local tx, ty, facing, state = self.x, self.y, self.facing, nil
    for i,v in ipairs(self.history) do
        tx, ty, facing, state = v.x, v.y, v.facing, v.state
        local upper = self.history_time - v.time
        if upper > (FOLLOW_DELAY * self.index) then
            if i > 1 then
                local prev = self.history[i - 1]
                local lower = self.history_time - prev.time

                local t = ((FOLLOW_DELAY * self.index) - lower) / (upper - lower)

                tx = Utils.lerp(prev.x, v.x, t)
                ty = Utils.lerp(prev.y, v.y, t)
            end
            break
        end
    end
    return tx, ty, facing, state
end

function Follower:moveToTarget(speed)
    if self:getTarget() and self:getTarget().history then
        local tx, ty, facing, state = self:getTargetPosition()
        local dx, dy = tx - self.x, ty - self.y

        if speed then
            dx = Utils.approach(self.x, tx, speed * DTMULT) - self.x
            dy = Utils.approach(self.y, ty, speed * DTMULT) - self.y
        end

        self:move(dx, dy)

        if facing and (not speed or (dx == 0 and dy == 0)) then
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

function Follower:interpolateHistory()
    local target = self:getTarget()

    local new_facing = Utils.facingFromAngle(Utils.angle(self.x, self.y, target.x, target.y))
    self.history = {
        {x = target.x, y = target.y, facing = target.facing, time = self.history_time, state = target.state},
        {x = self.x, y = self.y, facing = new_facing, time = self.history_time - (self.index * FOLLOW_DELAY), state = self.state}
    }
end

function Follower:beginSlide()
    self.needs_slide = false
    self.sprite:setAnimation("slide")
end
function Follower:endSlide()
    self.sprite:resetSprite()
end

function Follower:copyHistoryFrom(target)
    self.history_time = target.history_time
    self.history = Utils.copy(target.history)
end
function Follower:updateHistory(dt, moved)
    local target = self:getTarget()
    if target.state == "SLIDE" and self.state ~= "SLIDE" then
        self.needs_slide = true
    end

    if moved or self.state == "SLIDE" or self.needs_slide then
        self.history_time = self.history_time + dt

        table.insert(self.history, 1, {x = target.x, y = target.y, facing = target.facing, time = self.history_time, state = target.state})
        while (self.history_time - self.history[#self.history].time) > (Game.max_followers * FOLLOW_DELAY) do
            table.remove(self.history, #self.history)
        end

        if self.following and not self.move_target then
            self:moveToTarget()
        end
    end
end

function Follower:update(dt)
    self:updateIndex()

    if #self.history == 0 then
        table.insert(self.history, {x = self.x, y = self.y, time = 0})
    end

    if self.returning and not self.move_target then
        local dx, dy = self:moveToTarget(self.return_speed)
        if dx == 0 and dy == 0 then
            self.returning = false
            self.following = true
        end
    end

    super:update(self, dt)
end

return Follower