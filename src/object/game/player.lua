local Player, super = Class(Character)

function Player:init(chara, x, y)
    super:init(self, chara, x, y)

    local hx, hy, hw, hh = self.collider.x, self.collider.y, self.collider.width, self.collider.height

    self.interact_collider = {
        ["left"] = Hitbox(hx - hw/2, hy, hw, hh, self),
        ["right"] = Hitbox(hx + hw/2, hy, hw, hh, self),
        ["up"] = Hitbox(hx, hy - hh/2, hw, hh, self),
        ["down"] = Hitbox(hx, hy + hh/2, hw, hh, self)
    }

    self.history_time = 0
    self.history = {}

end

function Player:onAdd(parent)
    super:onAdd(self, parent)

    if parent:includes(World) and not parent.player then
        parent.player = self
    end
end

function Player:onRemove(parent)
    super:onRemove(self, parent)

    if parent:includes(World) and parent.player == self then
        parent.player = nil
    end
end

function Player:interact()
    local col = self.interact_collider[self.facing]

    for _,obj in ipairs(self.world.children) do
        if obj.onInteract and obj:collidesWith(col) and obj:onInteract(self, self.facing) then
            return true
        end
    end

    return false
end

function Player:update(dt)
    if #self.history == 0 then
        local ex, ey = self:getExactPosition()
        table.insert(self.history, {x = ex, y = ey, time = 0})
    end

    if self.moved > 0 then
        self.history_time = self.history_time + dt

        local ex, ey = self:getExactPosition()

        if self.last_collided_x then
            ex = self.x
        end
        if self.last_collided_y then
            ey = self.y
        end

        table.insert(self.history, 1, {x = ex, y = ey, time = self.history_time})
        while (self.history_time - self.history[#self.history].time) > (Game.max_followers * FOLLOW_DELAY) do
            table.remove(self.history, #self.history)
        end

        for _,follower in ipairs(Game.followers) do
            if follower.target == self and follower.following then
                follower:interprolate()
            end
        end
    end

    super:update(self, dt)
end

return Player