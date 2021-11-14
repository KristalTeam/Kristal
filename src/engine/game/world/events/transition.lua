local Transition, super = Class(Event)

function Transition:init(data)
    super:init(self, data.x, data.y, data.width, data.height)

    self.collider = Hitbox(self, 0, 0, self.width, self.height)

    self.target = {
        map = data.properties.map,
        x = data.properties.x,
        y = data.properties.y,
        marker = data.properties.marker
    }
end

function Transition:onCollide(chara)
    if chara == self.world.player then
        self.world:transition(self.target)
    end
end

return Transition