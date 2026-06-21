--- A ClimbEnemy is a type of WorldBullet which can be damaged by the player when they jump into it while climbing.
---
---@class ClimbEnemy : WorldBullet
---
---@overload fun(x?: number, y?: number, texture?: string|love.Image) : ClimbEnemy
local ClimbEnemy, super = Class(WorldBullet)

function ClimbEnemy:init(x, y, texture)
    super.init(self, x, y, texture)

    self.destroy_on_hit = false
    self.battle_fade = false
    self.remove_offscreen = false

    self.is_active = true

    self.health = 1
    self.timer = 0

    self.state = 0 -- 0 = idle, 1 = hit, 2 = dying
end

--- *(Override)* Whether or not this enemy can be interacted with by the player.
---@return boolean
function ClimbEnemy:isActive()
    return self.is_active
end

--- *(Override)* Called when the player jumps into this bullet while climbing.
---@param player Player
function ClimbEnemy:onJumpAttack(player)
    self.is_active = false
    self.timer = 0

    self:spawnAttackEffects()
    self:playAttackSounds()

    self:shake(10, 0, 2)

    self:hurt(1, player)
end

--- Hurts this climb enemy for a certain amount.
---@param amount number The amount of damage to deal to this climb enemy.
---@param player Player The player that is dealing the damage, used for knockback.
function ClimbEnemy:hurt(amount, player)
    self.health = self.health - amount
    if self.health > 0 then
        player:climbFall(20)
        self.state = 1
    else
        self.state = 2
    end
end

function ClimbEnemy:update()
    super.update(self)

    if self.state == 1 then
        self.timer = self.timer + DTMULT
        if self.timer >= 16 then
            self.state = 0
            self.timer = 0
            self.is_active = true
        end
    elseif self.state == 2 then
        self.timer = self.timer + DTMULT

        if self.timer >= 8 then
            self:onDeath()
        end
    end
end

--- Spawns effects when this enemy is attacked.
function ClimbEnemy:spawnAttackEffects()
    local sprite = self.parent:addChild(Sprite("effects/attack/cut", self.x, self.y))
    sprite.layer = self.layer + 0.1
    sprite:setScale(2)
    sprite:setOrigin(0.5, 0.5)
    sprite:play(1 / 30, false, function(spr) spr:remove() end)

    local fade = self.parent:addChild(FlashFade(self.sprite.texture, self.x, self.y))
    fade.layer = self.layer + 0.05
    fade:setScale(self:getScale())
    fade:setOrigin(self:getOrigin())
end

--- Plays sounds when this enemy is attacked.
function ClimbEnemy:playAttackSounds()
    Assets.playSound("swing", 0.4, 1.2)
    Assets.playSound("laz_c", 0.3, 1.2)
end

--- Spawns effects when this enemy dies.
function ClimbEnemy:spawnDeathEffects()
    -- Attack animation
    local sprite = self.parent:addChild(Sprite("effects/attack/slap_n", self.x, self.y))
    sprite.layer = self.layer + 0.1
    sprite:setScale(2)
    sprite:setOrigin(0.5)
    sprite:play(1 / 15, false, function(spr) spr:remove() end)

    -- Attack animation backdrop
    sprite = self.parent:addChild(Sprite("effects/attack/slap_n", self.x, self.y))
    sprite.layer = self.layer + 0.05
    sprite:setScale(3)
    sprite:setOrigin(0.5)
    sprite:play(1 / 15, false, function(spr) spr:remove() end)
    sprite:setColor(0, 0, 0, 1)

    -- The afterimage
    sprite = self.parent:addChild(Sprite("effects/attack/slap_n", self.x, self.y))
    sprite.layer = self.layer + 0.05
    sprite:setScale(3)
    sprite:setOrigin(0.5)
    sprite:fadeOutSpeedAndRemove(0.04)
    sprite:setColor(0, 0, 0, 1)

    -- The cut sprite
    local cut = self.parent:addChild(SpriteCutHalf(self.sprite.texture, self.x, self.y))
    cut.layer = self.layer + 0.05
    cut:setScale(self:getScale())
    cut:setOrigin(self:getOrigin())
end

--- Plays sounds when this enemy dies.
function ClimbEnemy:playDeathSounds()
    Assets.playSound("swing", 1, 0.5)
    Assets.playSound("damage", 0.5, 0.5)
    Assets.playSound("punchmed", 0.4, 1)
end

--- Called when this enemy dies. By default, it spawns death effects, plays sounds, and removes itself.
function ClimbEnemy:onDeath()
    self:spawnDeathEffects()
    self:playDeathSounds()

    self:remove()
end

return ClimbEnemy
