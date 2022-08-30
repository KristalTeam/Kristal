local PartyBattler, super = Class(Battler)

function PartyBattler:init(chara, x, y)
    self.chara = chara
    self.actor = chara:getActor()

    super:init(self, x, y, self.actor:getSize())

    self.sprite = self.actor:createSprite()
    self.sprite.facing = "right"

    self.overlay_sprite = self.actor:createSprite()
    self.overlay_sprite.facing = "right"
    self.overlay_sprite.visible = false

    self:addChild(self.sprite)
    self:addChild(self.overlay_sprite)

    -- default to the idle animation, handle the battle intro elsewhere
    self:setAnimation("battle/idle")

    self.action = nil

    self.defending = false
    self.hurt_timer = 0
    self.hurting = false

    self.is_down = false
    self.sleeping = false

    self.should_darken = false
    self.darken_timer = 0
    self.darken_fx = self:addFX(RecolorFX())

    self.target_sprite = Sprite("ui/battle/chartarget")
    self.target_sprite:play(10/30)
    self:addChild(self.target_sprite)

    self.targeted = false
end

function PartyBattler:canTarget()
    return (not self.is_down)
end

function PartyBattler:calculateDamage(amount)
    local def = self.chara:getStat("defense")
    local max_hp = self.chara:getStat("health")

    local threshold_a = (max_hp / 5)
    local threshold_b = (max_hp / 8)
    for i = 1, def do
        if amount > threshold_a then
            amount = amount - 3
        elseif amount > threshold_b then
            amount = amount - 2
        else
            amount = amount - 1
        end
    end

    return math.max(amount, 1)
end

function PartyBattler:calculateDamageSimple(amount)
    return math.ceil(amount - (self.chara:getStat("defense") * 3))
end

function PartyBattler:getElementReduction(element)
    -- TODO: this

    if (element == 0) then return 1 end

    -- dummy values since we don't have elements
    local armor_elements = {
        {element = 0, element_reduce_amount = 0},
        {element = 0, element_reduce_amount = 0}
    }

    local reduction = 1
    for i = 1, 2 do
        local item = armor_elements[i]
        if (item.element ~= 0) then
            if (item.element == element)                              then reduction = reduction - item.element_reduce_amount end
            if (item.element == 9 and (element == 2 or element == 8)) then reduction = reduction - item.element_reduce_amount end
            if (item.element == 10)                                   then reduction = reduction - item.element_reduce_amount end
        end
    end
    return math.max(0.25, reduction)
end

function PartyBattler:hurt(amount, exact, color, options)
    options = options or {}

    if not options["all"] then
        Assets.playSound("hurt")
        if not exact then
            amount = self:calculateDamage(amount)
            if self.defending then
                amount = math.ceil((2 * amount) / 3)
            end
            -- we don't have elements right now
            local element = 0
            amount = math.ceil((amount * self:getElementReduction(element)))
        end

        self:removeHealth(amount)
    else
        -- We're targeting everyone.
        if not exact then
            amount = self:calculateDamage(amount)
            -- we don't have elements right now
            local element = 0
            amount = math.ceil((amount * self:getElementReduction(element)))

            if self.defending then
                amount = math.ceil((3 * amount) / 4) -- Slightly different than the above
            end

            self:removeHealthBroken(amount) -- Use a separate function for cleanliness
        end
    end

    if (self.chara.health <= 0) then
        self:statusMessage("msg", "down", color, true)
    else
        self:statusMessage("damage", amount, color, true)
    end

    self.sprite.x = -10
    self.hurt_timer = 4
    Game.battle:shakeCamera(4)

    if (not self.defending) and (not self.is_down) then
        self.sleeping = false
        self.hurting = true
        self:toggleOverlay(true)
        self.overlay_sprite:setAnimation("battle/hurt", function()
            self.hurting = false
            self:toggleOverlay(false)
        end)
        if not self.overlay_sprite.anim_frames then -- backup if the ID doesn't animate, so it doesn't get stuck with the hurt animation
            Game.battle.timer:after(0.5, function()
                self.hurting = false
                self:toggleOverlay(false)
            end)
        end
    end
end

function PartyBattler:removeHealth(amount)
    if (self.chara.health <= 0) then
        amount = Utils.round(amount / 4)
        self.chara.health = self.chara.health - amount
    else
        self.chara.health = self.chara.health - amount
        if (self.chara.health <= 0) then
            amount = math.abs((self.chara.health - (self.chara:getStat("health") / 2)))
            self.chara.health = Utils.round(((-self.chara:getStat("health")) / 2))
        end
    end
    self:checkHealth()
end

function PartyBattler:removeHealthBroken(amount)
    self.chara.health = self.chara.health - amount
    if (self.chara.health <= 0) then
        -- BUG: Use Kris' max health...
        self.chara.health = Utils.round(((-Game.party[1]:getStat("health")) / 2))
    end
    self:checkHealth()
end

function PartyBattler:down()
    self.is_down = true
    self.sleeping = false
    self:toggleOverlay(true)
    self.overlay_sprite:setAnimation("battle/defeat")
    if self.action then
        Game.battle:removeAction(Game.battle:getPartyIndex(self.chara.id))
    end
    Game.battle:checkGameOver()
