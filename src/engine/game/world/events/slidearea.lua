local SlideArea, super = Class(Event)

function SlideArea:init(data)
    super:init(self, data.x, data.y, data.width, data.height)

    self.solid = false

    self.sliding = false

    self:setOrigin(0, 0)
    self:setHitbox(0, 0, data.width, data.height)
end

function SlideArea:update(dt)
    if not Game.world.player then return end

    if Game.world.player:collidesWith(self.collider) then
        Game.world.player:move(0, 1, 16 * DTMULT)
        Game.world.player:moveCamera()
        if not self.sliding then
            self.sliding = true
            Game.world.player:setSprite("slide")
        end
    else
        if self.sliding then
            self.sliding = false
            Game.world.player:resetSprite()
        end
    end

    if (Game.world.player.y - (Game.world.player.height/2)) > (self.y + self.height) then
        if not self.sliding then
            self.solid = true
        end
    else
        self.solid = false
    end

    super:update(self, dt)
end

return SlideArea