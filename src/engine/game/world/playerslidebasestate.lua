---@class PlayerSlideBaseState : StateClass
---
---@field player Player
---
---@overload fun(player: Player) : PlayerSlideBaseState
local PlayerSlideBaseState, super = Class(StateClass)

function PlayerSlideBaseState:init(player)
    self.player = player

    self.slide_sound = Assets.newSound("paper_surf")
    self.slide_sound:setLooping(true)

    self.dust_timer = 0

    self.was_colliding = false
end

function PlayerSlideBaseState:registerEvents()
    self:registerEvent("enter", self.onEnter)
    self:registerEvent("update", self.onUpdate)
    self:registerEvent("leave", self.onExit)
    self:registerEvent("remove", self.onRemove)
end

-------------------------------------------------------------------------------
-- Callbacks
-------------------------------------------------------------------------------

function PlayerSlideBaseState:onEnter(old_state)
    self.slide_sound:play()
    self.player:setFacing("down")
    self.player.sprite:setAnimation("slide")
    self.player.auto_moving = true
end

function PlayerSlideBaseState:updateDust()
    self.dust_timer = self.dust_timer - DTMULT

    if self.dust_timer <= 0 then
        self.dust_timer = self.dust_timer + 3

        local dust = Sprite("effects/slide_dust")
        dust:play(1 / 15, false, function() dust:remove() end)
        dust:setOrigin(0.5, 0.5)
        dust:setScale(2, 2)
        dust:setPosition(self.player.x, self.player.y)
        dust.layer = self.player.layer - 0.01
        dust.physics.speed_y = -6
        dust.physics.speed_x = MathUtils.random(-1, 1)
        dust.debug_select = false
        self.player.world:addChild(dust)
    end
end

function PlayerSlideBaseState:onSlideEnd()
    self.player:setState("WALK")
end

function PlayerSlideBaseState:handleMovement()
    self.player:move(0, 2, 6 * DTMULT)
end

function PlayerSlideBaseState:checkSlideEnd()
    if self.player.last_collided_y then
        self:onSlideEnd()
    end

    local is_colliding = false

    Object.startCache()
    for _, obj in ipairs(Game.world.children) do
        if obj:includes(SlideArea) and obj:collidesWith(self.player) then
            is_colliding = true
            self.was_colliding = true
            break
        end
    end

    Object.endCache()

    if not is_colliding and self.was_colliding then
        self:onSlideEnd()
    end
end

function PlayerSlideBaseState:onUpdate()
    self:handleMovement()
    self:updateDust()
    self:checkSlideEnd()
end

function PlayerSlideBaseState:onExit(next_state)
    self.player:resetSprite()
    self.slide_sound:stop()

    self.player.auto_moving = false
end

function PlayerSlideBaseState:onRemove()
    self.slide_sound:stop()
end

return PlayerSlideBaseState
