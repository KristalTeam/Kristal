---@class OverworldSoul : Object
---@overload fun(...) : OverworldSoul
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

    self.debug_rect = {-8, -8, 16, 16}

    self.collider = CircleCollider(self, 0, 0, 8)

    self.inv_timer = 0
    self.inv_flash_timer = 0

    self.target_lerp = 0
end

function OverworldSoul:canDebugSelect()
    return self.alpha > 0 and super.canDebugSelect(self)
end

function OverworldSoul:onCollide(bullet)
    -- Handles damage
    bullet:onCollide(self)
end

function OverworldSoul:onAdd(parent)
    super.onAdd(self, parent)
    if parent:includes(World) then
        self.world = parent
    end
end

function OverworldSoul:onRemove(parent)
    super.onRemove(self, parent)
    if self.world == parent then
        self.world = nil
    end
end

function OverworldSoul:update()
    -- Bullet collision !!! Yay
    if self.inv_timer > 0 then
        self.inv_timer = Utils.approach(self.inv_timer, 0, DT)
    end

    self.sprite.alpha = 1 -- ??????

    Object.startCache()
    for _,bullet in ipairs(Game.stage:getObjects(WorldBullet)) do
        if bullet:collidesWith(self.collider) then
            self:onCollide(bullet)
        end
    end
    Object.endCache()

    if self.inv_timer > 0 then
        self.inv_flash_timer = self.inv_flash_timer + DT
        local amt = math.floor(self.inv_flash_timer / (4/30))
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
        local soul_character = self.world:getPartyCharacterInParty(soul_party)
        if soul_character then
            sx, sy = soul_character:getRelativePos(soul_character.actor:getSoulOffset())
        end
    end

    local tx, ty = sx, sy

    if self.world.player and self.world.player.battle_alpha > 0 then
        tx, ty = self.world.player:getRelativePos(self.world.player.actor:getSoulOffset())
        progress = self.world.player.battle_alpha * 2
    end

    self.x = Utils.lerp(sx, tx, progress * 1.5)
    self.y = Utils.lerp(sy, ty, progress * 1.5)
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