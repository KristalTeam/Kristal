--- The base class for participants in battles. 
--- This class defines shared logic between types of `Battler`, but is not used on its own. \
--- See [`EnemyBattler`](lua://EnemyBattler.init) or [`PartyBattler`](lua://PartyBattler.init) depending on which you are working with, as well as this object.
---
---@class Battler : Object
---
---@field hit_count         number              The number of times the battler has been hit recently, used for the stacking effect of damage numbers.
---
---@field highlight         ColorMaskFX         An instance of a white ColorMaskFX, used for the white flash when the battler is selected in a menu.
---@field flash_timer       number              Internal timer variable for the battler's selected flash.
---
---@field last_highlighted  boolean             Internal variable used to determine whether the battler was highlighted last frame.
---
---@field sprite            ActorSprite?        The main sprite being used by this battler.
---@field overlay_sprite    ActorSprite?        An overlay sprite being used by this battler - special animations such as being hurt or downed take place on this sprite as to preserve the main sprite's animation cycle afterwards.
---
---@field dialogue_offset   [number, number]    The offset of the dialogue bubble from its default position.
---
---@field dialogue_bubble   string?             The bubble style used for the battler. Defaults to `"round"` or `"cyber"`, depending on chapter.
---
---@field alert_timer number                    Internal timer variable for the battler's overhead alert icon.
---@field alert_icon Sprite?                    Internal variable used to store the battler's overhead alert icon.
---@field alert_callback fun()?                 Internal variable used to store a callback for after an alert, if set.
---
---@overload fun(x?:number, y?:number, width?:number, height?:number) : Battler
local Battler, super = Class(Object)

---@param x?        number 
---@param y?        number
---@param width?    number
---@param height?   number
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

    self.dialogue_bubble = nil

    self.alert_timer = 0
    self.alert_icon = nil
    self.alert_callback = nil
end

--- Sets the actor used for this battler.
---@param actor         string|Actor    The id or instance of the `Actor` to set on this battler.
---@param use_overlay?  boolean         Whether to use the overlay sprite system (Defaults to `true`)
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

--- Toggles the visibility of the overlay sprite versus main sprite.
---@param overlay boolean?  Whether the overlay should be visible. If unset, will invert whatever the current visibility state is.
function Battler:toggleOverlay(overlay)
    if overlay == nil then
        overlay = self.sprite.visible
    end
    if self.overlay_sprite then
        self.overlay_sprite.visible = overlay
        self.sprite.visible = not overlay
    end
end

--- Makes the battler flash once.
---@param sprite    Sprite? An optional sprite to use for the flash instead of the battler's default sprite.
---@param offset_x? number
---@param offset_y? number
---@param layer?    number
---@return FlashFade
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

--- Creates sparkles around the battler (these appear by default when the battler receives healing)
---@param r? number
---@param g? number
---@param b? number
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

--- Creates a status text on the battler. \
--- Used for information such as damage numbers, being downed, or missing a hit
---@param x?        number  The x-coordinate the message should appear at, relative to the battler.
---@param y?        number  The y-coordinate the message should appear at, relative to the battler.
---@param type?     string  The type of message to display:
---|"mercy"     # Indicates that the message will be a mercy number
---|"damage"    # Indicates that the message will be a damage number
---|"msg"       # Indicates that the message will use a unique sprite, such as MISS or DOWN text
---@param arg?      any     An additional argument which depends on what `type` is set to:
---|"mercy"     # The amount of mercy added
---|"damage"    # The amount of damage dealt
---|"msg"       # The path to the sprite, relative to `ui/battle/message`, to use
---@param color?    table   The color used to draw the status message, defaulting to white
---@param kill?     boolean Whether this status should cause all other statuses to disappear.
---@return DamageNumber
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

--- *(Called internally)* Creates a RECRUIT message for when an enemy is spared and recruit progression advances
---@param x     number
---@param y     number
---@param type  string
---@return RecruitMessage
function Battler:recruitMessage(x, y, type)
    x, y = self:getRelativePos(x, y)

    local recruit = RecruitMessage(type, x, y - 40)
    self.parent:addChild(recruit)

    return recruit
end

--- Creates a speech bubble for this battler.
---@param text      string|string[]     The text to display in the speech bubble. Can be a table defining multiple lines.
---@param options?  table               A table defining additional properties to control the speech bubble:
---|"style"         # The dialogue bubble style to use (Defaults to [`Battler.dialogue_bubble`](lua://Battler.dialogue_bubble))
---|"right"         # Whether the dialogue bubble should appear to the right of the battler (Defaults to `false`)
---|"font"          # The font to use for the speech bubble
---|"actor"         # The actor to use for the speech bubble
---|"after"         # A callback that will be run after the dialogue is finished
---|"line_callback" # A callback that will be run after each line of dialogue is advanced
---@return SpeechBubble
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

--- *(Override)* Called whenever a speech bubble is created for this battler.
---@param bubble SpeechBubble
function Battler:onBubbleSpawn(bubble) end
--- *(Override)* Called whenever a speech bubble is removed for this battler.
---@param bubble SpeechBubble
function Battler:onBubbleRemove(bubble) end

--- Shorthand for [`ActorSprite:setAnimation()`](lua://ActorSprite.setAnimation)
---@param animation string|table
---@param callback? fun(ActorSprite)
function Battler:setAnimation(animation, callback)
    return self.sprite:setAnimation(animation, callback)
end

---Returns the active sprite, out of the battler's main and overlay sprite.
---@return ActorSprite?
function Battler:getActiveSprite()
    if not self.overlay_sprite then
        return self.sprite
    else
        return self.overlay_sprite.visible and self.overlay_sprite or self.sprite
    end
end

--- Shorthand for calling [`ActorSprite:setCustomSprite()`](lua://ActorSprite.setCustomSprite) and then [`ActorSprite:play()`](lua://ActorSprite.play)
---@param sprite?   string
---@param ox?       number
---@param oy?       number
---@param speed?    number
---@param loop?     boolean
---@param after?    fun(ActorSprite)
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