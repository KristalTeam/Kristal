---@class Battler : Object
---@overload fun(...) : Battler
local Battler, super = Class(Object)

function Battler:init(x, y, width, height)
    super.init(self, x, y, width, height)

    self.layer = BATTLE_LAYERS["battlers"]

    self:setOrigin(0.5, 1)
    self:setScale(2)

    self.hit_count = 0

    self.highlight = self:addFX(ColorMaskFX())
    self.highlight.amount = 0
    self.flash_timer = 0

    self.last_highlighted = false

    self.sprite = nil
    self.overlay_sprite = nil

    self.dialogue_offset = {0, 0}

    -- Speech bubble style - defaults to "round" or "cyber", depending on chapter
    self.dialogue_bubble = nil

    self.alert_timer = 0
    self.alert_icon = nil
    self.alert_callback = nil
end

function Battler:setActor(actor, use_overlay)
    if type(actor) == "string" then
        self.actor = Registry.createActor(actor)
    else
        self.actor = actor
    end

    self.width = self.actor:getWidth()
    self.height = self.actor:getHeight()

    if self.sprite         then self:removeChild(self.sprite)         end
    if self.overlay_sprite then self:removeChild(self.overlay_sprite) end

    self.sprite = self.actor:createSprite()
    self:addChild(self.sprite)

    if use_overlay ~= false then
        self.overlay_sprite = self.actor:createSprite()
        self.overlay_sprite.visible = false
        self:addChild(self.overlay_sprite)
    end
end

function Battler:toggleOverlay(overlay)
    if overlay == nil then
        overlay = self.sprite.visible
    end
    if self.overlay_sprite then
        self.overlay_sprite.visible = overlay
        self.sprite.visible = not overlay
    end
end

function Battler:flash(sprite, offset_x, offset_y, layer)
    local sprite_to_use = sprite or self.sprite
    return sprite_to_use:flash(offset_x, offset_y, layer)
end

--- Creates an alert bubble (tiny !) above this battler.
---@param duration?     number  The number of frames to show the bubble for. (Defaults to `20`)
---@param options?      table   A table defining additional properties to control the bubble.
---|"play_sound"    # Whether the alert sound will be played. (Defaults to `true`)
---|"sprite"        # The sprite to use for the alert bubble. (Defaults to `"effects/alert"`)
---|"offset_x"      # The x-offset of the icon.
---|"offset_y"      # The y-offset of the icon.
---|"layer"         # The layer to put the icon on. (Defaults to `100`)
---|"callback"      # A callback that is run when the alert finishes.
---@return Sprite
function Battler:alert(duration, options)
    options = options or {}
    if options["play_sound"] == nil or options["play_sound"] then
        Assets.stopAndPlaySound("alert")
    end
    local sprite_to_use = options["sprite"] or "effects/alert"
    self.alert_timer = duration and duration*30 or 20
    if self.alert_icon then self.alert_icon:remove() end
    self.alert_icon = Sprite(sprite_to_use, (self.width/2)+(options["offset_x"] or 0), options["offset_y"] or 0)
    self.alert_icon:setOrigin(0.5, 1)
    self.alert_icon.layer = options["layer"] or 100
    self:addChild(self.alert_icon)
    self.alert_callback = options["callback"]
    return self.alert_icon
end

function Battler:sparkle(r, g, b)
    Game.battle.timer:every(1/30, function()
        for i = 1, 2 do
            local x = self.x + ((love.math.random() * self.width) - (self.width / 2)) * 2
            local y = self.y - (love.math.random() * self.height) * 2
            local sparkle = HealSparkle(x, y)
            if r and g and b then
                sparkle:setColor(r, g, b)
            end
            self.parent:addChild(sparkle)
        end
    end, 4)
end

function Battler:statusMessage(x, y, type, arg, color, kill)
    x, y = self:getRelativePos(x, y)

    local offset = 0
    if not kill then
        offset = (self.hit_count * 20)
    end

    local percent = DamageNumber(type, arg, x + 4, y + 20 - offset, color)
    if kill then
        percent.kill_others = true
    end
    self.parent:addChild(percent)

    if not kill then
        self.hit_count = self.hit_count + 1
    end

    return percent
end

function Battler:recruitMessage(x, y, type)
    x, y = self:getRelativePos(x, y)

    local recruit = RecruitMessage(type, x, y - 40)
    self.parent:addChild(recruit)

    return recruit
end

function Battler:spawnSpeechBubble(text, options)
    options = options or {}
    local bubble
    if not options["style"] and self.dialogue_bubble then
        options["style"] = self.dialogue_bubble
    end
    if not options["right"] then
        local x, y = self.sprite:getRelativePos(0, self.sprite.height/2, Game.battle)
        x, y = x + self.dialogue_offset[1], y + self.dialogue_offset[2]
        bubble = SpeechBubble(text, x, y, options, self)
    else
        local x, y = self.sprite:getRelativePos(self.sprite.width, self.sprite.height/2, Game.battle)
        x, y = x - self.dialogue_offset[1], y + self.dialogue_offset[2]
        bubble = SpeechBubble(text, x, y, options, self)
    end
    self.bubble = bubble
    self:onBubbleSpawn(bubble)
    bubble:setCallback(function()
        self:onBubbleRemove(bubble)
        bubble:remove()
        self.bubble = nil
    end)
    bubble:setLineCallback(function(index)
        Game.battle.textbox_timer = 3 * 30
    end)
    Game.battle:addChild(bubble)
    return bubble
end

function Battler:onBubbleSpawn(bubble) end
function Battler:onBubbleRemove(bubble) end

-- Shorthand for convenience
function Battler:setAnimation(animation, callback)
    return self.sprite:setAnimation(animation, callback)
end

function Battler:getActiveSprite()
    if not self.overlay_sprite then
        return self.sprite
    else
        return self.overlay_sprite.visible and self.overlay_sprite or self.sprite
    end
end

function Battler:setCustomSprite(sprite, ox, oy, speed, loop, after)
    self.sprite:setCustomSprite(sprite, ox, oy)
    if not self.sprite.directional and speed then
        self.sprite:play(speed, loop, after)
    end
end

function Battler:update()
    if Game.battle:isHighlighted(self) then
        self.highlight:setColor(1, 1, 1)
        self.flash_timer = self.flash_timer + DTMULT
        self.highlight.amount = -math.cos((self.flash_timer) / 5) * 0.4 + 0.6
        self.last_highlighted = true
    elseif self.last_highlighted then
        self.highlight.amount = 0
        self.flash_timer = 0
        self.last_highlighted = false
    end

    if self.alert_timer > 0 then
        self.alert_timer = Utils.approach(self.alert_timer, 0, DTMULT)
        if self.alert_timer == 0 then
            self.alert_icon:remove()
            self.alert_icon = nil
            if self.alert_callback then
                self.alert_callback()
                self.alert_callback = nil
            end
        end
    end

    super.update(self)
end

return Battler