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
        if self.target.marker then
            x, y = Game.world.map:getMarker(self.target.marker)
        end

        local facing = self.target.facing

        if self.target.shop then
            self.world:enterShop(self.target.shop, {x=x, y=y, facing=facing, map=self.target.map})
        elseif self.target.map then
            self.world:mapTransition(self.target.map, x, y, facing)
        end
    end
end

return Transition