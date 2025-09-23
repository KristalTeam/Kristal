--- `PartyBattler`s are a type of `Battler` that represent [`PartyMember`](lua://PartyMember.init)s when they are in battle. \
--- The set of `PartyBattler`s in the current battle are stored in [`Game.battle.party`](lua://Battle.party). \
--- Unlike `EnemyBattler`, party members do not need to define a `PartyBattler` in a file as their PartyMember file defines everything necessary and is utilised by `PartyBattler`.
---
---@class PartyBattler : Battler
---
---@field chara         PartyMember The PartyMember this battler uses
---@field actor         Actor       The actor this battler uses
---
---@field action        table       The current action the battler has queued up
---
---@field defending     boolean     Whether the battler is currently defending
---@field hurt_timer    number      How long this battler's hurt sprite should be displayed for when hit
---@field hurting       boolean     Whether the battler is currently hurting (showing their hurt sprite)
---
---@field is_down       boolean     Whether the battler is downed
---@field sleeping      boolean     Whether the battler is sleeping
---
---@field should_darken boolean     *(Used internally)* Whether the battler's sprite should be darkened during waves
---@field darken_timer  number      *(Used internally)* A timer for the darkening of the battler's sprite during the wave transition
---@field darken_fx     RecolorFX   *(Used internally)* A RecolorFX used for darkening the battler's sprite during waves
---
---@field target_sprite Sprite
---@overload fun(chara:PartyMember, x?:number, y?:number) : PartyBattler
local PartyBattler, super = Class(Battler)

---@param chara     PartyMember
---@param x?        number
---@param y?        number
function PartyBattler:init(chara, x, y)
    self.chara = chara
    self.actor = chara:getActor()

    super.init(self, x, y, self.actor:getSize())

    if self.actor then
        self:setActor(self.actor, true)
    end

    -- default to the idle animation, handle the battle intro elsewhere
    self:setAnimation("battle/idle")

    self.action = nil
    
    self.defending = false
    self.hurt_timer = 16
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

--- *(Override)*
---@return boolean
function PartyBattler:canTarget()
    return (not self.is_down)
end

--- Calculates the damage the battler should take after defense reductions
---@param amount number
---@return number
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
        if amount <= 0 or def == math.huge then
            amount = 0
            break
        end
    end

    return math.max(amount, 1)
end

--- Less complex damage calculation than [`PartyBattler:calculateDamage()`](lua://PartyBattler.calculateDamage) \
--- (unused?)
---@param amount number
---@return integer
function PartyBattler:calculateDamageSimple(amount)
    return math.ceil(amount - (self.chara:getStat("defense") * 3))
end

--- Gets the damage reduction multiplier for damage of a particular element
---@param element number
---@return integer multiplier
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

---@param amount    number  The damage of the incoming hit
---@param exact?    boolean Whether the damage should be treated as exact damage instead of applying defense and element modifiers
---@param color?    table   The color of the damage number
---@param options?  table   A table defining additional properties to control the way damage is taken
---|"all"   # Whether the damage being taken comes from a strike targeting the whole party
---|"swoon" # Whether the damage should swoon the battler instead of downing them
function PartyBattler:hurt(amount, exact, color, options)
    options = options or {}

    local swoon = options["swoon"]

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

        self:removeHealth(amount, swoon)
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
        end

        self:removeHealthBroken(amount, swoon) -- Use a separate function for cleanliness
    end

    if (self.chara:getHealth() <= 0) then
        self:statusMessage("msg", swoon and "swoon" or "down", color, true)
    else
        self:statusMessage("damage", amount, color, true)
    end

    self.hurt_timer = 0
    Game.battle:shakeCamera(4)

    if (not self.defending) and (not self.is_down) then
        self.sleeping = false
        self.hurting = true
        self:toggleOverlay(true)
        self.overlay_sprite:setAnimation("battle/hurt", function()
            if self.hurting then
                self.hurting = false
                self:toggleOverlay(false)
            end
        end)
        if not self.overlay_sprite.anim_frames then -- backup if the ID doesn't animate, so it doesn't get stuck with the hurt animation
            Game.battle.timer:after(0.5, function()
                if self.hurting then
                    self.hurting = false
                    self:toggleOverlay(false)
                end
            end)
        end
    end
end

--- Removes health from the character and sets their downed HP value if necessary
---@param amount number
---@param swoon boolean? Whether to swoon rather than down
function PartyBattler:removeHealth(amount, swoon)
    if (self.chara:getHealth() <= 0) then
        amount = Utils.round(amount / 4)
        self.chara:setHealth(self.chara:getHealth() - amount)
    else
        self.chara:setHealth(self.chara:getHealth() - amount)
        if (self.chara:getHealth() <= 0) then
            if swoon then
                self.chara:setHealth(-999)
            else
                amount = math.abs((self.chara:getHealth() - (self.chara:getStat("health") / 2)))
                self.chara:setHealth(Utils.round(((-self.chara:getStat("health")) / 2)))
            end
        end
    end
    self:checkHealth(swoon)
end

--- A variant of [`PartyBattler:removeHealth()`](lua://PartyBattler.removeHealth) that uses Kris' (or the first party member)'s HP for downed hp values (used for deltarune accuracy)
---@param amount number
---@param swoon boolean? Whether to swoon rather than down
function PartyBattler:removeHealthBroken(amount, swoon)
    self.chara:setHealth(self.chara:getHealth() - amount)
    if (self.chara:getHealth() <= 0) then
        if swoon then
            self.chara:setHealth(-999)
        else
            -- BUG: Use Kris' max health...
            self.chara:setHealth(Utils.round(((-Game.party[1]:getStat("health")) / 2)))
        end
    end
    self:checkHealth(swoon)
end

function PartyBattler:swoon()
    self.is_down = true
    self.sleeping = false
    self.hurting = false
    self:toggleOverlay(true)
    self.overlay_sprite:setAnimation("battle/swooned")
    if self.action then
        Game.battle:removeAction(Game.battle:getPartyIndex(self.chara.id))
    end
    Game.battle:checkGameOver()
end

function PartyBattler:down()
    self.is_down = true
    self.sleeping = false
    self.hurting = false
    self:toggleOverlay(true)
    self.overlay_sprite:setAnimation("battle/defeat")
    if self.action then
        Game.battle:removeAction(Game.battle:getPartyIndex(self.chara.id))
    end
    Game.battle:checkGameOver()
end

---@param sleeping? boolean
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

--- Makes the battler flash once.
---@param sprite    Sprite? An optional sprite to use for the flash instead of the battler's default sprite.
---@param offset_x? number
---@param offset_y? number
---@param layer?    number
---@return FlashFade
function PartyBattler:flash(sprite, offset_x, offset_y, layer)
    return super.flash(self, sprite or self.overlay_sprite.visible and self.overlay_sprite or self.sprite, offset_x, offset_y, layer)
end

--- Heals the Battler by `amount` health and does healing effects
---@param amount            number  The amount of health to restore
---@param sparkle_color?    table   The color of the heal sparkles (defaults to the standard green) or false to not show sparkles
---@param show_up?          boolean Whether the "UP" status message should show if the battler is revived by the heal
function PartyBattler:heal(amount, sparkle_color, show_up)
    Assets.stopAndPlaySound("power")

    amount = math.floor(amount)

    self.chara:setHealth(self.chara:getHealth() + amount)

    local was_down = self.is_down
    self:checkHealth(false)

    if self.chara:getHealth() >= self.chara:getStat("health") then
        self.chara:setHealth(self.chara:getStat("health"))
        self:statusMessage("msg", "max", nil, nil, 8)
    else
        if show_up and was_down ~= self.is_down then
            self:statusMessage("msg", "up", nil, nil, 1)
        else
            self:statusMessage("heal", amount, {0, 1, 0}, nil, show_up and 1 or 8)
        end
    end

    if not show_up then
        self:healEffect(unpack(sparkle_color or {}))
    end
end

--- Checks whether the battler's down state needs to be changed based on its current health
---@param swoon boolean? Whether the battler should be swooned instead of downed if their health is 0 or below
function PartyBattler:checkHealth(swoon)
    if (not self.is_down) and self.chara:getHealth() <= 0 then
        if swoon then
            self:swoon()
        else
            self:down()
        end
    elseif (self.is_down) and self.chara:getHealth() > 0 then
        self:revive()
    end
end

--- An override of [`Battler:statusMessage()`](lua://Battler.statusMessage) that positions the message for this PartyBattler
---@param ... unknown
---@return DamageNumber
function PartyBattler:statusMessage(...)
    local message = super.statusMessage(self, 0, self.height/2, ...)
    message.y = message.y - 4
    return message
end

--- An override of [`Battler:recruitMessage()`](lua://Battler.recruitMessage)
---@param ... unknown
---@return RecruitMessage
function PartyBattler:recruitMessage(...)
    return super.recruitMessage(self, ...)
end

--- Whether the party member is in a state where they can take their turn (not sleeping or downed)
---@return boolean
function PartyBattler:isActive()
    return not self.is_down and not self.sleeping
end

---@return boolean
function PartyBattler:isTargeted()
    return self.targeted
end

--- Gets the icon that should display in the Battler's head slot on their action box
---@return string texture
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

--- Toggles the visibility of the overlay sprite versus main sprite.
---@param overlay boolean?  Whether the overlay should be visible. If unset, will invert whatever the current visibility state is.
function PartyBattler:toggleOverlay(overlay)
    if overlay == nil then
        overlay = self.sprite.visible
    end
    self.overlay_sprite.visible = overlay
    self.sprite.visible = not overlay
end

--- Sets the Battler's sprite back to their default (`battle/idle`)
function PartyBattler:resetSprite()
    self:setAnimation("battle/idle")
end

--- Sets the battler's sprite for performing ACTs, including the additional flash effect
--- Acts as a shorthand of [`ActorSprite:setCustomSprite()`](lua://ActorSprite.setCustomSprite) and [`ActorSprite:play()`](lua://ActorSprite.play)
---@param sprite?   string
---@param ox?       number
---@param oy?       number
---@param speed?    number
---@param loop?     boolean
---@param after?    fun(ActorSprite)
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

--- Shorthand for [`ActorSprite:setSprite()`](lua://ActorSprite.setSprite) and [`Sprite:play()`](lua://Sprite.play)
---@param sprite?   string
---@param speed?    number
---@param loop?     boolean
---@param after?    fun(ActorSprite)
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
    
    if self.hurt_timer <= 15 then
        local hurt_index = math.min(self.hurt_timer / 2, 2)
        self.sprite.x = (-10 + (math.floor(hurt_index) * 5))
        self.hurt_timer = self.hurt_timer + DTMULT
    else
        self.sprite.x = 0
    end

    self.target_sprite.visible = false
    if self:isTargeted() then
        if (Game:getConfig("targetSystem")) and (Game.battle.state == "ENEMYDIALOGUE") then
            self.target_sprite.visible = true
        end
    elseif self.should_darken then
        if self.darken_timer < 15 then
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

    super.update(self)
end

function PartyBattler:draw()
    super.draw(self)
    if self.actor then
        self.actor:onBattleDraw(self)
    end
end

return PartyBattler
