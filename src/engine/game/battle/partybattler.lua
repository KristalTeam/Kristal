local PartyBattler, super = Class(Battler)

function PartyBattler:init(chara, x, y)
    self.chara = chara
    self.actor = Registry.getActor(chara.actor)

    super:init(self, x, y, self.actor.width, self.actor.height)

    self.sprite = ActorSprite(self.actor)
    self.sprite.facing = "right"

    self.overlay_sprite = ActorSprite(self.actor)
    self.overlay_sprite.facing = "right"
    self.overlay_sprite.visible = false

    self:addChild(self.sprite)
    self:addChild(self.overlay_sprite)

    -- default to the idle animation, handle the battle intro elsewhere
    self:setAnimation("battle/idle")

    self.defending = false
    self.hurt_bump_timer = 0

    self.is_down = false
end

function PartyBattler:hurt(amount, exact)
    Assets.playSound("snd_hurt1")

    if not exact then
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

        amount = Utils.round(amount)

        if self.defending then
            amount = math.ceil((2 * amount) / 3)
        end
        if amount < 1 then
            amount = 1
        end
    end

    if (self.chara.health <= 0) then
        amount = Utils.round(amount / 4)
        self.chara.health = self.chara.health - amount
    else
        self.chara.health = self.chara.health - amount
        if (self.chara.health <= 0) then
            amount = math.abs((self.chara.health - (self.chara.stats.health / 2)))
            self.chara.health = Utils.round(((-self.chara.stats.health) / 2))
            --scr_dead(target)
            self:down()
        end
    end

    if (self.chara.health <= 0) then
        self:statusMessage("msg", "down", nil, true)
    else
        self:statusMessage("damage", amount, nil, true)
    end

    self.sprite.x = -10
    self.hurt_bump_timer = 4
    Game.battle.shake = 4

    if (not self.defending) and (not self.is_down) then
        self:toggleOverlay(true)
        self.overlay_sprite:setAnimation("battle/hurt", function() self:toggleOverlay(false) end)
    end
end

function PartyBattler:down()
    self.is_down = true
    self:toggleOverlay(true)
    self.overlay_sprite:setAnimation("battle/defeat")
    Game.battle:checkGameOver()
end

function PartyBattler:revive()
    self.is_down = false
    self:toggleOverlay(false)
end

function PartyBattler:flash()
    super:flash(self, self.overlay_sprite.visible and self.overlay_sprite or self.sprite)
end

function PartyBattler:heal(amount)
    Assets.stopAndPlaySound("snd_power")

    self.chara.health = self.chara.health + amount

    if (self.is_down) and self.chara.health >= 0 then
        self:revive()
    end

    self:flash()

    if self.chara.health > self.chara.stats.health then
        self.chara.health = self.chara.stats.health
        self:statusMessage("msg", "max")
    else
        self:statusMessage("heal", amount, {0, 1, 0})
    end

    self:sparkle()
end

function PartyBattler:statusMessage(...)
    local message = super:statusMessage(self, 0, self.height/2, ...)
    message.y = message.y - 4
end


function PartyBattler:toggleOverlay(overlay)
    if overlay == nil then
        overlay = self.sprite.visible
    end
    self.overlay_sprite.visible = overlay
    self.sprite.visible = not overlay
end

function PartyBattler:setActSprite(sprite, ox, oy, speed, loop, after)

    self:setCustomSprite(sprite, ox, oy, speed, loop, after)

    local x = self.x - (self.actor.width/2 + ox) * 2
    local y = self.y - (self.actor.height + oy) * 2
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

function PartyBattler:update(dt)
    if self.hurt_bump_timer > 0 then
        self.sprite.x = -self.hurt_bump_timer * 2
        self.hurt_bump_timer = Utils.approach(self.hurt_bump_timer, 0, DTMULT)
    else
        self.sprite.x = 0
    end

    super:update(self, dt)
end

return PartyBattler