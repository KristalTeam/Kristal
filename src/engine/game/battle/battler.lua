local Battler, super = Class(Object)

function Battler:init(x, y, width, height)
    super:init(self, x, y, width, height)

    self.layer = BATTLE_LAYERS["battlers"]

    self:setOrigin(0.5, 1)
    self:setScale(2)

    self.hit_count = 0

    self.highlight = self:addFX(ColorMaskFX())
    self.highlight.amount = 0

    self.last_highlighted = false
end

function Battler:flash(sprite)
    local sprite_to_use = sprite or self.sprite
    local offset = sprite_to_use:getOffset()
    local flash = FlashFade(sprite_to_use.texture, offset[1], offset[2])
    flash.layer = 100
    self:addChild(flash)
    return flash
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

function Battler:spawnSpeechBubble(text, right, style)
    local bubble
    if not style and self.dialogue_bubble then
        style = self.dialogue_bubble
    end
    if not right then
        local x, y = self.sprite:getRelativePos(0, self.sprite.height/2, Game.battle)
        if self.dialogue_offset then
            x, y = x + self.dialogue_offset[1], y + self.dialogue_offset[2]
        end
        bubble = SpeechBubble(text, x, y, self, false, style)
    else
        local x, y = self.sprite:getRelativePos(self.sprite.width, self.sprite.height/2, Game.battle)
        if self.dialogue_offset then
            x, y = x - self.dialogue_offset[1], y + self.dialogue_offset[2]
        end
        bubble = SpeechBubble(text, x, y, self, true, style)
    end
    self.bubble = bubble
    self:onBubbleSpawn(bubble)
    bubble:setCallback(function()
        self:onBubbleRemove(bubble)
        bubble:remove()
        self.bubble = nil
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
        self.highlight.amount = -math.cos((Kristal.getTime()*30) / 5) * 0.4 + 0.6
        self.last_highlighted = true
    elseif self.last_highlighted then
        self.highlight.amount = 0
        self.last_highlighted = false
    end

    super:update(self)
end

return Battler