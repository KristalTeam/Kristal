local Transition, super = Class(Event)

function Transition:init(x, y, w, h, properties)
    super:init(self, x, y, w, h)

    properties = properties or {}

    self.target = {
        map = properties.map,
        x = properties.x,
        y = properties.y,
        marker = properties.marker
    }
end

function Transition:onCollide(chara)
    if chara == self.world.player then
        self.world:transition(self.target)
    end
end

return Transition