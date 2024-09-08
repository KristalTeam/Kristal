--- The class that all World bullets in Kristal originate from. \
--- Generic bullets can be spawned into the world with `Game.world:spawnBullet(texture, x, y)` \
--- Files in `scripts/world/bullets` will also be loaded as world bullets and should Extend this class.
--- Extension bullets can be spawned into the world with `Game.world:spawnBullet(id, ...)` - their `id` defaults to their filepath, starting from `scripts/world/bullets`. Additional arguments `...` are passed into the bullet type's init function.
---
---@class WorldBullet : Object
---@overload fun(...) : WorldBullet
---
---@field world             World           The current World instance. Not defined until after `WorldBullet:init()`, and only if it is parented to a World instance.
---
---@field collider          Collider|nil
---
---@field damage            number
---@field inv_timer         number
---@field destroy_on_hit    boolean
---
---@field battle_fade       boolean
---
---@field remove_offscreen  boolean
---
local WorldBullet, super = Class(Object)

---@param x         number
---@param y         number
---@param texture?  string|love.Image
function WorldBullet:init(x, y, texture)
    super.init(self, x, y)

    -- Set scale and origin
    self:setOrigin(0.5, 0.5)
    self:setScale(2, 2)

    -- Add a sprite, if we provide one
    if texture then
        self:setSprite(texture, 0.25, true)
    end

    -- Default collider to half this object's size
    self.collider = Hitbox(self, self.width/4, self.height/4, self.width/2, self.height/2)

    -- Damage given to the player when hit by this bullet (Defaults to `10`)
    self.damage = 10
    -- Invulnerability timer to apply to the player when hit by this bullet (Defaults to 4/3 seconds)
    self.inv_timer = (4/3)
    -- Whether this bullet gets removed on collision with the player (Defaults to `false`)
    self.destroy_on_hit = false

    -- Whether this bullet gets faded in/out by the battle state (Defaults to `true`)
    self.battle_fade = true

    -- Whether to remove this bullet when it goes offscreen (Defaults to `true`)
    self.remove_offscreen = true
end

function WorldBullet:getDebugInfo()
    local info = super.getDebugInfo(self)
    table.insert(info, "Damage: " .. self.damage)
    table.insert(info, "Destroy on hit: " .. (self.destroy_on_hit and "True" or "False"))
    table.insert(info, "Fade with battles: " .. (self.battle_fade and "True" or "False"))
    table.insert(info, "Remove when offscreen: " .. (self.remove_offscreen and "True" or "False"))
    return info
end

---@return number
function WorldBullet:getDamage()
    return self.damage
end


--- *(Override)* Called when the bullet hits the player's soul without invulnerability frames. \
--- Not calling `super:onDamage()` here will stop the normal damage logic from occurring.
---@param soul Soul
function WorldBullet:onDamage(soul)
    if self:getDamage() > 0 then
        self.world:hurtParty(self.damage)

        soul.inv_timer = self.inv_timer
    end
end

--- *(Override)* Called when the bullet collides with the player's soul, before invulnerability checks.
---@param soul Soul
function WorldBullet:onCollide(soul)
    if not self.world:inBattle() then return end

    if soul.inv_timer == 0 then
        self:onDamage(soul)
    end

    if self.destroy_on_hit then
        self:remove()
    end
end

---@param texture?      string|love.Image   The new texture or path to the texture to set on the sprite (Removes the bullet's sprite if undefined) 
---@param speed?        number              The time between frames of the sprite, in seconds (Defaults to 1/30th second)
---@param loop?         boolean             Whether the sprite should continuously loop. (Defaults to `true`)
---@param on_finished?  fun(Sprite)         A function that is called when the animation finishes.
---@return Sprite?
function WorldBullet:setSprite(texture, speed, loop, on_finished)
    if self.sprite then
        self:removeChild(self.sprite)
    end
    if texture then
        self.sprite = Sprite(texture)
        self.sprite.inherit_color = true
        self:addChild(self.sprite)

        if speed then
            self.sprite:play(speed, loop, on_finished)
        end

        self.width = self.sprite.width
        self.height = self.sprite.height

        return self.sprite
    end
end

--- Checks whether this bullet is an instance or extension of a specific bullet type, specified by `id`.
---@param id string
---@return boolean
function WorldBullet:isBullet(id)
    return self:includes(Registry.getBullet(id))
end

function WorldBullet:onAdd(parent)
    super.onAdd(self, parent)
    if parent:includes(World) then
        self.world = parent
    end
end

function WorldBullet:onRemove(parent)
    super.onRemove(self, parent)
    if self.world == parent then
        self.world = nil
    end
end

function WorldBullet:update()
    super.update(self)

    if self.remove_offscreen then
        local mw, mh = self.world.map.width * self.world.map.tile_width, self.world.map.height * self.world.map.tile_height
        if self.x < -100 or self.y < -100 or self.x > mw + 100 or self.y > mh + 100 then
            self:remove()
        end
    end
end

function WorldBullet:getDrawColor()
    local r, g, b, a = super.getDrawColor(self)
    if self.battle_fade then
        return r, g, b, a * self.world.battle_alpha
    else
        return r, g, b, a
    end
end

function WorldBullet:draw()
    super.draw(self)

    if DEBUG_RENDER and self.collider then
        self.collider:draw(1, 0, 0)
    end
end

return WorldBullet