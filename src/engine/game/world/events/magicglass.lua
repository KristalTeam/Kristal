---@class MagicGlass : Event
---@overload fun(...) : MagicGlass
local MagicGlass, super = Class(Event)

function MagicGlass:init(x, y, w, h)
    super.init(self, x, y, w, h)

    self.texture = Assets.getTexture("world/events/magical_glass")

    self.tiles_x = math.floor(self.width/40)
    self.tiles_y = math.floor(self.height/40)

    self.glass_colliders = {}
    self.tile_alphas = {}

    for i = 1, self.tiles_x do
        for j = 1, self.tiles_y do
            local hitbox = Hitbox(self, (i - 1) * 40, (j - 1) * 40, 40, 40)
            table.insert(self.glass_colliders, hitbox)
            table.insert(self.tile_alphas, 0)
        end
    end

    self.collider = ColliderGroup(self, self.glass_colliders)
end

function MagicGlass:update()
    Object.startCache()
    for i,collider in ipairs(self.glass_colliders) do
        local any_collided = false
        for _,char in ipairs(Game.stage:getObjects(Character)) do
            if collider:collidesWith(char) then
                any_collided = true
                break
            end
        end
        if any_collided then
            self.tile_alphas[i] = 1
        else
            self.tile_alphas[i] = Utils.lerp(self.tile_alphas[i], 0, 0.125 * DTMULT)
        end
    end
    Object.endCache()

    super.update(self)
end

function MagicGlass:draw()
    local r,g,b,a = self:getDrawColor()

    local id = 1
    for i = 1, self.tiles_x do
        for j = 1, self.tiles_y do
            Draw.setColor(r, g, b, a * self.tile_alphas[id])
            Draw.draw(self.texture, (i - 1) * 40, (j - 1) * 40, 0, 2, 2)
            id = id + 1
        end
    end

    super.draw(self)
end

return MagicGlass