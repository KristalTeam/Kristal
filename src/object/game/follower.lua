local Follower, super = Class(Character)

function Follower:init(chara, x, y, target)
    super:init(self, chara, x, y)

    self.index = 1
    self.target = target or Game.world.player

    self.last_target_x = nil
    self.last_target_y = nil

    self.following = true
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
            local upper = self.target.history_time - v.time
            if upper > (FOLLOW_DELAY * self.index) then
                if i > 1 then
                    local lower = self.target.history_time - self.target.history[i - 1].time

                    local t = ((FOLLOW_DELAY * self.index) - lower) / (upper - lower)

                    tx = Utils.lerp(tx, v.x, t)
                    ty = Utils.lerp(ty, v.y, t)
                end
                break
            else
                tx, ty = v.x, v.y
            end
        end

        local speed = 10 * DTMULT

        local dx = Utils.approach(ex, tx, speed) - ex
        local dy = Utils.approach(ey, ty, speed) - ey

        self:move(dx, dy)
    end
end

function Follower:update(dt)
    self:updateIndex()

    local ex, ey = self.target:getExactPosition()

    if self.last_target_x then
        local moved = ex ~= self.last_target_x or ey ~= self.last_target_y
        if moved and self.following and self.target then
            self:interprolate()
        end
    end
    self.last_target_x = ex
    self.last_target_y = ey

    super:update(self, dt)
end

return Follower