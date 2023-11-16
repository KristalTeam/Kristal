local ArenaHazard, super = Class(Bullet)

function ArenaHazard:init(x, y, rot)
    -- Last argument = sprite path
    super.init(self, x, y, "bullets/arenahazard")

    -- Top-center origin point (will be rotated around it)
    self:setOrigin(0.5, 0)

    -- The hitbox where the player will be damaged by the bullet (affected by scale and rotation)
    self:setHitbox(0, 0, self.width, 8)

    -- Rotation of the bullet (in radians)
    self.rotation = rot

    -- Don't destroy this bullet when it damages the player
    self.destroy_on_hit = false
end

function ArenaHazard:update()
    -- For more complicated bullet behaviours, code here gets called every update

    super.update(self)
end

return ArenaHazard