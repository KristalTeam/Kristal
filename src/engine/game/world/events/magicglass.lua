--- Magical glass are Overworld objects that appear only when stepped on. \
--- `MagicGlass` is an [`Event`](lua://Event.init) - naming an object `magicglass` on an `objects` layer in a map creates this object.
---@class MagicGlass : Event
---
---@field texture           love.Image
---@field tiles_x           integer
---@field tiles_y           integer
---
---@field glass_colliders   Collider[]
---@field tile_alphas       number[]
---
---@field collider          Hitbox
---
---@overload fun(...) : MagicGlass
local MagicGlass, super = Class(Event)

---@param x number
---@param y number
---@param shape EventShape
---@param properties table
function MagicGlass:init(x, y, shape, properties)
    super.init(self, x, y, shape)

    properties = properties or {}

    self.texture = Assets.getTexture(properties["new_sprite"] and "world/events/magical_glass_new" or "world/events/magical_glass")

    self.tiles_x = math.floor(self.width / 40)
    self.tiles_y = math.floor(self.height / 40)

    self.glass_colliders = {}
    self.tile_alphas = {}

    for i = 1, self.tiles_x do
        for j = 1, self.tiles_y do
            local hitbox = Hitbox(self, (i - 1) * 40, (j - 1) * 40, 40, 40)
            table.insert(self.glass_colliders, hitbox)
            table.insert(self.tile_alphas, 0)
        end
    end

    self.collider = Hitbox(self, 0, 0, self.width, self.height)
end

--- Updates the alpha of a magic glass tile based on whether it is colliding with any objects.
---@param index integer # The index of the magic glass tile being updated.
---@param colliding Object[] # A list of objects currently colliding with this magic glass tile.
function MagicGlass:updateGlassAlpha(index, colliding)
    if #colliding > 0 then
        self.tile_alphas[index] = 1
    else
        self.tile_alphas[index] = MathUtils.clamp(MathUtils.lerp(self.tile_alphas[index], 0, 0.125 * DTMULT), 0, 1)
    end
end

--- Gets a list of all objects in the stage that should reveal magic glass on collision.
---@return Object[] # A list of objects that should reveal magic glass on collision.
function MagicGlass:getGlassRevealingObjects()
    return Game.stage:getObjects(Character)
end

function MagicGlass:update()
    Object.startCache()

    local valid_objs = {}

    for _, obj in ipairs(self:getGlassRevealingObjects()) do
        if obj:collidesWith(self.collider) then
            table.insert(valid_objs, obj)
        end
    end

    local collided = {}

    for i, collider in ipairs(self.glass_colliders) do
        for _, obj in ipairs(valid_objs) do
            if collider:collidesWith(obj) then
                table.insert(collided, obj)
            end
        end

        self:updateGlassAlpha(i, collided)

        if #collided > 0 then
            collided = {}
        end
    end

    Object.endCache()

    super.update(self)
end

function MagicGlass:draw()
    local r, g, b, a = self:getDrawColor()

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
