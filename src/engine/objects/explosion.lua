---@class Explosion : Object
---@overload fun(...) : Explosion
local Explosion, super = Class(Object)

function Explosion:init(x, y)
    super.init(self, x, y)

    self.frames = Assets.getFrames("misc/realistic_explosion")
    self.frame = 1
    self.speed = 0.5

    self.time = 0

    self.width = self.frames[1]:getWidth()
    self.height = self.frames[1]:getHeight()
    self:setOrigin(0.5, 0.5)
    self:setScale(2)

    self.play_sound = true
end

function Explosion:onAdd()
    if self.play_sound then
        Assets.playSound("badexplosion")
    end
end

function Explosion:update()
    self.time = self.time + (self.speed * DTMULT)

    self.frame = math.floor(self.time) + 1
    if self.frame > #self.frames then
        self:remove()
    end

    super.update(self)
end

function Explosion:draw()
    Draw.draw(self.frames[self.frame])
    super.draw(self)
end

return Explosion