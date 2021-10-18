local Player, super = Class(Character)

function Player:init(chara, x, y)
    super:init(self, chara, x, y)

    local hx, hy, hw, hh = self.collider.x, self.collider.y, self.collider.width, self.collider.height

    self.interact_collider = {
        ["left"] = Hitbox(hx - hw/2, hy, hw, hh, self),
        ["right"] = Hitbox(hx + hw/2, hy, hw, hh, self),
        ["up"] = Hitbox(hx, hy - hh/2, hw, hh, self),
        ["down"] = Hitbox(hx, hy + hh/2, hw, hh, self)
    }
end

function Player:interact()
    local col = self.interact_collider[self.facing]

    for _,obj in ipairs(self.world.children) do
        if obj.onInteract and obj:collidesWith(col) and obj:onInteract(self, self.facing) then
            return true
        end
    end

    return false
end

return Player