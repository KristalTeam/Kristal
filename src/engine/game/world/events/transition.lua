local Transition, super = Class(Event)

function Transition:init(x, y, w, h, properties)
    super:init(self, x, y, w, h)

    properties = properties or {}

    self.target = {
        map = properties.map,
        shop = properties.shop,
        x = properties.x,
        y = properties.y,
        marker = properties.marker,
        facing = properties.facing,
    }
end

function Transition:onEnter(chara)
    if chara.is_player then
        local x, y = self.target.x, self.target.y
        local facing = self.target.facing
        local marker = self.target.marker

        if self.target.shop then
            self.world:shopTransition(self.target.shop, {x=x, y=y, marker=marker, facing=facing, map=self.target.map})
        elseif self.target.map then
            if marker then
                self.world:mapTransition(self.target.map, marker, facing)
            else
                self.world:mapTransition(self.target.map, x, y, facing)
            end
        end
    end
end

return Transition