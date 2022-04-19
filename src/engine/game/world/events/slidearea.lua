local SlideArea, super = Class(Event)

function SlideArea:init(x, y, w, h)
    super:init(self, x, y, w, h)

    self.solid = true

    self.sliding = false
end

function SlideArea:onCollide(chara, dt)
    if chara.y <= self.y and chara:includes(Player) then
        if not self.sliding then
            Assets.stopAndPlaySound("snd_noise")
        end

        self.solid = false
        self.sliding = true

        chara:setState("SLIDE")
    end
end

function SlideArea:update(dt)
    if not Game.world.player then return end

    if Game.world.player.y > self.y + self.height then
        if self.sliding and not Game.world.player:collidesWith(self.collider) then
            self.sliding = false
            self.solid = true
            Game.world.player:setState("WALK")
        end
    end

    super:update(self, dt)
end

return SlideArea