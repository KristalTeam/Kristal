---@class Bullet : Object
---@overload fun(...) : Bullet
---
---@field attacker          EnemyBattler    The attacker that owns the wave which created this bullet.
---@field wave              Wave            The wave that this bullet was created by.
---
---@field tp                number
---@field time_bonus        number
---
---@field damage            number
---@field inv_timer         number
---@field destroy_on_hit    boolean
---
---@field grazed            boolean
---
---@field remove_offscreen  boolean
---
local Bullet, super = Class(Object)

function Bullet:init(x, y, texture)
    super.init(self, x, y)

    self.layer = BATTLE_LAYERS["bullets"]

    -- Set scale and origin
    self:setOrigin(0.5, 0.5)
    self:setScale(2, 2)

    -- Add a sprite, if we provide one
    if texture then
        self:setSprite(texture, 0.25, true)
    end

    -- Default collider to half this object's size
    self.collider = Hitbox(self, self.width/4, self.height/4, self.width/2, self.height/2)

    -- TP added when you graze this bullet (Also given each frame after the first graze, 30x less at 30FPS)
    self.tp = 1.6 -- (1/10 of a defend, or cheap spell)
    -- Turn time reduced when you graze this bullet (Also applied each frame after the first graze, 30x less at 30FPS)
    self.time_bonus = 1

    -- Damage given to the player when hit by this bullet (defaults to 5x the attacker's attack stat)
    self.damage = nil
    -- Invulnerability timer to apply to the player when hit by this bullet
    self.inv_timer = (4/3)
    -- Whether this bullet gets removed on collision with the player
    self.destroy_on_hit = true

    -- Whether this bullet has already been grazed (reduces graze rewards)
    self.grazed = false

    -- Whether to remove this bullet when it goes offscreen
    self.remove_offscreen = true
end

---@return string
function Bullet:getTarget()
    return self.attacker and self.attacker.current_target or "ANY"
end

---@return number
function Bullet:getDamage()
    return self.damage or (self.attacker and self.attacker.attack * 5) or 0
end

--- *(Override)* Called when the bullet hits the player's soul without invulnerability frames. \
--- This function is where the damage of the hit is dealt, so by not calling super:onDamage(), or only under certain conditions, custom hit and damage logic can be implemented.
---@param soul Soul
---@return table<PartyBattler> battlers_hit
function Bullet:onDamage(soul)
    local damage = self:getDamage()
    if damage > 0 then
        local battlers = Game.battle:hurt(damage, false, self:getTarget())
        soul.inv_timer = self.inv_timer
        soul:onDamage(self, damage)
        return battlers
    end
    return {}
end

--- *(Override)* Called when the bullet collides with the player's soul, before invulnerability checks.
---@param soul Soul
function Bullet:onCollide(soul)
    if soul.inv_timer == 0 then
        self:onDamage(soul)
    end

    if self.destroy_on_hit then
        self:remove()
    end
end

---@param wave Wave
function Bullet:onWaveSpawn(wave) end

---@param texture string|love.Image The path to the new texture to set on the sprite. 
---@param speed number              The time between frames of the sprite, in seconds. Defaults to 1/30th second.
---@param loop boolean
---@param on_finished fun()
---@return Sprite?
function Bullet:setSprite(texture, speed, loop, on_finished)
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

--- Checks whether this bullet is an instance of a specific bullet type, specified by `id`.
---@param id string
---@return boolean
function Bullet:isBullet(id)
    return self:includes(Registry.getBullet(id))
end

function Bullet:update()
    super.update(self)

    if self.remove_offscreen then
        if self.x < -100 or self.y < -100 or self.x > SCREEN_WIDTH + 100 or self.y > SCREEN_HEIGHT + 100 then
            self:remove()
        end
    end
end

function Bullet:draw()
    super.draw(self)

    if DEBUG_RENDER and self.collider then
        self.collider:drawFor(self, 1, 0, 0)
    end
end

return Bullet