end

function PartyBattler:setSleeping(sleeping)
    if self.sleeping == (sleeping or false) then return end

    if sleeping then
        if self.is_down then return end
        self.sleeping = true
        self:toggleOverlay(true)
        if not self.overlay_sprite:setAnimation("battle/sleep") then
            self.overlay_sprite:setAnimation("battle/defeat")
        end
        if self.action then
            Game.battle:removeAction(Game.battle:getPartyIndex(self.chara.id))
        end
    else
        self.sleeping = false
        self:toggleOverlay(false)
    end
end

function PartyBattler:revive()
    self.is_down = false
    self:toggleOverlay(false)
end

function PartyBattler:flash()
    super:flash(self, self.overlay_sprite.visible and self.overlay_sprite or self.sprite)
end

function PartyBattler:heal(amount, sparkle_color, show_up)
    Assets.stopAndPlaySound("power")

    amount = math.floor(amount)

    self.chara.health = self.chara.health + amount

    local was_down = self.is_down
    self:checkHealth()

    self:flash()

    if self.chara.health >= self.chara:getStat("health") then
        self.chara.health = self.chara:getStat("health")
        self:statusMessage("msg", "max")
    else
        if show_up then
            if was_down ~= self.is_down then
                self:statusMessage("msg", "up")
            end
        else
            self:statusMessage("heal", amount, {0, 1, 0})
        end
    end

    self:sparkle(unpack(sparkle_color or {}))
end

function PartyBattler:checkHealth()
    if (not self.is_down) and self.chara.health <= 0 then
        self:down()
    elseif (self.is_down) and self.chara.health > 0 then
        self:revive()
    end
end

function PartyBattler:statusMessage(...)
    local message = super:statusMessage(self, 0, self.height/2, ...)
    message.y = message.y - 4
end

function PartyBattler:isActive()
    return not self.is_down and not self.sleeping
end

function PartyBattler:isTargeted()
    return self.targeted
end

function PartyBattler:getHeadIcon()
    if self.sleeping then
        return "sleep"
    elseif self.defending then
        return "defend"
    elseif self.action and self.action.icon then
        return self.action.icon
    elseif self.hurting then
        return "head_hurt"
    else
        return "head"
    end
end

function PartyBattler:toggleOverlay(overlay)
    if overlay == nil then
        overlay = self.sprite.visible
    end
    self.overlay_sprite.visible = overlay
    self.sprite.visible = not overlay
end

function PartyBattler:resetSprite()
    self:setAnimation("battle/idle")
end

function PartyBattler:setActSprite(sprite, ox, oy, speed, loop, after)

    self:setCustomSprite(sprite, ox, oy, speed, loop, after)

    local x = self.x - (self.actor:getWidth()/2 - ox) * 2
    local y = self.y - (self.actor:getHeight() - oy) * 2
    local flash = FlashFade(sprite, x, y)
    flash:setOrigin(0, 0)
    flash:setScale(self:getScale())
    self.parent:addChild(flash)

    local afterimage1 = AfterImage(self, 0.5)
    local afterimage2 = AfterImage(self, 0.6)
    afterimage1.physics.speed_x = 2.5
    afterimage2.physics.speed_x = 5

    afterimage2.layer = afterimage1.layer - 1

    self:addChild(afterimage1)
    self:addChild(afterimage2)
end

function PartyBattler:setSprite(sprite, speed, loop, after)
    self.sprite:setSprite(sprite)
    if not self.sprite.directional and speed then
        self.sprite:play(speed, loop, after)
    end
end

function PartyBattler:update()
    if self.actor then
        self.actor:onBattleUpdate(self)
    end

    if self.chara:getWeapon() then
        self.chara:getWeapon():onBattleUpdate(self)
    end
    for i = 1, 2 do
        if self.chara:getArmor(i) then
            self.chara:getArmor(i):onBattleUpdate(self)
        end
    end

    if self.hurt_timer > 0 then
        self.sprite.x = -self.hurt_timer * 2
        self.hurt_timer = Utils.approach(self.hurt_timer, 0, DTMULT)
    else
        self.sprite.x = 0
    end

    self.target_sprite.visible = false
    if self:isTargeted() then
        if (Game:getConfig("targetSystem")) and (Game.battle.state == "ENEMYDIALOGUE") then
            self.target_sprite.visible = true
        end
    elseif self.should_darken then
        if (self.darken_timer < 15) then
            self.darken_timer = self.darken_timer + DTMULT
        end
    else
        if not self.should_darken then
            if self.darken_timer > 0 then
                self.darken_timer = self.darken_timer - (3 * DTMULT)
            end
        end
    end

    self.darken_fx.color = {1 - (self.darken_timer / 30), 1 - (self.darken_timer / 30), 1 - (self.darken_timer / 30)}

    super:update(self)
end

function PartyBattler:draw()
    super:draw(self)
    if self.actor then
        self.actor:onBattleDraw(self)
    end
end

return PartyBattler