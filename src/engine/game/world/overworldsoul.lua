--- The soul of the player used when in the Overworld. \
--- The Overworld soul defines the player's hitbox against bullets in the Overworld and controls taking damage from them - as such it is only visible if inside a battle area.
---@class OverworldSoul : Object
---
---@field collider CircleCollider The hitbox of the soul, defaulting to a circle with an 8 pixel radius
---
---@overload fun(x?: number, y?: number) : OverworldSoul
local OverworldSoul, super = Class(Object)

function OverworldSoul:init(x, y)
    super.init(self, x, y)

    self:setColor(1, 0, 0)

    self.alpha = 0

    --self.layer = BATTLE_LAYERS["soul"]

    self.sprite = Sprite("player/heart_dodge")
    self.sprite:setOrigin(0.5, 0.5)
    self.sprite.alpha = 0 -- ??????
    self.sprite.inherit_color = true
    self:addChild(self.sprite)

    self.debug_rect = { -8, -8, 16, 16 }

    self.collider = CircleCollider(self, 0, 0, 8)

    self.inv_timer = 0
    self.inv_flash_timer = 0

    self.target_lerp = 0
end

function OverworldSoul:canDebugSelect()
    return self.alpha > 0 and super.canDebugSelect(self)
end

--- *(Override)* Called whenever a bullet hits the soul \
--- *By default, calls `bullet:onCollide()` which handles the soul taking damage*
---@param bullet WorldBullet
function OverworldSoul:onCollide(bullet)
    -- Handles damage
    bullet:onCollide(self)
end

function OverworldSoul:update()
    -- Bullet collision !!! Yay
    if self.inv_timer > 0 then
        self.inv_timer = MathUtils.approach(self.inv_timer, 0, DT)
    end

    self.sprite.alpha = 1 -- ??????

    Object.startCache()
    for _, bullet in ipairs(Game.stage:getObjects(WorldBullet)) do
        if bullet:collidesWith(self.collider) then
            self:onCollide(bullet)
        end
    end
    Object.endCache()

    if self.inv_timer > 0 then
        self.inv_flash_timer = self.inv_flash_timer + DT
        local amt = math.floor(self.inv_flash_timer / (4 / 30))
        if (amt % 2) == 1 then
            self.sprite:setColor(0.5, 0.5, 0.5)
        else
            self.sprite:setColor(1, 1, 1)
        end
    else
        self.inv_flash_timer = 0
        self.sprite:setColor(1, 1, 1)
    end

    local sx, sy = self.x, self.y
    local progress = 0

    local soul_party = Game:getSoulPartyMember()
    if soul_party then
        local soul_character = Game.world:getPartyCharacterInParty(soul_party)
        if soul_character then
            sx, sy = soul_character:getRelativePos(soul_character.actor:getSoulOffset())
        end
    end

    local tx, ty = sx, sy

    if Game.world.player and Game.world.player.battle_alpha > 0 then
        tx, ty = Game.world.player:getRelativePos(Game.world.player.actor:getSoulOffset())
        progress = Game.world.player.battle_alpha * 2
    end

    self.x = MathUtils.lerp(sx, tx, progress * 1.5)
    self.y = MathUtils.lerp(sy, ty, progress * 1.5)
    self.alpha = progress

    super.update(self)
end

function OverworldSoul:draw()
    super.draw(self)

    if DEBUG_RENDER then
        self.collider:draw(0, 1, 0)
    end
end

return OverworldSoul
