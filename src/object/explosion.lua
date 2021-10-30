local Explosion, super = Class(Object)

function Explosion:init(x, y)
    super:init(self, x, y)

    self.frames = Assets.getFrames("misc/realistic_explosion")
    self.frame = 1
    self.speed = 1

    self.time = 0

    self.width = self.frames[1]:getWidth()
    self.height = self.frames[1]:getHeight()
    self:setOrigin(0.5, 0.5)
    self:setScale(2)
end

function Explosion:onAdd()
    local explodsion = love.audio.newSource("assets/sounds/snd_badexplosion.wav", "static")
    explodsion:play()
end

function Explosion:update(dt)
    self.time = self.time + dt

    self.frame = math.floor(self.time / 0.05) + 1
    if self.frame > #self.frames then
        self:remove()
    end

    super:update(self, dt)
end

function Explosion:draw()
    love.graphics.draw(self.frames[self.frame])
    super:draw(self)
end

return Explosion