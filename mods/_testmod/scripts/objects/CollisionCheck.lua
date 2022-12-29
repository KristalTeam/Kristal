local CollisionCheck, super = Class(Object)

function CollisionCheck:init(x, y, collider)
    super.init(self, x, y)

    self.layer = BATTLE_LAYERS["below_soul"]

    if collider then
        self.collider = collider
        self.collider.parent = self
    end
end

function CollisionCheck:draw()
    if Game.battle and Game.battle.soul and Game.battle.soul:collidesWith(self) then
        self.collider:drawFill(1, 0.5, 0)
    else
        self.collider:drawFill(0, 0.5, 1)
    end
    super.draw(self)
end

return CollisionCheck