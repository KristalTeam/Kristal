local ArenaSprite, super = Class(Object)

function ArenaSprite:init(arena, x, y)
    super:init(self, x, y)

    self.arena = arena

    self.width = arena.width
    self.height = arena.height

    self:setScaleOrigin(0.5, 0.5)
    self:setRotateOrigin(0.5, 0.5)

    self.background = true
    self.fading = false
end

function ArenaSprite:fade(alpha)
    self.initial_alpha = alpha
    self.alpha = alpha
    self.background = false
    self.lifetime = ((5/6) * alpha)
    self.time_alive = 0
    self.fading = true
end

function ArenaSprite:update(dt)
    self.width = self.arena.width
    self.height = self.arena.height

    if self.fading then
        self.time_alive = Utils.approach(self.time_alive, self.lifetime, dt)
        if self.time_alive == self.lifetime then
            self:remove()
            return
        end

        self.alpha = self.initial_alpha * (1 - (self.time_alive / self.lifetime))
    end

    self:updateChildren(dt)
end

function ArenaSprite:draw()
    if self.background then
        love.graphics.setColor(0, 0, 0)
        for _,triangle in ipairs(self.arena.triangles) do
            love.graphics.polygon("fill", unpack(triangle))
        end
    end

    self:drawChildren()

    local r,g,b,a = self:getDrawColor()
    local arena_r,arena_g,arena_b,arena_a = self.arena:getDrawColor()

    love.graphics.setColor(r * arena_r, g * arena_g, b * arena_b, a * arena_a)
    love.graphics.setLineStyle("rough")
    love.graphics.setLineWidth(self.arena.line_width)
    love.graphics.line(unpack(self.arena.border_line))
end

return ArenaSprite