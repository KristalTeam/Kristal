local Follower, super = Class(Character)

function Follower:init(chara, x, y, target)
    super:init(self, chara, x, y)

    self.noclip = true

    self.index = 1
    self.target = target or Game.world.player

    self.following = true
    self.returning = false
end

function Follower:onAdd(parent)
    super:onAdd(self, parent)

    self.index = #Game.followers + 1
    table.insert(Game.followers, self)
end

function Follower:onRemove(parent)
    super:onRemove(self, parent)

    Utils.removeFromTable(Game.followers, self)
end

function Follower:updateIndex()
    for i,v in ipairs(Game.followers) do
        if v == self then
            self.index = i
        end
    end
end

function Follower:interprolate()
    if self.target and self.target.history then
        local ex, ey = self:getExactPosition()
        local tx, ty = self.x, self.y
        for i,v in ipairs(self.target.history) do
            tx, ty = v.x, v.y
            local upper = self.target.history_time - v.time
            if upper > (FOLLOW_DELAY * self.index) then
                if i > 1 then
                    local prev = self.target.history[i - 1]
                    local lower = self.target.history_time - prev.time

                    local t = ((FOLLOW_DELAY * self.index) - lower) / (upper - lower)

                    tx = Utils.lerp(prev.x, v.x, t)
                    ty = Utils.lerp(prev.y, v.y, t)
                end
                break
            end
        end

        local speed = 8 * DTMULT

        local dx = Utils.approach(ex, tx, speed) - ex
        local dy = Utils.approach(ey, ty, speed) - ey

        self:move(dx, dy)

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